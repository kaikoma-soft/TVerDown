#!/usr/bin/ruby
# -*- coding: utf-8 -*-

#
#  
#
require 'fileutils'
require 'optparse'
require 'open-uri'
require 'find'
require 'ferrum.rb'


require_relative 'lib/Const.rb'
require_relative 'lib/Sqlite.rb'
require_relative 'lib/MyFerrum.rb'
require_relative 'lib/common.rb'
require_relative 'lib/Opt.rb'
require_relative 'lib/readConf.rb'
require_relative "lib/noko.rb"


class Main

  #
  #  実行
  #
  def run(  )

    mf = MyFerrum.new( $opt.hl )
    mn = Mynoko.new
    db = SqlDB.new

    dcount = 1
    
    #
    #  番組情報の取得
    #
    regex = nil
    if $opt.regex != nil
      regex = Regexp.new( $opt.regex )
    end

    ferrum = 0
    target2 = {}
    TARGET.each do |tmp|
      url, dir, opt  = tmp

      if opt != nil 
        if opt.start_with?(/d/i) == true    # Date
          opt = :date
        elsif opt.start_with?(/s/i) == true # Serial
          opt = :serial
        else
          log("Warn: TARGET の オプションが不正です。#{dir}(#{url}) #{opt}" )
        end
      end
      if target2[ url ] == nil
        target2[ url ] = Pdata.new( url, dir, opt )
      else
        log("Warn: TARGET の URL が重複しています。#{dir}(#{url})" )
      end
    end

    plist = []
    target2.each_pair do |k,v|
      v.url = File.join( TVERJP, v.url ) unless v.url =~ /~http/
      v.ignore = false
      v.progdl = false
      if regex != nil and !( regex =~ v.dir )
        v.ignore = true
      else
        if mf.get?( v.url ) == true
          v.progdl = true
          ferrum += 1
        end
      end
      v.cf = mf.cacheFname( v.url )
      v.dcount = 0
      plist << v
    end

    if ferrum > 0
      mf.setup()
      mf.get( TVERJP )
    end
    count = 1
    plist.each do |prog|
      if prog.progdl == true
        log("番組ページの取得 #{count}/#{ferrum} #{prog.dir}")
        cf = mf.get( prog.url )
        count += 1
        sleep( 10 )
      end
      list2 = []
      list = mn.getList( prog.cf, prog.dir, prog.url )
      list.each_pair do |url, title|
        list2 << PdataSub.new( url, title, false, -1 )
      end
      prog.list = list2
    end
    if ferrum > 0
      mf.fin()
    end

    
    #
    # 履歴の有無を調査してdownload するか判定
    #
    db.open( ) do |db2|
      plist.each do |p|
        p.list.each do |tmp|
          url2 = File.join( TVERJP, tmp.url )
          r = db2.select( url: url2 )
          if r.size == 0 
            tmp.downFlag = true
            p.dcount += 1
          else
            tmp.failcount = r.first[3]
            if tmp.failcount == EOD
              # NOP
            elsif tmp.failcount < FailCount
              tmp.downFlag = true
              p.dcount += 1
            else
              tmp.downFlag = true if $opt.force == true
              p.dcount += 1
            end
          end
        end
      end
    end

    #
    #  表示
    #
    dltcount = 0
    plist.each do |p|
      next if p.ignore == true
      log( "# " + p.dir ) if p.dcount > 0 or $opt.v == true
      p.list.each do |tmp|
        if tmp.failcount == EOD
          log( sprintf(" - %s %s", tmp.url, tmp.title ) ) if $opt.v == true
        elsif tmp.downFlag == true
          log( sprintf(" + %s %s", tmp.url, tmp.title ) )
          dltcount += 1
        elsif tmp.failcount >= FailCount
          log( sprintf(" E %s %s", tmp.url, tmp.title ) )
        end
      end
    end

    return if $opt.dry == true
    log("-" * 40 ) if dltcount > 0 
    
    #
    #  download の実行
    #
    catch(:exit_point) do
      plist.each do |p|
        p.list.each do |p2|
          if p2.downFlag == true
            url2 = File.join( TVERJP, p2.url )
            outDir = File.join( SpoolDir, p.dir ) 
            FileUtils.mkdir_p( outDir ) unless test( ?d, outDir )
            
            db.open() do |db2|
              if db2.exist?( url2 ) == false
                db2.insert( url2, p2.title, Time.now.to_i )
              end
            end
            log("Download 開始 #{dcount}/#{dltcount} #{p2.title}")
            st = Time.now
            if ytDlp( url2, outDir, p.opt ) ==  true
              lap = ( Time.now - st ).to_i
              log("Download 成功 #{lap} 秒")
              db.open() do |db2|
                db2.downEnd( url2 )
              end
              dcount += 1
              if dcount > $opt.n
                throw :exit_point
              end
            else
              log("Download 失敗")
              db.open() do |db2|
                db2.failInc( url2 )
              end
            end
            if $opt.done == false
              log("sleep #{IDLETIME}")
              sleep( IDLETIME )
            end
          end
        end
      end
    end
    
  end

  def initialize( )

    $opt = Opt.new

    #
    #  config,target の読み込み
    #
    readConf( $opt.config )
    raise "config not found" if Object.const_defined?(:BaseDir) != true
    raise "target not found" if Object.const_defined?(:TARGET) != true

    $opt.hl = HEADLESS if $opt.hl == nil
    
    [ BaseDir, CacheDir, DbDir ].each do |dir|
      FileUtils.mkdir_p( dir ) unless test( ?d, dir )
    end

                
    log("TVerDown start")
    expire()
    run()
    log("TVerDown end")
    
  end


  def ytDlp( url, outDir, opt = nil )

    return true if $opt.done == true
    tmpdir = Dir.mktmpdir( "TVer_" )
    st = Time.now
    db = SqlDB.new
    ret = false

    unless test( ?d, tmpdir )
      log( "Error: tmpdir not found" )
      return false
    end
    
    begin

      # DLファイル名の取得
      fname = nil
      cmd = %W( #{YTDLP_cmd} --print  %(title)s.%(ext)s )
      cmd += [  url ]
      IO.popen( cmd, "r") do |fp|
        fname = fp.gets
      end
      if fname == nil
        log("Error: DL ファイル名が取得出来ませんでした。#{url}")
        return false
      else
        fname.strip!
      end
      fname = makeFname( fname, outDir, opt )
      cmd = [ YTDLP_cmd ] + YTDLP_opt
      cmd += [ "-P", tmpdir, "-o", fname, url ]

      pid = spawn( *cmd ,[:out, :err] => [LogFn, "a"] )
      Process.waitpid( pid )
      
      Dir.open( tmpdir ).each do |file|
        if file =~ /\.mp4$/
          path = File.join( tmpdir, file )
          if File.size( path ) > 10 * 1024 * 1024
            FileUtils.mv( path, outDir )
            ret = true
          end
        end
      end
    ensure
      FileUtils.remove_entry_secure tmpdir
    end

    if ret == true and opt == :serial
      inc_serial( outDir )
    end
    
    return ret
  end

  #
  #   シリアル番号の取得
  #
  def get_serial( dir )
    ret = 1
    fn = File.join( dir, ".serial.txt")
    if test( ?f, fn )
      File.open( fn, "r") do |fp|
        num = fp.gets
        if num != nil
          ret = num.to_i
        end
      end
    end
    return ret
  end

  #
  #   シリアル番号の +1
  #
  def inc_serial( dir )

    n = get_serial( dir ) + 1
    fn = File.join( dir, ".serial.txt")
    File.open( fn, "w") do |fp|
      fp.puts( n.to_s )
    end
    return n
  end
  
  #
  #  ファイル名の文字列の加工
  #
  def makeFname( str, outDir, opt = nil )
    tmp = str.gsub(/\//,'／').dup
    tmp.strip!
    base = File.basename( tmp, ".*")
    ext = File.extname( tmp )

    if opt != nil 
      if opt == :date
        day = Time.now.strftime("%Y-%m-%d ")
        base = day + base
      elsif opt == :serial
        n = get_serial( outDir )
        base = sprintf("#%02d ", n ) + base
      end
    end
    
    base2 = truncate_utf8_by_bytes( base, MAX_FNLEN )
    ret = base2 + ext 
    return ret
  end

  def truncate_utf8_by_bytes(str, max_bytes)
    return str if str.bytesize <= max_bytes

    truncated_str = str.byteslice(0, max_bytes)
    while truncated_str.bytesize > 0 && !truncated_str.valid_encoding?
      truncated_str = truncated_str.byteslice(0, truncated_str.bytesize - 1)
    end
    truncated_str
  end


  
  #
  # 古い cacheファイルは削除
  #
  def expire()

    expTime = Time.now - Expire
    Find.find( CacheDir ) do |path|
      if test( ?f, path )
        if path =~ /\.html$/
          ctime = File.ctime( path )
          if ctime < expTime
            printf("del %s\n",path) if $opt.v == true
            File.unlink( path )       
          end
        end
      end
    end
  end
  
end


if $0 == __FILE__

  Main.new
  
end

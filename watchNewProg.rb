#!/usr/bin/ruby
# -*- coding: utf-8 -*-

#
#  ジャンルTop ページに追加/削除された、番組を検出する。
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
require_relative 'lib/readConf.rb'
require_relative "lib/noko.rb"


class Main

  def initialize( )

    $opt = Opt.new
    $opt.parser()

    #
    #  config の読み込み
    #
    readConf( $opt.config )

    def confChk( sym )
      if Object.const_defined?( sym ) != true
        printf( "Error: %s not found in config\n", sym.to_s )
        exit
      end
    end
    
    confChk( :CacheDir )
    confChk( :WNP_cateTop )

    if Object.const_defined?( :WNP_RSS_ON )
      confChk( :WNP_RSS_NUM )
      confChk( :WNP_RSS_FNAME )
      confChk( :WNP_RSS_LINK )
    else
      Object.const_set( :WNP_RSS_ON, false )
    end

    $opt.hl = HEADLESS if $opt.hl == nil
      
    log("#{$opt.pname} start") if $opt.v == true
    run()
    log("#{$opt.pname} end") if $opt.v == true
    
  end

  #
  #  実行
  #
  def run(  )

    
    @mf = MyFerrum.new( $opt.hl )
    @mn = Mynoko.new
    @db = SqlDB.new
    @progD = Struct.new( :url, :title, :ctime, :flag ) # 番組データ

    @db.open( ) do |db2|        # table の追加
      db2.chk_progTable()
    end

    @mf.setup()

    text = []
    WNP_cateTop.each_pair do |url, cateName|
      tmp = getSeries( url, cateName )
      text << "" if tmp.size > 0 and text.size > 0
      text += tmp
    end

    if text.size > 0
      @db.open( ) do |db2|
        sql = "insert into rssText ( text,ctime ) values (?,?)"
        db2.execute( sql, text.join("<br>\n"), Time.now.to_i )

        # expire
        sql = <<EOS
    delete FROM rssText WHERE id IN (
    SELECT id FROM rssText
    ORDER BY ctime DESC limit -1  OFFSET #{WNP_RSS_NUM} );
EOS
        db2.execute( sql )
      end
    end

    if WNP_RSS_ON == true
      makeRSS( WNP_RSS_FNAME )
    end

    if $opt.test == true
      @db.open( ) do |db2|
        10.times do |n|
          id = rand(500)
          sql = "delete from progList where id = ? "
          db2.execute( sql, id )
        end
      end
    end
  end


  #
  #  カテゴリのTopで、Series を抽出
  #
  def getSeries( urlC, cate )

    cf = @mf.cacheFname( urlC )
    if @mf.get?( urlC ) == true
      @mf.get( urlC )
    end
    printf("%s %s\n",urlC,cf) if $opt.v == true

    pdH = {}
    @db.open( ) do |db2|
      db2.selectPL( cate: cate ).each do |tmp|
        ( url, title, cate, ctime ) = tmp
        tmp2 = @progD.new( url, title, ctime, false )
        pdH[ url ] = tmp2       # URLの重複は後の方が有効
      end
    end

    pl2 = {}
    count = 0                   # <a> の数を数える
    File.open( cf, "r" ) do |fp|
      doc = Nokogiri.HTML( fp )
      doc.xpath("//a").each do |tmp|
        if tmp[:href] =~ /series/
          url  = tmp[:href]
          if tmp.at("img") != nil
            name = tmp.at("img")[:alt]
            if name != "バナー"
              pl2[ url ] = name
            end
          else
            pp tmp if $opt.d == true
          end
        end
        count += 1
      end
    end
    printf("count = %d\n", count) if $opt.v == true
    if count < 100
      printf("Error: a タグの数が不足 %s %d\n",urlC, count)
      return []
    end

    buf1 = []                   # 標準出力向け
    buf2 = []                   # RSS 向け
    @db.open( tran: true ) do |db2|
      now = Time.now.to_i

      # 追加の検出
      pl2.each_pair do |url,name|
        if pdH[ url ] == nil or pdH[ url ].title != name
          unless url =~ /^http/
            url2 = File.join( TVERJP, url )
          else
            url2 = url
          end
          buf1 << sprintf("add %-24s %s\n",url, name )
          buf2 << sprintf("add <a href=%s>%-24s</a> %s\n",url2,url, name )
          db2.insertPL( url, name, cate, now )
          pdH[ url ].flag = true if pdH[ url ] != nil
        else
          pdH[ url ].flag = true
        end
      end

      # 無くなったものを削除
      pdH.each_pair do |url, v|
        if v.flag == false
          unless url =~ /^http/
            url2 = File.join( TVERJP, url )
          else
            url2 = url
          end
          buf1 << sprintf("del %-24s %s",v.url, v.title )
          buf2 << sprintf("del <a href=%s>%-24s</a> %s\n",url2, v.url, v.title )
          db2.deletePL( v.url )
        end
      end
    end

    if buf1.size > 0
      tmp = sprintf("\n+++++  %s +++++\n",cate) 
      buf1.unshift( tmp )
      buf2.unshift( tmp )
      buf1.each do |tmp|
        puts( tmp )
      end

    end

    return buf2
  end

  #
  #  RSS の生成
  #
  require "rss"

  def makeRSS( output = nil )

    textA = nil
    @db.open( ) do |db2|
      sql = "select text,ctime from rssText order by ctime desc LIMIT "
      sql += WNP_RSS_NUM.to_s
      textA = db2.execute( sql )
    end
    return if textA == nil or textA.size == 0

    rss = RSS::Maker.make("2.0") do |maker|
      #xss = maker.xml_stylesheets.new_xml_stylesheet
      #xss.href = "http://example.com/index.xsl"
      #maker.channel.about = "http://example.com/index.rdf"
      
      maker.channel.title = "TVerDown watchNewProg"
      maker.channel.description = "TVer 番組変更検出"
      maker.channel.link = "WNP_RSS_LINK"
      maker.items.do_sort = true

      textA.each do |tmp|
        ( text, ctime ) = tmp
        maker.items.new_item do |item|
          date = Time.at( ctime ).strftime("%Y/%m/%d %H:%M" )
          item.title = "TVer 番組変更情報 " + date
          item.date = Time.at( ctime )
          item.summary = text
        end
      end

    end

    if output == nil
      puts rss
    else
      File.open( output, "w") do |fp|
        fp.puts rss
      end
    end
  end
end

class SqlDB

  #
  #  TABLE progList の追加
  #
  def add_table_progList( )
    sql = <<EOS
create table progList (
    id                  integer  primary key,
    url                 text,    -- URL
    title               text,    -- タイトル
    cate                text,    -- カテゴリ名
    ctime               integer  -- 作成日
);

create index pl1 on progList (title) ;
create index pl2 on progList (url) ;
create index pl3 on progList (ctime) ;
create index pl4 on progList (id) ;
create index pl5 on progList (cate) ;

create table rssText (
    id                  integer  primary key,
    text                text,    -- 内容
    ctime               integer  -- 作成日
);

create index rt1 on rssText (ctime) ;


EOS
    @db.execute_batch(sql)
  end
  
  #
  #  progList TABLE が有るか？ 無ければ作る。
  #
  def chk_progTable()
    sql = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='progList';"
    ret = @db.execute( sql )
    if ret[0][0] == 0 
      puts("add_table_progList")
      add_table_progList( )
    end
  end

  #
  #  select progList
  #
  def selectPL( cate: nil )
    sql = "select url,title,cate,ctime from progList "
    arg = []
    if cate != nil
      sql += " where cate = ? "
      arg << cate
    end
    sql += " order by id "

    tmp = @db.execute( sql, arg )
    return tmp
  end


  #
  #  追加 progList
  #
  def insertPL( url, title, cate, ctime )
    sql = "insert into progList ( url,title,cate,ctime ) values ( ?,?,?,? ) "
    @db.execute( sql, url, title, cate, ctime )
  end
  
  #
  #  削除 progList
  #
  def deletePL( url )
    sql = "delete from progList where url= ? "
    @db.execute( sql, url )
  end
  
  
end


#
#  オプション
#
class Opt
  attr_accessor :v, :d, :hl, :n, :cache, :config
  attr_accessor :rss, :test, :pname

  def initialize()
    @d     = false              # debug
    @hl    = nil                # headless 
    @cache = true               # キャッシュを使うか？
    @config = nil               # config ファイル
    @v     = false              # verbose
    @test   = false             # TEST mode
  end

  def parser()
    OptionParser.new do |opt|
      @pname = opt.program_name
      opt.version = ProgVer
      opt.on('-C dir', '--configDir dir') {|v| @config = v } 
      opt.on('-h', '--headless')          { @hl = true  } 
      opt.on('-H', '--no-headless')       { @hl = false } 
      opt.on('-N', '--no-cache')          { @cache = ! @cache } 
      opt.on('-d', '--debug' )            { @d = ! @d  } 
      opt.on('-v', '--verbose' )          { @v = ! @v } 
      opt.on('-T', '--test' )             { @test = ! @test }
      opt.on('--help' )                   { usage() } 
      opt.parse!(ARGV)
    end

  end

  def usage()
    puts <<EOS
使用法: #{@pname} [オプション]... 

 -C, --configDir=dir   config.rb,target.rb のあるDir を指定する。
 -H, --no-headless     chrome をヘッドレスで起動しない。
 -h, --headless        chrome をヘッドレスで起動する。
 -N, --no-cache        キャッシュを使用しない。
     --version         Version 表示
     --help            help メッセージ
EOS
    exit
  end

end



if $0 == __FILE__

  Main.new
  
end

#!/usr/bin/ruby

#
#  chrome系のbookmarkファイル から TVerの番組ページの URL を抽出して 
#  TVerDown の TARGET を標準出力に出力する。
#

require 'optparse'
require 'json'

require_relative 'lib/Const.rb'
require_relative 'lib/Opt.rb'
require_relative 'lib/readConf.rb'

class MakeTarget
  
  def hashDump( hash )
    retur nil if hash.class != Hash
    hash.each_pair do |k,v|
      next if k == "trash"      # ゴミ箱以下を無視する。
      if v.class == Hash
        hashDump( v )
      elsif v.class == Array
        arrayDump( v )
      else
        if k == "url" and v =~ /tver\.jp\/series/
          name = hash[ "name" ]
          name = name.sub(/\|\s+TVer$/,"").strip
          #printf("%s %s\n",v, name  )
          @list[ v ] = name
        end
      end
    end
  end

  def select( hash )
    if hash["url"] != nil
      if hash["url"] =~ /tver/
        printf("%s\n",hash["url"] )
      end
    end
  end

  def arrayDump( ary )
    ary.each do |tmp|
      if tmp.class == Hash
        hashDump( tmp )
      end
    end
  end

  def output()
    tver = Regexp.escape( TVERJP )
    str = <<EOS
#
#  Download 対象の番組ページの URL と 保存SubDir と オプション
#
EOS
    puts( str )
    puts("TARGET = [")
    @list.keys.sort.each do |key|
      tmp = key.sub(/#{tver}\//o,'')
      tmp = "\"" + tmp + "\""
      tmp2 = "\"" + @list[key].dup.gsub(/\//,'／') + "\""
      printf("  [ %-22s, %s, %s ],\n", tmp, tmp2, @optStr )
    end
    puts("]")
    str = <<EOS

#
#  -M オプションの対象外にするもの(書式は TARGET と同じ)
#
DELLIST = [
]
EOS
    puts( str )
  end

  def output_diff()             # 差分を出力

    urls = {}
    if Object.const_defined?(:TARGET) == true # 対象リスト
      TARGET.each do |tmp|
        urls[ tmp[0] ] = true
      end
    end
    
    delList = {}
    if Object.const_defined?(:DELLIST) == true # 対象外リスト
      DELLIST.each do |tmp|
        delList[ tmp[0] ] = true
      end
    end
    
    tver = Regexp.escape( TVERJP )
    @list.keys.sort.each do |key|
      tmp = key.sub(/#{tver}\//o,'')
      next if delList[ tmp ] == true
      if urls[ tmp ] == nil
        tmp = "\"" + tmp + "\""
        tmp2 = "\"" + @list[key].dup.gsub(/\//,'／') + "\""
        printf("  [ %-22s, %s, %s ],\n", tmp, tmp2, @optStr )
      end
    end

  end
  
  def initialize( )

    @list = {}
    @merge = false
    @config = nil               # config ファイル
    @optStr = '"' + OptStr + '"'
    @json = nil

    OptionParser.new do |opt|
      @pname = opt.program_name
      opt.version = ProgVer
      opt.on('--json json','-J json')     {|v| @json = v } 
      opt.on('--merge','-M')              { @merge = ! @merge } 
      opt.on('--configDir dir','-C dir' ) {|v| @config = v } 
      opt.on('--opt type','-O type' )     {|v| @optStr = '"' + v + '"'} 
      opt.on('--help' )                   { usage() } 
      opt.parse!(ARGV)
    end

    readConf( @config )
    
    if  @merge == true
      raise "target not found" if Object.const_defined?(:TARGET) != true
    end

    if @json == nil 
      if Object.const_defined?(:MT_JSON) == true
        @json = MT_JSON
      else
        @json = File.join( HOME, ".config/google-chrome/Default/Bookmarks" )
      end
    end
      
    if test( ?f, @json )
      File.open(@json) do |file|
        hash = JSON.load(file)

        root = hash["roots"]
        if root.class == Hash
          hashDump( root )
        elsif root.class == Array
          arrayDump( root )
        end
      end
      if @merge == false
        output()
      else
        output_diff()
      end
        
    else
      puts("Error: json file not found (#{@json})")
    end

  end

  def usage()
    puts <<EOS
使用法: #{@pname} [オプション]... 

 -J, --json=file       読み込む json ファイルを指定する。指定しない場合は、
                       #{@json}
 -M, --merge           target.rb の内容と比較して、追加分だけを出力する。
 -C, --configDir=dir   target.rb のあるDir を指定する。(-M 指定時のみ有効)
 -O, --opt=type        オプションの文字列(nil,Date,Serial) を指定。デフォルトは Date 
     --help            help メッセージ

EOS
    exit
  end
  

end

MakeTarget.new

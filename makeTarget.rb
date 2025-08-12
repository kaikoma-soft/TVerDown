#!/usr/bin/ruby

#
#  chrome系のbookmarkファイル から TVerの番組ページの URL を抽出して 
#  TVerDown の TARGET を標準出力に出力する。
#

require 'optparse'
require 'json'

require_relative 'lib/Const.rb'

class MakeTarget
  
  def hashDump( hash )
    retur nil if hash.class != Hash
    hash.each_pair do |k,v|
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
    puts("TARGET = [")
    @list.keys.sort.each do |key|
      tmp = key.sub(/#{tver}\//o,'')
      tmp = "\"" + tmp + "\""
      tmp2 = "\"" + @list[key].dup.gsub(/\//,'／') + "\""
      printf("    [ %-22s, %s, nil ],\n", tmp, tmp2 )
    end
    puts("]")
  end
  
  def initialize( )

    @list = {}
    @json = File.join( ENV["HOME"], ".config/google-chrome/Default/Bookmarks" )
    #@json = File.join( ENV["HOME"], ".config/vivaldi/Default/Bookmarks" )

    OptionParser.new do |opt|
      @pname = opt.program_name
      opt.version = ProgVer
      opt.on('--json json','-J json') {|v| @json = v } 
      opt.on('--help' )                   { usage() } 
      opt.parse!(ARGV)
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
      output()    
    else
      puts("Error: json file not found (#{@json})")
    end

  end

  def usage()
    puts <<EOS
使用法: #{@pname} [オプション]... 

 -j, --json=file   読み込む json ファイルを指定する。指定しない場合は、
                   #{@json}
     --help        help メッセージ

EOS
    exit
  end
  

end

MakeTarget.new

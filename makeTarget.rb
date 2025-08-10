#!/usr/bin/ruby

#
#  chrome系のbookmarkファイル から TVerの番組ページの URL を抽出して 
#  TVerDown の TARGET を標準出力に出力する。
#

require 'json'

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
    puts("TARGET = {")
    @list.keys.sort.each do |key|
      tmp = "\"" + key + "\""
      tmp2 = @list[key].dup.gsub(/\//,'／')
      printf("    %-36s => \"%s\",\n", tmp, tmp2 )
    end
    puts("}")
  end
  
  def initialize( )

    @list = {}
    json = File.join( ENV["HOME"], ".config/google-chrome/Default/Bookmarks" )
    json = File.join( ENV["HOME"], ".config/vivaldi/Default/Bookmarks" )

    File.open(json) do |file|
      hash = JSON.load(file)

      root = hash["roots"]
      if root.class == Hash
        hashDump( root )
      elsif root.class == Array
        arrayDump( root )
      end
    end

    output()    
  end

end

MakeTarget.new

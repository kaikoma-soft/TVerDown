#!/usr/bin/ruby
# -*- coding: utf-8 -*-

#
#  
#


class Mynoko

  def initialize( )

  end

  def getList( cf, name, url )
    ret = {}
    if test( ?f, cf )
      # class 名の抽出
      classN = {}
      File.open( cf, "r" ) do |fp|
        doc = Nokogiri.HTML( fp )
        doc.xpath("//a").each do |tmp|
          if tmp[:href] =~ /episode/
            if tmp[:class] =~ /episode/
              classN[ tmp[:class] ] = true
            end
          end
        end
        doc.xpath("//pre[contains(@class,'ErrorModal_message__')]").each do |tmp|
          puts "Error: #{name} #{url} #{tmp.text}"
          return ret
        end
      end
      if classN.size == 0
        puts "Warrnig: Mynoko::getList() class名 が取得出来ません。#{name} #{cf}"
        return ret
      end

      classN.keys.each do |classN2|
        xpath = "//a[@class='#{classN2}']"
        File.open( cf, "r" ) do |fp|
          doc = Nokogiri.HTML( fp )
          doc.xpath(xpath).each do |tmp|
            if tmp[:href] =~ /episodes/
              ret[ tmp[:href] ] = tmp.at("img")[:alt]
            end
          end
        end
      end
    end
    return ret
  end
end


if $0 == __FILE__

  mn = Mynoko.new

  Dir.open( CacheDir ).each do |f|
    next if f == "." or f == ".."
    pp cf = File.join( CacheDir, f)
    pp mn.getList( cf )
  end

end

#!/usr/bin/ruby
# -*- coding: utf-8 -*-

#
#  
#
require 'nokogiri'


class Mynoko

  def initialize( )

  end

  def getList( cf, name, url )
    ret = {}
    if test( ?f, cf )

      File.open( cf, "r" ) do |fp|
        doc = Nokogiri.HTML( fp )

        doc.xpath("//pre[contains(@class,'ErrorModal_message__')]").each do |tmp|
          puts "Error: #{name} #{url} #{tmp.text}"
          return ret
        end
        
        doc.css('[class*="SeasonEpisodeList_episodes__"]').each do |tmp|
          tmp.xpath(".//a").each do |tmp2|
            if tmp2[:href] =~ /episode/
              tmp2.xpath(".//img").each do |tmp3|
                ret[ tmp2[:href] ] = tmp3[:alt]
              end
            end
          end
        end
      end

      if ret.size == 0
        File.open( cf, "r" ) do |fp|
          fp.each_line do |str|
            if str =~ /配信中のエピソードがありません/
              puts "Warrnig: 配信中のエピソードがありません #{url}"
              return ret
            end
          end
        end
        puts "Warrnig: Mynoko::getList() エピソードが見つかりません。#{name} #{cf}"
        return ret
      end
    end
    # pp ret
    return ret
  end
end


if $0 == __FILE__

  mn = Mynoko.new
  CacheDir = File.join( ENV["HOME"], "data/TVerDown/Cache" )
  
  Dir.open( CacheDir ).each do |f|
    next if f == "." or f == ".."
    pp cf = File.join( CacheDir, f)
    pp mn.getList( cf, "", "" )
  end

end

#!/usr/bin/ruby

#
#  config, target の読み込み
#
def readConf( opt = nil )

  files = %W( config.rb target.rb )
  dirs = [ ]
  dirs << opt if opt != nil
  dirs << ENV["TVERDOWN_CONF_DIR"] if ENV["TVERDOWN_CONF_DIR"] != nil
  dirs << File.join( ENV["HOME"], ".config/TVerDown" )

  files.each do |file|
    dirs.each do |dir|
      cfg = File.join( dir, file )
      cfg2 = File.expand_path( cfg )
      if test( ?f, cfg2 )
        require cfg2
        log( "readConf #{cfg2}" ) if $opt != nil and $opt.v == true
        break
      end
    end
  end
end

if $0 == __FILE__

  pp $0
  pp File.expand_path( $0 )
  pp File.join( File.dirname( $0 ), "lib" )
  
end

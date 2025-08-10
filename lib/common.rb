

def log( str )

  now = Time.now
  str = str.class == Array ? str.join("\n          ") : str
  txt = sprintf("%s: %s\n",now.strftime("%H:%M:%S"),str)

  begin 
    File.open( LogFn, "a" ) do |fp|
      fp.puts( txt )
    end
  rescue => e
    p $!
    puts e.backtrace.first + ": #{e.message} (#{e.class})"
    e.backtrace[1..-1].each { |m| puts "\tfrom #{m}" }
  end

  puts( txt )
  STDOUT.flush()

end

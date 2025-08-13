

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


#
#  ファイル名の書き換え
#
def renameRule( str )
  if Object.const_defined?(:RENAME_RULE) == true
    if RENAME_RULE.class == Hash
      RENAME_RULE.each_pair do |k,v|
        str.gsub!(/#{k}/,v )
      end
    end
  end
  return str
end

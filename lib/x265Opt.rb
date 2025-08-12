
#
#  オプション
#
class Opt
  attr_accessor :width, :v, :config, :maxproc, :force

  def initialize()
    @config  = nil              # config dir
    @maxproc = 999              # 最大変換数
    @force   = false            # lock を無視

    OptionParser.new do |opt|
      @pname = opt.program_name
      opt.version = ProgVer
      opt.on('-C dir','--config dir') {|v| @config = v } 
      opt.on('-M n', '--maxproc n')   {|v| @maxproc = v.to_i } 
      opt.on('-F',   '--force', )     { @force = ! @force } 
      opt.on('--help' )               { usage() } 
      opt.parse!(ARGV)
    end

  end

  def usage()
    puts <<EOS
使用法: #{@pname} [オプション]... 

 -C, --configDir=dir   config.rb,target.rb のあるDir を指定する。
 -M, --maxproc=n       変換数の制限
 -F, --force           ロックを無視して実行する。
     --help            help メッセージ

EOS
    exit
  end
  
end

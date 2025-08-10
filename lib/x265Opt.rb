
#
#  オプション
#
class Opt
  attr_accessor :width, :v, :config, :maxproc, :force

  def initialize()
    @v     = false              # 冗長な
    @config  = nil              # config dir
    @maxproc = 999              # 最大変換数
    @force   = false            # lock を無視

    OptionParser.new do |opt|
      opt.on('-V',   '--verbose')   {|v| @v = ! @v } 
      opt.on('-C dir','--config dir') {|v| @config = v } 
      opt.on('-M n', '--maxproc n') {|v| @maxproc = v.to_i } 
      opt.on('-M n', '--maxproc n') {|v| @maxproc = v.to_i } 
      opt.on('-F',   '--force', )   { @force = ! @force } 
      opt.parse!(ARGV)
    end

  end
end

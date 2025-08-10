
#
#  オプション
#
class Opt
  attr_accessor :v, :d, :hl, :n, :dry, :cache, :done, :config, :regex
  attr_accessor :force

  def initialize()
    @v     = false              # 冗長なメッセージ
    @d     = false              # debug
    @hl    = true               # headless
    @n     = 99                 # download 制限数
    @dry   = false              # dry run
    @cache = true               # キャッシュを使うか？
    @done  = false              # done mode = 既読にする。
    @config = nil               # config ファイル
    @regex  = nil               # 対象を絞る正規表現
    @force  = false             # エラーカウントを無視してdownload

    OptionParser.new do |opt|
      opt.on('--configDir dir','-C dir') {|v| @config = v } 
      opt.on('--done')                   { @done = ! @done } 
      opt.on('--dryrun',   '-D')         { @dry = ! @dry } 
      opt.on('--force',    '-F')         { @force = ! @force } 
      opt.on('--headless', '-H')         { @hl = ! @hl  } 
      opt.on('--no-cache', '-N')         { @cache = ! @cache } 
      opt.on('--regex str','-R str')     {|v| @regex = v } 
      opt.on('--verbose',  '-v')         { @v = ! @v } 
      opt.on('--version',  '-V')         { showVersion() } 
      opt.on('-d')                       { @d = ! @d  } 
      opt.on('-n n')                     {|v| @n = v.to_i } 
      opt.parse!(ARGV)
    end

  end

  def showVersion()
    printf("%s %s\n",File.basename( $0 ), ProgVer )
    exit
  end
end



#
#  オプション
#
class Opt
  attr_accessor :v, :d, :hl, :n, :dry, :cache, :done, :config, :regex
  attr_accessor :force

  def initialize()
    @v     = false              # 冗長なメッセージ
    @d     = false              # debug
    @hl    = nil                # headless 
    @n     = 99                 # download 制限数
    @dry   = false              # dry run
    @cache = true               # キャッシュを使うか？
    @done  = false              # done mode = 既読にする。
    @config = nil               # config ファイル
    @regex  = nil               # 対象を絞る正規表現
    @force  = false             # エラーカウントを無視してdownload

    OptionParser.new do |opt|
      @pname = opt.program_name
      opt.version = ProgVer
      opt.on('-C dir', '--configDir dir') {|v| @config = v } 
      opt.on('--done')                    { @done = ! @done } 
      opt.on('-D', '--dryrun'  )          { @dry = ! @dry } 
      opt.on('-F', '--force')             { @force = ! @force } 
      opt.on('-h', '--headless')          { @hl = true  } 
      opt.on('-N', '--no-cache')          { @cache = ! @cache } 
      opt.on('-H', '--no-headless')       { @hl = false } 
      opt.on('-R str', '--regex str')     {|v| @regex = v } 
      opt.on('-v', '--verbose' )          { @v = ! @v } 
      opt.on('-d', '--debug' )            { @d = ! @d  } 
      opt.on('-n n', '--maxnum n')        {|v| @n = v.to_i } 
      opt.on('--help' )                   { usage() } 
      opt.parse!(ARGV)
    end

  end

  def usage()
    puts <<EOS
使用法: #{@pname} [オプション]... 

 -C, --configDir=dir   config.rb,target.rb のあるDir を指定する。
     --done            download せずに、download終了とする。
 -D, --dryrun          download せずに、状況表示のみで終了する。
 -F, --force           累積エラーでも無視して download する。
 -H, --no-headless     chrome をヘッドレスで起動しない
 -N, --no-cache        キャッシュを使用しない
 -R, --regex=str       正規表現で、download対象を絞る
 -v, --verbose         冗長表示
     --version         Version 表示
 -d, --debug           デバッグ モード
 -h, --headless        chrome をヘッドレスで起動する
     --help            help メッセージ
 -n, --maxnum=n        download 個数制限

EOS
    exit
  end

end


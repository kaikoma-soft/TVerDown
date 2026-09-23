# coding: utf-8

require 'slim'

require_relative 'watchNewProg2.rb'

Local_jquery    = false    # jquery等をローカルに用意した場合に true

#
#  オプション
#
class Opt
  attr_accessor :v, :d, :config
  attr_accessor :rss, :test, :pname, :kill

  def initialize()
    @d     = false              # debug
    @config = nil               # config ファイル
    @v     = false              # verbose
    @kill  = false
  end

  def parser()
    OptionParser.new do |opt|
      @pname = opt.program_name
      opt.version = ProgVer
      opt.on('-C dir', '--configDir dir') {|v| @config = v } 
      opt.on('--kill' )                   { @kill = true } 
      opt.on('--help' )                   { usage() } 
      opt.parse!(ARGV)
    end

  end

  def usage()
    puts <<EOS
使用法: #{@pname} [オプション]... 

 -C, --configDir=dir   config.rb のあるDir を指定する。
     --version         Version 表示
     --kill            既に起動しているものを停止する。
     --help            help メッセージ
EOS
    exit
  end
end

$opt = Opt.new
$opt.parser()

#
#  config の読み込み
#
readConf( $opt.config )

#
#  PID の保存、プログラム終了
#
def httpdKill( fname, signal = :HUP )
  if test( ?f, fname )
    File.open( fname,"r" ) do |fp|
      pid = fp.gets().to_i
      if pid > 0
        begin
          Process.kill( signal, pid )
        rescue Errno::ESRCH
        end
      end
    end
  end
end
if $opt.kill == true
  httpdKill( PidFile, :HUP )
  exit
else
  File.open( PidFile, "w") do |fp|
    fp.puts( Process.pid  )
  end
end



#
#  sinatra 
#
require 'sinatra'

enable :sessions
enable :reloader
#set :server, "webrick"
set :server, "puma"
set :slim, pretty: true
set :sass, content_type: 'text/css', charset: 'utf-8'
set :port, HttpPort
set :bind, '0.0.0.0'
set :public_folder, File.dirname(__FILE__) + '/views'
set :session_secret, ENV['SESSION_SECRET'] || '8e9a835682b93ce7eb6de04cffd1d2b767ac3cc018f4df7d1c79896528c0a3c265facf3bd78669ed6a41d2390f96ac744bb5c6abcecfc0ad4158f60ed8dd15ab'

before do
  if session[:disp] == nil
    #pp "@session_disp = 1"
    @session_disp = 1
    session[:disp] = 1          # 無視以外
  end
  @viewDir = File.dirname(__FILE__) + '/views'
end

get '/' do
  @title = "TVerDown"
  @cateS = session[:cate]
  slim :top
end

post '/dispSel' do                   # 表示条件の変更
  disp = params.keys.first.to_i
  if disp > 0
    session[:disp] = disp
    @session_disp = disp
  end
  slim :top
end


get '/stop' do
  Thread.new do
    sleep(1)
    Process.kill( :SIGUSR2, $$ )
  end
  redirect '/'
end

post '/cb' do                   # checkbox
  id  = params[:id].to_i
  flag = params[:flag]
  db = SqlDB.new
  db.open( ) do |db2|
    db2.setFlag( id, flag )
  end
  
end

post '/sel' do                   # select
  id  = params[:id].to_i
  val = params[:val].to_i
  db = SqlDB.new
  db.open( ) do |db2|
    db2.setFOpt( id, val )
  end
end

get '/editD/*' do  |id|                # title, URL 編集 ダイアログ
  @id = id
  db = SqlDB.new
  db.open( ) do |db2|
    @data = db2.selectPL( id: @id ).first
  end
  slim :editD, layout: false
end

post '/editM' do                # title, URL 修正登録
  title = params[:title]
  url = params[:url]
  id = params[:id]
  statRadio = params[:statRadio].to_i
  optRadio  = params[:optRadio].to_i
  db = SqlDB.new
  db.open( tran: true ) do |db2|
    db2.updatePL( id, url, title )
    db2.setFOpt( id, optRadio )
    db2.setFlag( id, statRadio )
  end
  redirect '/'
end

post '/del' do                # 削除
  id = params[:id].to_i
  db = SqlDB.new
  db.open( ) do |db2|
    @data = db2.deletePL( id: id )
  end
end


post '/cate' do                   # 表示カテゴリの変更の記録
  cate = params.keys.first
  session[:cate] = cate
end


after do
  cache_control :no_cache
end



#
#  radioボタンのchecked を返す
#
def statRadioChk?( n )
  if @statRadioChk == nil
    @statRadioChk = Array.new( 4, false ) 
    cht = true
    case @data.flag
    when 0 then @statRadioChk[0] = cht        # 未
    when 1 then @statRadioChk[1] = cht        # Down
    when 2 then @statRadioChk[2] = cht        # 完了
    when 3 then @statRadioChk[3] = cht        # 無視
    end
  end
  return @statRadioChk[n]
end

def optRadioChk?( n )
  ##pp "object_id = #{object_id}"
  if @optRadioChk == nil
    @optRadioChk = Array.new( 3, false )
    case @data.fnameopt
    when 0 then @optRadioChk[0] = true # 未
    when 1 then @optRadioChk[1] = true # 日付
    when 2 then @optRadioChk[2] = true # シリアル番号
    end
  end
  return @optRadioChk[n]
end

def include( fn )
  r = ""
  fn = File.join(  @viewDir, fn )
  if test(?f, fn )
    File.open( fn, "r") do |fp|
      r = fp.read()
    end
  else
    puts("file not found #{fn}")
  end
  r
end

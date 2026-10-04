#
#  TVerDown config
#

#
#  Dir 設定
#
HOME     = ENV["HOME"]
BaseDir  = File.join( HOME,"/TVerDown" )
DbDir    = File.join( BaseDir,"/db" )
CacheDir = File.join( BaseDir,"/Cache" )
SpoolDir = File.join( BaseDir,"/spool" )
PidFile  = File.join( BaseDir,"/httpd.pid" )

#
#  download 履歴のDB
#
DbFname = File.join( DbDir, "db.sqlite" )

#
# yt-dlp コマンド
#
YTDLP_cmd = File.join( BaseDir,"com/yt-dlp" )
YTDLP_opt = %W( -r 1M --progress --color no_color )
MAX_FNLEN = 220                 # ファイル名の最大長
MIN_FSIZE = ( 5 * 1024 * 1024 ) # download 成功/失敗の閾値(byte)

#
#  ブラウザを headless で起動するかの初期値 true/false (true=する)
#
HEADLESS = false

#
#  Log ファイル
#
LogFn   = File.join( "/tmp", "TVerDown.log" )

#
#   Ver 2.0.0 以降
#
ProgExpire = 35                  # 古い番組データを保持する日数(day)
LogExpire  = 365                 # 古いdownload記録を保持する日数(day)
FnOpt    = 1                    # ファイル名に付加するオプションの初期値
                                # 0=なし、1=日付、2=シリアル番号
NewMark  = 3                    # new印を付ける日数
HttpPort = 42101                # http のポート番号


#
#  for watchNewProg2.rb
#
WNP_cateTop = {
  "https://tver.jp/categories/drama"   => "ドラマ",
  "https://tver.jp/categories/variety" => "バラエティ",
  "https://tver.jp/categories/anime"   => "アニメ",
  "https://tver.jp/categories/news"    => "ニュース",
  "https://tver.jp/categories/sports"  => "スポーツ",
}
WNP_RSS_ON = false              # RSS を生成するか ( true = する )
WNP_RSS_NUM = 10                # RSS に残す過去分
rssFname = "TVer_watchNewProg.rss"
WNP_RSS_FNAME = File.join( HOME, "public_html/#{rssFname}" ) # RSS の出力ファイル名
WNP_RSS_LINK = "http://localhost/~#{ENV["USER"]}/#{rssFname}" # RSS link addr



#
#  for x256 conv
#
ConvInDir  = SpoolDir
ConvOutDir = File.join( BaseDir, "x265" )
ConvLockfn = "/tmp/TVer-conv.lock"
ConvCmd    = "ffmpeg_1280.sh"
ConvSufFix = "-TVer"
X264expire = 14                 # 変換済みの mp4ファイルの保存期間(日)

  

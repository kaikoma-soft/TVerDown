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

#
#  download 履歴のDB
#
DbFname = File.join( DbDir, "db.sqlite" )

#
# yt-dlp コマンド
#
YTDLP_cmd = File.join( BaseDir,"com/yt-dlp" )
YTDLP_opt = %W( -r 1M --progress --color no_color )

#
#  ブラウザを headless で起動するかの初期値 true/false (true=する)
#
HEADLESS = false

#
#  Log ファイル
#
LogFn   = File.join( "/tmp", "TVerDown.log" )


#
#  for makeTarget.rb
#
MT_JSON = File.join( HOME, ".config/google-chrome/Default/Bookmarks" )
#MT_JSON = File.join( HOME, ".config/vivaldi/Default/Bookmarks" )

#
#  for x256 conv
#
ConvInDir  = SpoolDir
ConvOutDir = File.join( BaseDir, "x265" )
ConvLockfn = "/tmp/TVer-conv.lock"
ConvCmd    = "ffmpeg_1280.sh"
ConvSufFix = "-TVer"
X264expire = 14                 # 変換済みの mp4ファイルの保存期間(日)

  
#
#  for watchNewProg.rb
#
WNP_cateTop = {
  "https://tver.jp/categories/drama"   => "ドラマ",
  "https://tver.jp/categories/variety" => "バラエティ",
  "https://tver.jp/categories/anime"   => "アニメ",
  "https://tver.jp/categories/news"    => "ニュース",
  "https://tver.jp/categories/sports"  => "スポーツ",
}
#WNP_RSS_ON = true               # RSS を生成するか ( true = する )
WNP_RSS_NUM = 10                # RSS に残す過去分
WNP_RSS_FNAME = File.join( HOME, "public_html/TVer_watchNewProg.rss" ) # RSS の出力ファイル名
rssFname = "TVer_watchNewProg.rss"
WNP_RSS_FNAME = File.join( HOME, "public_html/#{rssFname}" ) # RSS の出力ファイル名
WNP_RSS_LINK = "http://localhost/~#{ENV["USER"]}/#{rssFname}" # RSS link addr


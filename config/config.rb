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
#  for x256 conv
#
ConvInDir  = SpoolDir
ConvOutDir = File.join( BaseDir, "x265" )
ConvLockfn = "/tmp/TVer-conv.lock"
ConvCmd    = "ffmpeg_1280.sh"
ConvSufFix = "-TVer"
X264expire = 14                 # 変換済みの mp4ファイルの保存期間(日)

  

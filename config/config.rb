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
YTDLP_cmd = File.join( BaseDir,"prog/yt-dlp" )
YTDLP_opt = %W( -r 1M --progress --color no_color )


#
#  for x256 conv
#
ConvInDir  = SpoolDir
ConvOutDir = File.join( BaseDir, "x265" )
ConvLockfn = "/tmp/TVer-conv.lock"
ConvCmd    = "ffmpeg_1280.sh"
ConvSufFix = "-TVer"

  

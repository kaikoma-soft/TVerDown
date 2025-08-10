

#
#  定数
#
Expire  = 3600 * 12             # cache の有効期間
TVERJP  = "https://tver.jp"
FailCount = 3                   # download 失敗の制限値
EOD       = 9999                # End of Download
IDLETIME  = 30                  # アイドルタイム
MAX_FNLEN = 230                 # ファイル名の最大長

ProgVer  = "Ver 0.0.0"


#
#  Log ファイル
#
LogFn   = File.join( "/tmp", "TVerDown.log" )

#
#  構造体定義
#
Pdata    = Struct.new( :url,    # 番組ページURL
                       :dir,    # 保存Dir名
                       :cf,     # キャッシュファイル名
                       :list,   # 個別番組への配列 -> PdataSub
                       :dcount, # download 数
                       :ignore, # 無視するか
                       :progdl  # 番組ページを DL するか
                     ) 
PdataSub = Struct.new( :url, :title, :downFlag, :failcount ) # 番組個別

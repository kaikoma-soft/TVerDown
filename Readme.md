

## 開発の背景と目的

本プログラムは、TVer の目的番組をバッチ的にダウンロードするための補助プログラムです。

Ver2 では、Download 対象をブラウザから選択できるように
GUIインターフェースを追加し、それに合わせて機能追加を行った。

## 動作概要

* 定期的に TVer の番組表から番組名を抽出し、DBに登録するプログラム
  ( watchNewProg2.rb ) を実行する。
* webサーバープログラム( httpd.rb )を立ち上げる。
* webブラウザでアクセスし、download したいもののステータスを変更する。
* downloadプログラム( TVerDown2.rb )を実行すると、
  * chromium で目的の番組ページを取得する。
  * ページ中から動画の URL を抽出
  * URL が既に download済みか、DB から検索
  * 検索して未了ならば、download 開始
  * download が正常終了ならば DB に完了登録


## 動作環境
* Ubuntu 24.04 LTS (多分Unix系ならなんでも)
* ruby  3.2 以上
* sqlite3
* ruby-nokogiri
* chromium
* ferrum
* python 3
* yt-dlp
* ffmpeg


## インストール

1. 想定のディレクトリ構成

   |   dir                   | 説明                           |
   |-------------------------|--------------------------------|
   |  $HOME/TVerDown/com     | プログラム インストール Dir    |
   |  $HOME/TVerDown/db      | database 保存Dir               |
   |  $HOME/TVerDown/Cache   | 番組ページのキャッシュ保存 Dir |
   |  $HOME/TVerDown/spool   | 動画保存 Dir                   |

1. 必要なツールをパッケージからインストールする。(ubuntu の場合)

   ```
   $ sudo apt install -y ruby ruby-dev ruby-sqlite3 ruby-nokogiri chromium-browser sqlite3 wget python3 git make gcc ffmpeg puma
   $ sudo gem install ferrum
   ```
1. TVerDown 本体のインストール

   ```
   $ mkdir -p $HOME/TVerDown/com
   $ mkdir -p $HOME/TVerDown/db
   $ mkdir -p $HOME/TVerDown/Cache
   $ mkdir -p $HOME/TVerDown/spool
   $ cd $HOME/TVerDown/com
   $ git clone --depth 1 https://github.com/kaikoma-soft/TVerDown.git .
   ```
1. yt-dlp のインストール

   yt-dlp は頻繁にアップデートされるのでパッケージではなく、
   配布元から直接インストールする。
   ```
   $ cd $HOME/TVerDown/com
   $ wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
   $ chmod +x yt-dlp
   ```

1. config.rb のコピー

   $HOME/TVerDown/com/config の下に設定ファイルの雛形が有るので、
   $HOME/.config/TVerDown にコピーし、自分の環境に合わせて適宜変更する。

   ```
   $ mkdir -p $HOME/.config/TVerDown
   $ cp config/* $HOME/.config/TVerDown
   $ vi $HOME/.config/TVerDown/config.rb
   ```

    | パラメータ    |  意味                                          |
    |---------------|------------------------------------------------|
    | DbDir         | database の保存ディレクトリ
    | CacheDir      | キャッシュの保存ディレクトリ
    | SpoolDir      | ダウンロードしたファイルの保存ディレクトリ
    | DbFname       | DataBase file 名
    | YTDLP_cmd     | yt-dlp の実行ファイル
    | YTDLP_opt     | yt-dlp のオプション
    | HEADLESS      | ブラウザを headless で起動するかの初期値
    | LogFn         | ログファイルのパス
    | ProgExpire    | 古い番組データを保持する日数(day) 0で削除しない。
    | LogExpire     | 古いdownload記録を保持する日数(day) 0で削除しない。
    | FnOpt         | ファイル名に付加するオプションの初期値(0=なし、1=日付、2=シリアル番号)
    | NewMark       | new印を付ける日数
    | HttpPort      | httpd のポート番号
    | WNP_cateTop   | 番組名を検索するページのURL
    | WNP_RSS_ON    | RSS を生成するか ( true = する )
    | WNP_RSS_NUM   | RSS に出力する過去の履歴の個数 
    | WNP_RSS_FNAME | RSS を出力するファイル名 
    | WNP_RSS_LINK  | RSS ファイルに埋め込む link アドレス

   なお config.rb 検索の優先順位は次の通り

     1. --configDir, -C オプションで指定したディレクトリ
     1. 環境変数 TVERDOWN_CONF_DIR で指定したディレクトリ
     1. ディレクトリ $HOME/.config/TVerDown 

## 使用方法


1. 番組情報の取得を実行する。

   ```
   $ ruby  $HOME/TVerDown/com/watchNewProg2.rb
   ```

1. WEBサーバーを立ち上げる。
   ```
   $ sh $HOME/TVerDown/com/run_TD.sh --httpd
   ```
1. WEBブラウザで、http://localhost:42101 にアクセスし、download 対象を選ぶ。
   (42101は HttpPort で指定 )

1. 定期的に番組情報の取得とdownload プログラムを実行する。
   ```
   $ sh $HOME/TVerDown/com/run_TD.sh
   ```

## おまけツール

* x265conv.rb

    TVer からダウンロードしたファイルはサイズが大きいので、
    X265 にエンコードするプログラム。
    
    * config.rb 中の以下のパラメータで制御される。
    
      | パラメータ    |  意味                                          |
      |---------------|------------------------------------------------|
      | ConvInDir     | 変換元のファイルが有るディレクトリ
      | ConvOutDir    | 変換後のファイルを格納するディレクトリ
      | ConvLockfn    | 多重起動防止の為のロックファイル名
      | ConvCmd       | ffmpeg の実行スクリプトの指定。libexe の下
      | ConvSufFix    | 変換後のディレクトリ付加する文字列 
      | X264expire    | 変換済みの mp4ファイルの保存期間(日)

    * 変換が終了したファイルの先頭に @@_ を付加する。
    * @@_ が付いたファイルは、X264expire 日後に削除される。


## 実行オプション

* TVerDown2.rb
  |   オプション       |      説明                                   |
  |--------------------|---------------------------------------------|
  | -C, --configDir=dir|  config.rb,target.rb のあるDir を指定する。 |
  |    --done          |  download せずに、download終了とする。      |
  | -D, --dryrun       |  download せずに、状況表示のみで終了する。  |
  | -F, --force        |  累積エラーでも無視して download する。     |
  | -H, --no-headless  |  chrome をヘッドレスで起動しない。          |
  | -N, --no-cache     |  キャッシュを使用しない。                   |
  | -R, --regex=str    |  正規表現で、download対象を絞る。           |
  | -v, --verbose      |  冗長表示                                   |
  |     --version      |  Version 表示                               |
  | -d, --debug        |  デバッグ モード                            |
  | -h, --headless     |  chrome をヘッドレスで起動する。            |
  |     --help         |  help メッセージ                            |
  | -n, --maxnum=n     |  download 個数制限                          |

* watchNewProg2.rb
  |   オプション       |      説明                                   |
  |--------------------|---------------------------------------------|
  | -C, --configDir=dir|  config.rb,target.rb のあるDir を指定する。 |
  | -H, --no-headless  |   chrome をヘッドレスで起動しない。         |
  | -h, --headless     |   chrome をヘッドレスで起動する。           |
  | -N, --no-cache     |   キャッシュを使用しない。                  |
  |     --version      |   Version 表示                              |
  |     --help         |   help メッセージ                           |

* x265conv.rb
  |   オプション       |      説明                                   |
  |--------------------|---------------------------------------------|
  | -C, --configDir=dir|  config.rb,target.rb のあるDir を指定する。 |
  | -M, --maxproc=n    |    変換数の制限                             |
  | -F, --force        |    ロックを無視して実行する。               |
  |     --help         |  help メッセージ                            |


* http.rb
  |   オプション       |      説明                                   |
  |--------------------|---------------------------------------------|
  | -C, --configDir=dir|  config.rb,target.rb のあるDir を指定する。 |
  |     --kill         |  httpd のプロセスを kill する。             |
  |     --help         |  help メッセージ                            |


## 注意点

* まれに TVer側の仕様が変わり、yt−dlp でのダウンロードが失敗する事があります。
  その場合は、yt-dlp が対応するのをまって、アップデートして下さい。
   ```
   $ ./yt-dlp --update
   ```

* cron で実行する場合は、ヘッドレスモード (-h) で実行すること。

* ダウンロードするファイルの一時保存の為に /tmp を使用するので、
  空き容量を確保する必要があります。

## ライセンス
このソフトウェアは、MIT ライセンスのも
とで公開します。詳しくは LICENSE を見て下さい。


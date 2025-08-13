


## 開発の背景と目的

普段使っている Ubuntu上の vivaldi はサポート外のため、
ブラウザで TVer の動画を視聴することが出来ない。<br>
そのため、ブラウザで URL を確認し、yt-dlp でダウンロードし、
mpv等で再生するという手作業を行っていた。

本プログラムは、それを自動化し TVer の目的番組を
バッチ的にダウンロードするための補助プログラムです。

## 動作概要

* あらかじめ目的の番組を target ファイルに記述する。
* プログラムを実行すると、
  * chromium で目的の番組ページを取得する。
  * ページ中から動画の URL を抽出
  * URL が既に download済みか、DB から検索
  * 検索して未了ならば、download 開始
  * download が正常終了ならば DB に完了登録
* cron で定期的に実行するように設定すれば、新規登録された動画を自動で取得できる。


## 動作環境
* Ubuntu 24.04 LTS (多分Unix系ならなんでも)
* ruby  3.2 以上
* sqlite3
* ruby-nokogiri
* chromium
* python 3
* yt-dlp
* ffmpeg


## インストール

1. 想定のディレクトリ構成

   |   dir                   | 説明                           |
   |-------------------------|--------------------------------|
   |  $HOME/TVerDown/prog    | プログラム インストール Dir    |
   |  $HOME/TVerDown/db      | database 保存Dir               |
   |  $HOME/TVerDown/Cache   | 番組ページのキャッシュ保存 Dir |
   |  $HOME/TVerDown/spool   | 動画保存 Dir                   |

1. 必要なツールをパッケージからインストールする。(ubuntu の場合)

   ```
   $ sudo apt install -y ruby ruby-dev ruby-sqlite3 ruby-nokogiri chromium-browser sqlite3 wget python3 git make gcc ffmpeg
   $ sudo gem install ferrum
   ```
1. yt-dlp のインストール
   yt-dlp は頻繁にアップデートされるのでパッケージではなく、
   配布元から直接インストールする。
   ```
   $ mkdir -p $HOME/TVerDown/com
   $ cd $HOME/TVerDown/com
   $ wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
   $ chmod +x yt-dlp
   ```

1. TVerDown 本体のインストール

   ```
   $ cd $HOME/TVerDown/prog
   $ git clone --depth 1 https://github.com/kaikoma-soft/TVerDown.git .
   ```
1. config.rb, target.rb のコピー

   $HOME/TVerDown/prog/config の下に設定ファイルの雛形が有るので、
   $HOME/.config/TVerDown にコピーし、自分の環境に合わせて適宜変更する。

   ```
   $ mkdir -p $HOME/.config/TVerDown
   $ cp config/* $HOME/.config/TVerDown
   $ vi config.rb
   ```

    | パラメータ    |  意味                                          |
    |---------------|------------------------------------------------|
    | DbDir         | database の保存ディレクトリ
    | CacheDir      | キャッシュの保存ディレクトリ
    | SpoolDir      | ダウンロードしたファイルの保存ディレクトリ
    | DbFname       | Database file 名
    | YTDLP_cmd     | yt-dlp の実行ファイル
    | YTDLP_opt     | yt-dlp のオプション
    | HEADLESS      | ブラウザを headless で起動するかの初期値
  
   なお config.rb, target.rb 検索の優先順位は次の通り

     1. --configDir, -C オプションで指定したディレクトリ
     1. 環境変数 TVERDOWN_CONF_DIR で指定したディレクトリ
     1. ディレクトリ $HOME/.config/TVerDown 

## 使用方法

1. target.rb に、目的の番組を記述する。
   * 記述例
      ```
      TARGET = [
        [ "series/sr85a3356t", "きょうの料理ビギナーズ",  nil ],
        [ "series/srx2o7o3c8", "WBS",                    "Date"],
        [ "series/srnk9ijw9v", "全力完走",               "Serial"],
      ]
      ```

    * 説明

      書式は ruby の２次元配列で、次のパラメータを記述する。
      |  要素   |  意味                                       |
      |---------|---------------------------------------------|
      | 1番目   | 番組ページの URL (https://tver.jp は省略可) |
      | 2番目   | 動画を格納する Dir名                        |
      | 3番目   | オプションの指定(下記参照)                  |

    * オプションの説明

      |  オプション   |  意味                                          |
      |---------------|------------------------------------------------|
      | nil           | 何もしない                                     |
      | Date          | 日付(YYYY-MM-DD)をファイル名の先頭に付加する。 |
      | Serial        | 連番をファイル名の先頭に付加する。             |
       なお、先頭の文字で判断するので、"D","S" でも可
  
    *  雛形を生成する makeTarget.rb (後述)


1. 実行方法

   ```
   $ sh $HOME/TVerDown/prog/run_TD.sh
   ```

## おまけツール

* makeTarget.rb

   chrome系のブラウザの bookmark ファイルを読んで,
   URL が "http://tver.jp/series" なものを抽出し、tagrget.rb の雛形を
   出力する。

   ```
   使用法: makeTarget [オプション]... 

    -j, --json=file   読み込む json ファイルを指定する。指定しない場合は、
                      ~/.config/google-chrome/Default/Bookmarks
        --help        help メッセージ
   ```


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

* TVerDown.rb
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

* x265conv.rb
  |   オプション       |      説明                                   |
  |--------------------|---------------------------------------------|
  | -C, --configDir=dir|  config.rb,target.rb のあるDir を指定する。 |
  |  -M, --maxproc=n   |    変換数の制限                             |
  |  -F, --force       |    ロックを無視して実行する。               |
  |     --help         |  help メッセージ                            |

* makeTarget.rb
  |   オプション       |      説明                                   |
  |--------------------|---------------------------------------------|
  | -j, --json=file    |  読み込む json ファイルを指定する。         |
  |     --help         |  help メッセージ                            |


## 注意点

* まれに TVer側の仕様が変わり、yt−dlp でのダウンロードが失敗する事があります。
  その場合は、yt-dlp が対応するのをまって、アップデートして下さい。
   ```
   $ ./yt-dlp --update
   ```


## ライセンス
このソフトウェアは、MIT ライセンスのも
とで公開します。詳しくは LICENSE を見て下さい。


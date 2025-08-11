


## 目的

本プログラムは, yt-dlp を使って TVer (https://tver.jp) の目的番組を
バッチ的にdownload するための補助プログラムです。

## 動作概要

* あらかじめ目的の番組を target ファイルに記述する。
* プログラムを実行すると、
  * chromium で目的番組のページを取得する。
  * ページ中から動画の URL を抽出
  * URL が既に download済みか、DB から検索
  * 検索して魅了ならば、download 開始
  * 正常終了ならば DB に登録

## 環境
* Ubuntu 24.04 LTS (多分Unix系ならなんでも)
* ruby  3.2 以上
* sqlite3
* ruby-nokogiri
* chromium
* python 3
* yt-dlp
* ffmpeg (エンコードするなら)


## インストール

* 想定のディレクトリ構成

  |   dir                   | 説明                           |
  |-------------------------|--------------------------------|
  |  $HOME/TVerDown/prog    | プログラム インストール Dir    |
  |  $HOME/TVerDown/db      | database 保存Dir               |
  |  $HOME/TVerDown/Cache   | 番組ページのキャッシュ保存 Dir |
  |  $HOME/TVerDown/spool   | 動画保存 Dir                   |

* 必要なツールをパッケージからインストールする。(ubuntu の場合)

  ```
  $ sudo apt install -y ruby ruby-dev ruby-sqlite3 ruby-nokogiri chromium-browser sqlite3 wget python3 git make gcc
  $ sudo gem install ferrum
  ```
* yt-dlp のインストール
  yt-dlp は頻繁にアップデートされるのでパッケージではなく、
  配布元から直接インストールする。
  ```
  $ mkdir -p $HOME/TVerDown/com
  $ cd $HOME/TVerDown/com
  $ wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp
  $ chmod +x yt-dlp
  $ ./yt-dlp --update
  ```

* 本体のインストール

  ```
  $ cd $HOME/TVerDown/prog
  $ git clone --depth 1 https://github.com/kaikoma-soft/TVerDown.git .
  ```
* config.rb, target.rb の変更

  $HOME/TVerDown/prog/config の下に設定ファイルが有るので、
  $HOME/.config/TVerDown にコピーし、自分の環境に合わせて適宜変更する。

  ```
  $ mkdir -p $HOME/.config/TVerDown
  $ cp config/* $HOME/.config/TVerDown
  $ vi config.rb
  ```

  なお config.rb, target.rb 検索の優先順位は次の通り

    1. --configDir, -C オプションで指定したディレクトリ
    1. 環境変数 TVERDOWN_CONF_DIR で指定したディレクトリ
    1. ディレクトリ $HOME/.config/TVerDown 

## 使用方法


## オプション


## おまけツール


## ライセンス
このソフトウェアは、MIT ライセンスのも
とで公開します。詳しくは LICENSE を見て下さい。


#!/usr/bin/ruby
# -*- coding: utf-8 -*-

#
#  ジャンル毎にページに追加/削除された番組を検出し DB に登録する。
#

require 'fileutils'
require 'optparse'
require 'open-uri'
require 'find'
require 'ferrum.rb'


require_relative 'lib/Const.rb'
require_relative 'lib/Sqlite.rb'
require_relative 'lib/MyFerrum.rb'
require_relative 'lib/common.rb'
require_relative 'lib/readConf.rb'
require_relative "lib/noko.rb"


class Main

  def initialize( )

    $opt = Opt.new
    $opt.parser()

    #
    #  config の読み込み
    #
    readConf( $opt.config )

    def confChk( sym )
      if Object.const_defined?( sym ) != true
        printf( "Error: %s not found in config\n", sym.to_s )
        exit
      end
    end
    
    confChk( :CacheDir )
    confChk( :WNP_cateTop )

    if Object.const_defined?( :WNP_RSS_ON )
      confChk( :WNP_RSS_NUM )
      confChk( :WNP_RSS_FNAME )
      confChk( :WNP_RSS_LINK )
    else
      Object.const_set( :WNP_RSS_ON, false )
    end

    $opt.hl = HEADLESS if $opt.hl == nil
      
    log("#{$opt.pname} start") if $opt.v == true
    run()
    log("#{$opt.pname} end") if $opt.v == true
    
  end

  #
  #  実行
  #
  def run(  )

    @mf = MyFerrum.new( $opt.hl )
    @mn = Mynoko.new
    @db = SqlDB.new

    @db.open( tran: true ) do |db2| # table の追加
      db2.chk_progTable()       # Ver1.0 用
      db2.chk_progTable2()      # Ver2.0 用
    end

    @mf.setup()

    text = []                   # RSS text
    WNP_cateTop.each_pair do |url, cate|
      tmp = getSeries( url, cate )
      text << "" if tmp.size > 0 and text.size > 0
      text += tmp
    end

    if text.size > 0
      @db.open( ) do |db2|
        sql = "insert into rssText ( text,ctime ) values (?,?)"
        db2.execute( sql, [ text.join("<br>\n"), Time.now.to_i ])

      end
    end

    if WNP_RSS_ON == true
      makeRSS( WNP_RSS_FNAME )
    end

    @db.open( ) do |db2|
      db2.expire()              # Expire
    end
    
  end


  #
  #  カテゴリのTopで、Series を抽出
  #
  def getSeries( urlC, cate )

    cf = @mf.cacheFname( urlC )
    if @mf.get?( urlC ) == true
      @mf.get( urlC )
    end
    printf("%s %s\n",urlC,cf) if $opt.v == true

    pl2 = {}
    count = 0                   # <a> の数を数える
    File.open( cf, "r" ) do |fp|
      doc = Nokogiri.HTML( fp )
      doc.xpath("//a").each do |tmp|
        if tmp[:href] =~ /series/
          url  = tmp[:href]
          if tmp.at("img") != nil
            name = tmp.at("img")[:alt]
            if name != "バナー"
              pl2[ url ] = Prog2.new( 0, cate, url, name )
            end
          else
            pp tmp if $opt.d == true
          end
        end
        count += 1
      end
    end
    printf("count = %d\n", count) if $opt.v == true
    if count < 80
      printf("Error: a タグの数が不足 %s %d\n",urlC, count)
      return []
    end

    buf1 = []                   # 標準出力向け
    buf2 = []                   # RSS 向け
    @db.open( tran: true ) do |db2|
      now = Time.now.to_i

      # 追加の検出
      pl2.each_pair do |url, prog2 |
        if prog2.urlCheck( @db ) == true
          unless url =~ /^http/
            url2 = File.join( TVERJP, url )
          else
            url2 = url
          end
          buf1 << sprintf("add %-24s %s\n",prog2.url, prog2.title )
          buf2 << sprintf("add <a href=%s>%-24s</a> %s\n",url2,url, prog2.title )
          prog2.insertPL( @db )
        end
      end
    end

    if buf1.size > 0
      tmp = sprintf("\n+++++  %s +++++\n",cate) 
      buf1.unshift( tmp )
      buf2.unshift( tmp )
      buf1.each do |tmp|
        puts( tmp )
      end

    end
    
    return buf2
  end

  #
  #  RSS の生成
  #
  require "rss"

  def makeRSS( output = nil )

    textA = nil
    @db.open( ) do |db2|
      sql = "select text,ctime from rssText order by ctime desc LIMIT "
      sql += WNP_RSS_NUM.to_s
      textA = db2.execute( sql )
    end
    return if textA == nil or textA.size == 0

    rss = RSS::Maker.make("2.0") do |maker|
      #xss = maker.xml_stylesheets.new_xml_stylesheet
      #xss.href = "http://example.com/index.xsl"
      #maker.channel.about = "http://example.com/index.rdf"
      
      maker.channel.title = "TVerDown watchNewProg"
      maker.channel.description = "TVer 番組変更検出"
      maker.channel.link = "WNP_RSS_LINK"
      maker.items.do_sort = true

      textA.each do |tmp|
        ( text, ctime ) = tmp
        maker.items.new_item do |item|
          date = Time.at( ctime ).strftime("%Y/%m/%d %H:%M" )
          item.title = "TVer 番組変更情報 " + date
          item.date = Time.at( ctime )
          item.summary = text
        end
      end

    end

    if output == nil
      puts rss
    else
      File.open( output, "w") do |fp|
        fp.puts rss
      end
    end
  end
end


class SqlDB

  #
  #  TABLE progList の追加
  #
  def add_table_progList( )
    sql = <<EOS
create table progList (
    id                  integer  primary key,
    url                 text,    -- URL
    title               text,    -- タイトル
    cate                text,    -- カテゴリ名
    ctime               integer  -- 作成日
);

create index pl1 on progList (title) ;
create index pl2 on progList (url) ;
create index pl3 on progList (ctime) ;
create index pl4 on progList (id) ;
create index pl5 on progList (cate) ;

create table rssText (
    id                  integer  primary key,
    text                text,    -- 内容
    ctime               integer  -- 作成日
);

create index rt1 on rssText (ctime) ;


EOS
    @db.execute_batch(sql)
  end
  
  #
  #  progList TABLE が有るか？ 無ければ作る。
  #
  def chk_progTable()
    sql = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='progList';"
    ret = @db.execute( sql )
    if ret[0][0] == 0 
      puts("add_table_progList")
      add_table_progList( )
    end
  end

  #
  #  TABLE progList2 の追加
  #
  def add_table_progList2( )
    sql = <<EOS
--
-- 番組リスト 改定版
--
create table progList2 (
    id                  integer  primary key,
    cate                text,    -- カテゴリ名
    url                 text,    -- URL
    title               text,    -- タイトル
    flag                integer, -- 1 = download 対象
                                 -- 0 = 未
                                 -- 2 = 完了
                                 -- 3 = 無視
    ctime               integer, -- 作成日時
    atime               integer, -- 更新日時(expire用)
    fnameopt            integer  -- ファイル名の加工オプション
                                 --    0 = なし
                                 --    1 = 日付
                                 --    2 = シリアル番号
);
create index pl21 on progList2 (title) ;
create index pl22 on progList2 (url) ;
create index pl23 on progList2 (ctime) ;
create index pl24 on progList2 (atime) ;
create index pl25 on progList2 (id) ;
create index pl26 on progList2 (cate) ;
create index pl27 on progList2 (fnameopt) ;

--
--  パラメータ記録用
--
create table memo (
    id                  integer  primary key,
    key                 text,    --
    val                 text     --
);
create index m1 on memo (key) ;

EOS
    @db.execute_batch(sql)
  end
  
  #
  #  progList TABLE が有るか？ 無ければ作る。
  #
  def chk_progTable()
    sql = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='progList';"
    ret = @db.execute( sql )
    if ret[0][0] == 0 
      puts("add_table_progList")
      add_table_progList( )
    end
  end

  #
  #  progList2 TABLE が有るか？ 無ければ作る。
  #
  def chk_progTable2()
    sql = "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='progList2';"
    ret = @db.execute( sql )
    if ret[0][0] == 0 
      puts("add_table_progList2")
      add_table_progList2( )
    end
  end

  #
  #  select progList2
  #
  def selectPL( id: nil, cate: nil, url: nil )
    sql = "select * from progList2 "
    arg = []
    if id != nil
      sql += " where id = ? "
      arg << id
    end
    if cate != nil
      sql += " where cate = ? "
      arg << cate
    end
    if url != nil
      sql += " where url = ? "
      arg << url
    end
    sql += " order by ctime desc, title "

    r = []

    @db.execute( sql, arg ).each do |tmp|
      tmp2 = tmp.dup
      r << Prog2.new( *tmp2 )
    end
    
    return r
  end


  #
  #  削除 progList2
  #
  def deletePL( url: nil, id: nil )
    sql = "delete from progList2  "
    arg = []
    if id != nil
      sql += " where id = ? "
      arg << id
    end
    if url != nil
      sql += " where url = ? "
      arg << url
    end
    
    @db.execute( sql, arg )
  end

  #
  #  download flag のset
  #
  def setFlag( id, val )
    sql = "update progList2 set flag = ? where id = ? "
    @db.execute( sql, [ val, id ] )
  end


  #
  #  ファイル名オプションのset
  #
  def setFOpt( id, val )
    sql = "update progList2 set fnameopt = ? where id = ? "
    @db.execute( sql, [ val, id ] )
  end

  #
  #  URL, タイトルの変更
  #
  def updatePL( id, url, title )
    sql = "update progList2 set url = ?, title = ? where id = ? "
    @db.execute( sql, [ url, title, id ] )
  end

  #
  #  期限切れデータの expire  
  #
  def expire( pday = ProgExpire, lday = LogExpire )

    #
    #  progList2 の削除
    #
    if pday != 0
      th = Time.now.to_i - ( pday * 24 * 3600 )

      sql = "select cate,title,ctime from progList2 where flag != 1 and atime < ?  order by cate,title"
      @db.execute( sql, [ th ] ).each do |tmp|
        ( cate, title, ctime ) = tmp
        printf("Expire %s %s\n",cate, title)
      end
      sql = "delete from progList2 where flag != 1 and atime < ?"
      @db.execute( sql, [ th ] )
    end
    
    #
    # downlog の削除
    #
    if lday != 0
      th = Time.now.to_i - ( lday * 24 * 3600 )
      sql = "select title,ctime from downlog where ctime < ?  order by title"
      @db.execute( sql, [ th ] ).each do |tmp|
        ( title,ctime ) = tmp
        t = Time.at( ctime ).strftime("%F")
        printf("Expire downlog %s %s\n",t, title)
      end
      sql = "delete from downlog where ctime < ? "
      @db.execute( sql, [ th ] )
    end

    #
    # RSS
    #
    sql = <<EOS
        delete FROM rssText WHERE id IN (
            SELECT id FROM rssText
            ORDER BY ctime DESC limit -1  OFFSET #{WNP_RSS_NUM} );
EOS
    @db.execute( sql )
    
    @db.execute( "vacuum" )
  end
  
end


#
#  番組情報
#
class Prog2
  
  attr_accessor :id, :cate, :url, :title, :flag, :ctime, :atime, :fnameopt

  def initialize( id, cate, url, title, flag=0, ctime=nil, atime=nil, fnameopt=FnOpt )
    @id   = id
    @cate = cate
    @url  = url
    @title = title
    @flag = flag
    @ctime = ctime == nil ? Time.now.to_i : ctime
    @atime = atime == nil ? @ctime : atime
    @fnameopt = fnameopt
  end

  #
  #  DB に追加 progList2
  #
  def insertPL( db )
    sql = "insert into progList2 ( cate, url, title, flag, ctime, atime, fnameopt ) values ( ?,?,?,?,?,?,? ) "
    db.execute( sql, [ @cate, @url, @title, @flag, @ctime, @atime, @fnameopt ] )
  end

  #
  #  url がすでに登録されているか？ ない=true, ある=false
  #  ある場合 atime を更新
  #
  def urlCheck( db )
    sql = "select atime from progList2 where url = ? "
    tmp = db.execute( sql, @url )
    if tmp.size == 0
      return true
    else
      sql = "update progList2 set atime = ? where url = ? "
      db.execute( sql, Time.now.to_i, @url )
      puts("atime 更新 #{@title}") if $opt.v == true
    end
    return false
  end

end

if $0 == __FILE__

  #
  #  オプション
  #
  class Opt
    attr_accessor :v, :d, :hl, :n, :cache, :config
    attr_accessor :rss, :test, :pname

    def initialize()
      @d     = false              # debug
      @hl    = nil                # headless 
      @cache = true               # キャッシュを使うか？
      @config = nil               # config ファイル
      @v     = false              # verbose
      @test   = false             # TEST mode
    end

    def parser()
      OptionParser.new do |opt|
        @pname = opt.program_name
        opt.version = ProgVer
        opt.on('-C dir', '--configDir dir') {|v| @config = v } 
        opt.on('-h', '--headless')          { @hl = true  } 
        opt.on('-H', '--no-headless')       { @hl = false } 
        opt.on('-N', '--no-cache')          { @cache = ! @cache } 
        opt.on('-d', '--debug' )            { @d = ! @d  } 
        opt.on('-v', '--verbose' )          { @v = ! @v } 
        opt.on('-T', '--test' )             { @test = ! @test }
        opt.on('--help' )                   { usage() } 
        opt.parse!(ARGV)
      end

    end

    def usage()
      puts <<EOS
使用法: #{@pname} [オプション]... 

 -C, --configDir=dir   config.rb のあるDir を指定する。
 -H, --no-headless     chrome をヘッドレスで起動しない。
 -h, --headless        chrome をヘッドレスで起動する。
 -N, --no-cache        キャッシュを使用しない。
     --version         Version 表示
     --help            help メッセージ
EOS
      exit
    end

  end
end



if $0 == __FILE__

  Main.new
  
end

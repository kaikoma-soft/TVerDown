#!/usr/bin/ruby
# -*- coding: utf-8 -*-

require 'sqlite3'


class SqlDB

  def initialize( dbFname = DbFname )
    @db = nil
    @DBfile = dbFname
    unless File.exist?( @DBfile )
      open( ) do |db|
        createDB()
      end
      File.chmod( 0600, @DBfile )
    end

    @para = %W( url title ctime failcount )
  end

  #
  #  SQLite DB の初期化
  #
  def createDB( )
    sql = <<EOS
--
-- BWdata
--
create table downlog (
    id                  integer  primary key,
    url                 text,    -- URL
    title               text,    -- タイトル
    ctime               integer, -- 作成日
    failcount           integer  -- 失敗回数
);

-- ALTER TABLE downlog ADD COLUMN failcount integer;
-- create index ch5 on downlog (failcount);

create index ch1 on downlog (title) ;
create index ch2 on downlog (url) ;
create index ch3 on downlog (ctime) ;
create index ch4 on downlog (id) ;

EOS
    @db.execute_batch(sql)
  end

  
  #
  #  DB open  mode = :immediate or :deferred or :exclusive
  # 
  def open( tran: false, mode: :immediate )       # tran = true transaction
    @db = SQLite3::Database.new( @DBfile )
    @db.busy_timeout(1000)
    ecount = 0
    roll = false
    begin
      roll = false
      if tran == true
        @db.transaction( mode ) do
          roll = true
          yield self
        end
      else
        yield self
      end
    rescue SQLite3::BusyException => e
      begin
        @db.rollback() if roll == true
      rescue
        pp "rollback fail #{$!}"
      end
      if ecount > 59
        printf( "SQLite3::BusyException exit", $!, e )
        return
      else
        ecount += 1
        sleep( 1 )
        retry
      end
    rescue => e
      puts "SQLite3::another error", $!, e.backtrace
      begin
        @db.rollback() if roll == true
      rescue
        pp "rollback fail #{$!}"
      end
      return
    ensure
      close()
    end
  end
  
  def close
    if @db != nil
      @db.close()
      @db = nil
    end
  end

  def execute( *args )
    @db.execute( *args )
  end

  def prepare( str )
    @db.prepare( str )
  end

  #
  #  select
  #
  def select(id:     nil,
             title:  nil,
             url:    nil,
             order:  nil
            )
    where = []
    args = []
    sql = "select " + @para.join(",") + " from downlog "
    if id != nil
      where << " id = ? "
      args << id
    end
    if  title != nil
      where << " title like ? "
      args << title
    end
    if url != nil
      where << " url = ? "
      args << url
    end

    if where.size > 0
      sql += " where " + where.join(" and ")
    end
    
    if order == nil
      sql += " order by id "
    else
      sql += order
    end
    sql += ";"

    tmp = @db.execute( sql, args )
    return tmp
  end

  #
  #  既に存在しているか
  #
  def exist?( url )
    sql = "select url from downlog where url = ? "
    r = @db.execute( sql, url )
    return true if r.size > 0
    return false
  end
  
  #
  #  追加
  #
  def insert( url, title, ctime )

    sql = "insert into downlog ( " + @para.join(",") + ") values ("
    sql += ( Array[ "?"] * @para.size).join(",")
    sql += " )"
    
    args = []
    args << url
    args << title
    args << ctime
    args << 0

    @db.execute( sql, args )
  end

  #
  #   failcount のインクリメント
  #
  def failInc( url )
    sql = "update downlog set failcount = failcount + 1 where url = ? "
    @db.execute( sql, url )
  end

  #
  #   failcount の
  #
  def downEnd( url )
    sql = "update downlog set failcount = ? where url = ? "
    @db.execute( sql, EOD, url )
  end
  
end

if $0 == __FILE__

  db = SqlDB.new
  db.open() do |db2|
    #db2.insert( "aaa", "bbbb", Time.now.to_i )
    db2.failInc( "aaa" )
  end

end

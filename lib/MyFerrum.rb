
require 'ferrum'
require 'io/console'
require 'nokogiri'
require "tmpdir"
require "digest/md5"



class MyFerrum

  def initialize( headless = true )

    @saveDir = BaseDir
    @downdir = BaseDir
    @cookiesFn = File.join( DbDir, "ferrumCookies.yaml" )
    @browser   = nil
    @headless = headless

  end

  def setup()
    
    port = 9225
    rcount = 0
    begin
      @browser = Ferrum::Browser.new( headless: @headless,
                                      port: port,
                                      timeout: 10,
                                      window_size: [1000,500],
                                    )
      sleep(1)
      cookiesLoad()
    rescue Ferrum::DeadBrowserError => e
      rcount += 1
      if rcount < 5
        sleep(10)
        log("Ferrum::Browser.new retry #{rcount} #{e.class}")
        retry
      else
        raise e
      end
    end
    
  end


  #
  #  キャッシュのファイル名生成
  #
  def cacheFname( url )
    hash = Digest::MD5.hexdigest(url)
    path = File.join( CacheDir, hash + ".html" )
    return path
  end

  #
  #  down するか?
  #
  def download?( fn )
    return true if $opt.cache == false
    if test( ?f, fn )
      ctime = File.ctime( fn )
      if ctime < ( Time.now - Expire )
        return true
      end
    else
      return true
    end
    return false
  end
  
  #
  #   取得
  #
  def get( url )
    cf = cacheFname( url )
    if download?( cf ) == true
      goto( url ) 
      saveHtml( cf )
    end
    return cf
  end

  #
  #   取得するか判定
  #
  def get?( url )
    cf = cacheFname( url )
    return download?( cf )
  end
  
  def fin()
    cookiesSave()
    @browser.quit
  end

  
  def goto( url )
    log("get #{url}") if $opt.v == true
    rcount = 0
    begin
      @browser.go_to( url )
      sleep(1)
    rescue Ferrum::StatusError, Ferrum::PendingConnectionsError => e
      rcount += 1
      if rcount < 5
        sleep(10)
        log("goto retry #{rcount} #{e.class}")
        retry
      else
        endProc( )
        raise NetSlow
      end
    end
    sleep(1)
  end

  def cookiesLoad()
    if test( ?f, @cookiesFn )
      @browser.cookies.load(@cookiesFn)
    end
  end

  def cookiesSave()
    @browser.cookies.store( @cookiesFn )
  end
  

  #
  #  html の save
  #
  def saveHtml( fname )
    File.open( fname,"w") do |fp|
      fp.puts @browser.body
    end
    return fname
  end

end



if $0 == __FILE__

end

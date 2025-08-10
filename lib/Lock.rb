# coding: utf-8

#
#   多重起動防止
#

class Locked

  def initialize( lockfname, expT = 3600 * 6 )
    @lockfname = lockfname
  end
  
  # 排他制御用ラッパー
  def synchronized()
    # フォルダーがない時エラーが生じるので、あらかじめ生成しておく
    File.open( @lockfname, 'w') do |lock_file|
      # 排他ロック
      if lock_file.flock(File::LOCK_EX|File::LOCK_NB)
        yield
      else
        raise "[Error] #{@lockfname} in use"
      end
    end
    if test(?f, @lockfname )
      File.unlink( @lockfname )
    end
  end

  # ロックの取得
  def locked?()
    return false if !File.exist?( @lockfname )
    File.open( @lockfname, 'r+') do |lock_file|
      # 共有ロックの取得を試みる、失敗した時はファイルの最終更新日時を返す
      lock_file.flock(File::LOCK_SH|File::LOCK_NB) ? false : lock_file.mtime
    end
  end

  # 使い方
  def run_synchronized
    locked_at = locked?()
    if locked_at
      puts "Locked at #{locked_at.strftime("%Y-%m-%d %H:%M:%S")}"
      return
    end
    
    synchronized() do
      p 'Start....'
      sleep(10)
      p 'End...'
    end
  end
end




class  Lock

  def initialize( lockfname, expT = 3600 * 6 )
    @lockfname = lockfname
    @expT      = expT
  end
  
  def lock?() 
    if test( ?f, @lockfname )
      now = Time.now
      mtime = File.mtime( @lockfname )
      if mtime > ( now - expT )  # expT 以内なら有効
        return true
      end
    end
    return false
  end

  def lock()
    FileUtils.touch( @lockfname )
  end

  def unlock()
    if test(?f, @lockfname )
      File.unlink( @lockfname )
    end
  end
  
end

    

# coding: utf-8

#
#  spool にある x264 を x265 に変換する。
#

require 'find'
require 'optparse'
require 'fileutils'

require_relative 'lib/Const.rb'
require_relative 'lib/common.rb'
require_relative 'lib/ffprob.rb'
require_relative 'lib/Lock.rb'
require_relative 'lib/x265Opt.rb'
require_relative 'lib/readConf.rb'

$opt = Opt.new

readConf( $opt.config )
raise "config not found" if Object.const_defined?(:SpoolDir) != true


#
#  出力先の生成
#
def makeOfname( f )
  dir = File.dirname( f )
  dir2 = File.basename( dir )
  base = File.basename( f )

  dir3 = dir2 + ( ConvSufFix == nil ? "" : ConvSufFix )
  r = File.join( ConvOutDir, dir3 , base )
  return r
end

#
#  変換
#
def conv( inf, outf, prog = "")

  st = Time.now
  mp4tmp = "/tmp/TVer-conv-tmp.mp4"
  logfn = "/tmp/TVer-conv-err.log"

  ffp = Mylib::ffprobe( inf )
  w = ffp[:width].to_i
  h = ffp[:height].to_i
  dir = File.dirname( outf )
  dir2 = File.basename( dir )
  base = File.basename( outf )

  cmd = File.join( File.dirname( $0 ), "libexe", ConvCmd )
  env = { "OUTPUT" => mp4tmp,
          "INPUT"  => inf, }

  printf("%s: %s %dx%d %s/%s\n",Time.now.strftime("%H:%M:%S"), prog, w,h, dir2,base )
  pid = spawn( env, cmd, [:out, :err] => [ logfn, "a"] )
  Process.waitpid( pid )

  speed = ""
  File.open( logfn ,"r" ) do |fp|
    fp.each_line do |l|
      if l =~ /(speed=.*?x)/
        speed = $1
      end
    end
  end
  if test( ?f, mp4tmp )
    s1 = File.size( mp4tmp )
    s2 = File.size( inf )
    s3 = ( s1.to_f / s2  ) * 100
    sa = ( Time.now - st ).to_i
    s12 = (s1 / (1024*1204)).to_i
    printf("       -> %d sec  %d MB (%2.1f%%)  %s\n",sa, s12, s3, speed )

    if s1 > 1 * 1024 * 1024    # 正常ならば 1M 以上はあるはず
      unless test( ?d, dir )
        Dir.mkdir( dir )
      end
      FileUtils.cp( mp4tmp, outf )
      File.unlink( mp4tmp )
    else
      puts "Error: mp4 file not found"
      return
    end
  end
  
end


#
#  処理済みのマークをつける
#
def addMark( fname )
  if test( ?f, fname )
    dir = File.dirname( fname )
    base = File.basename( fname )
    newfn = File.join( dir, sprintf("@@_%s",base ) )
    File.rename( fname, newfn )
  end
end

#
#  古い @@_ は、ファイル名を残して削除(0byte化)
#

def expireOrgMp4( fname )
  limit = Time.now - ( 3600 * 24 * X264expire )
  if test( ?f, fname )
    size = File.size( fname )
    if size > 0
      ctime = File.ctime( fname )
      if ctime < limit
        puts "del #{fname}"
        FileUtils.cp "/dev/null", fname
      end
    end
  end
end

#
#   main
#

[ ConvOutDir ].each do |dir|
  unless test( ?d, dir )
    printf("Error: dir not found %s\n",dir )
    exit
  end
end

list = {}
Find.find( ConvInDir ) do |f|
  if f =~ /\.mp4$/
    base = File.basename( f )
    if base =~ /^@@_/
      expireOrgMp4( f )
      next
    end

    ofname = makeOfname( f )
    if test( ?f, ofname )
      addMark( f )
    else
      list[ f ] = ofname
    end
  end
end

if $opt.force == true and test( ?f, ConvLockfn )
  File.unlink( ConvLockfn )
end

lock = Locked.new( ConvLockfn )
locked_at = lock.locked?()
if locked_at
  puts "Locked at #{locked_at.strftime("%Y-%m-%d %H:%M:%S")}"
  exit
end

lock.synchronized() do
  count = 1
  proccount = 1
  list.keys.sort.each do |infname|
    ofname = list[ infname ]
    next if test( ?f, ofname )

    if test( ?f, infname )
      mp4Lock = infname + ".lock" # 個別のlock( NFS での競合対策)
      if $opt.force == true and test( ?f, mp4Lock )
        File.unlink( mp4Lock )
      end
      lock2 = Locked.new( mp4Lock )
      if test(?f, mp4Lock )
        now = Time.now.strftime("%H:%M:%S")
        printf("%s: %d/%d %s is locked\n", now, count, list.size,  infname)
      else
        lock2.synchronized() do
          prog = sprintf("%d/%d",count, list.size )
          conv( infname, ofname, prog )
          if test( ?f, ofname )
            addMark( infname )
            proccount += 1
          end
        end
      end
    end
    count += 1
    break if proccount > $opt.maxproc
  end
end



#!/usr/local/bin/ruby 
# -*- coding: utf-8 -*-

#
#  top
#
require 'sys/filesystem'

class Top


attr_reader :cate, :list, :data, :tbldata
  
  def initialize( cateS, sd )
    $status = {} if $status == nil
    @cateS = cateS
    @session_disp = sd == nil ? 1 : sd
  end

  def setup
    @data = {}
    db = SqlDB.new
    @cate = {}
    db.open( ) do |db2|        # 
      db2.selectPL( cate: nil, url: nil ).each do |tmp|

        if @session_disp == 1   # 全部
          ; # NOP
        elsif @session_disp == 2 # Downのみ
          next if tmp.flag != 1
        elsif @session_disp == 3 # 完了のみ
          next if tmp.flag != 2
        elsif @session_disp == 4 # 未了のみ
          next if tmp.flag != 0
        elsif @session_disp == 5 # 無視以外
          next if tmp.flag == 3
        elsif @session_disp == 6 # 無視のみ
          next if tmp.flag != 3
        end
          
        @data[ tmp.cate ] ||= []
        @data[ tmp.cate ]  << tmp
        @cate[ tmp.cate ] = true
      end
    end
    count = 0
    @cate.keys.sort.each do |cate|
      @cate[ cate ] = count
      count += 1
    end
    
    makeTable()    
    return 
  end

  def pageSel()
    return []
  end

  def cateSel()
  end

  def printTD( str, clas: nil, id: nil, rid: nil, style: nil )
    attr = ""
    attr += %Q{class="#{clas.join(" ")}" } if clas != nil
    attr += %Q{id="#{id}" } if id != nil
    attr += %Q{rid="#{rid}" } if rid != nil
    attr += %Q{style="#{style}" } if style != nil
    %Q{ <td #{attr}> #{str} </td>}
  end

  def printTH( str, clas: nil, id: nil, rid: nil, style: nil )
    attr = ""
    attr += %Q{class="#{clas.join(" ")}" } if clas != nil
    attr += %Q{id="#{id}" } if id != nil
    attr += %Q{rid="#{rid}" } if rid != nil
    attr += %Q{style="#{style}" } if style != nil
    %Q{ <th #{attr}> #{str} </th>}
  end

  def printTR( data, id: nil, clas: nil )
    attr = []
    attr << %Q(class="#{clas.join(" ")}") if clas != nil
    attr << %Q(id="#{id}") if id != nil
    
    a = [ %Q{ <tr #{attr.join(" ")}> } ]
    a += data
    a << %Q{ </tr> }
    a.join("\n")
  end

  #
  # 先頭のカテゴリをactive にする
  #
  def active?( cate )
    return "active" if @cateS == cate
    return ""
  end
  
  def makeTable()
    @tbldata = {}

    return if @data == nil

    clas = %w(  ) # nowrap item
    @cate.keys.sort.each do |cate|
      tmp = []
      cateN = @cate[cate]
      cateK = sprintf("cate%d", cateN )
      tmp << %Q(<div id="#{cateK}" class="col s12"> )
      tmp << %q(<table class="striped">)  # 

      th = []
      th << printTH( "No" )
      th << printTH( "URL" )
      th << printTH( "状態" )
      th << printTH( "タイトル" )
      th << printTH( "オプション" )
      #th << printTH( "変更" )
      th << printTH( "作成日時" )
      tmp << printTR( th )
      
      count = 1
      now = Time.now.to_i
      @data[cate].each do |t|
        clasS = %w( nowrap )

        url = %Q(<a href="#{TVERJP}#{t.url}" target="_blank"> #{t.url} </a>)

        st = Time.at(t.ctime ).strftime("%Y-%m-%d %H:%M")
        st = %Q( <span did="#{t.id}" class="dialog"> #{st} </span> )
        if ( now - t.ctime ) < ( 3600 * 24 * NewMark )
          img = %Q( <img src="new.png" alt="新規">  )
        else
          img = ""
        end

        stat = case t.flag
               when 0 then "未"
               when 1 then "Down"
               when 2 then "完了"
               when 3 then "無視"
               end
        stat = %Q( <span did="#{t.id}" class="dialog" > #{stat} </span> )
        cb = %Q( <label> <span did="#{t.id}" class="dialog">  #{t.title} </span>  #{img} </label> )
        edit = %Q( <a class="waves-effect waves-light btn dialog" did="#{t.id}">編集</a>)
        edit = %Q( <a did="#{t.id}" class="dialog btn--orange btn--radius">変更</a> )
        sel = case t.fnameopt
              when 0 then "なし"
              when 1 then "日付"
              when 2 then "シリアル番号"
              end
        sel = %Q( <span did="#{t.id}" class="dialog"> #{sel} </span> )
        
        td = []
        td << printTD( count, clas: clas )
        td << printTD( url,   clas: clas )
        td << printTD( stat,  clas: clas )
        td << printTD( cb,    clas: clas )
        td << printTD( sel,   clas: clas )
        #td << printTD( edit,  clas: clas )
        td << printTD( st,    clas: clas )
        tmp << printTR( td )
        count += 1
      end
      tmp << %q(</table>)
      tmp << %q(</div>)
      
      @tbldata[ cate ] = tmp.join("\n")
    end
  end

  def tabtest()
    str = <<EOS
 <div class="row">
    <div class="col s12">
      <ul class="tabs">
        <li class="tab col s3"><a href="#test1">Test 1</a></li>
        <li class="tab col s3"><a class="active" href="#test2">Test 2</a></li>
        <li class="tab col s3 disabled"><a href="#test3">Disabled Tab</a></li>
        <li class="tab col s3"><a href="#test4">Test 4</a></li>
      </ul>
    </div>
    <div id="test1" class="col s12">Test 1</div>
    <div id="test2" class="col s12">Test 2</div>
    <div id="test3" class="col s12">Test 3</div>
    <div id="test4" class="col s12">Test 4</div>
</div>
EOS
    str
  end

  def dispChk?(n)
    if @dispChk == nil
      @dispChk = Array.new( 6, false ) 
    end
    @dispChk[ @session_disp ] = true
    return @dispChk[n]
  end
  
end


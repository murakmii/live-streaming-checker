"use strict"

# ポップアップを開いた際のライブ中,オフラインのグループを一覧表示するためのビュー
class GroupList extends Backbone.View

   @Type:
      Live     : "Live"
      Offline  : "Offline"

   tagName  : "div"
   className: "group-list"
   events   : 
      "click .header": "_onClickedHeader"

   # リストのヘッダーがクリックされた際のイベント
   # リストの折り畳み状態をトグルする
   _onClickedHeader: ( ) ->
      if @isOpened( )
         @close true
      else
         @open true

   # 保持しているアイテムがクリックされた際のイベント
   # クリックされたアイテムの保持しているグループIDを引数にイベントを発生させる
   _onClickedItem: ( e ) -> @trigger "click", e.getGroupId( )
  
   initialize: ( options ) ->

      @_count     = 0
      @_items     = { }
      @_opened    = false
      @_type      = options.type

      # テンプレートを取得
      tpl = document.getElementById( "group-list-tpl" ).content
      $( @el ).append tpl.cloneNode( true )

      # ヘッダーを構成
      @_h2 = @el.getElementsByTagName( "h2" )[ 0 ]
      @_h2.className = @_type.toLowerCase( )
      @_h2.innerText = "#{@_type}(#{@_count})"

      @_list      = @el.getElementsByClassName( "list" )[ 0 ]
      @_nogroup   = @_list.getElementsByClassName( "no-group" )[ 0 ] # 表示するアイテムがない場合に表示するメッセージ
      @_arrow     = @el.getElementsByClassName( "arrow" )[ 0 ]

      @delegateEvents( )

   # リストにアイテムを追加する
   setItems: ( items ) ->
      frg = document.createDocumentFragment( )
      for i in items
         @listenTo i, "click", @_onClickedItem
         @_items[ i.getGroupId( ) ] = i
         frg.appendChild i.el

      @_list.appendChild frg
      @_nogroup.style.display = "none" if ( @_count += items.length ) isnt 0
      @_h2.innerText = "#{@_type}(#{@_count})"

   # 保持している全ての配信情報を削除する
   clearAll: ( ) ->
      @_list.innerHTML = "" # あらかじめ内容をクリア

      for id, item of @_items
         @stopListening item
         item.remove( )

      @_items  = { }
      @_count  = 0
      @_nogroup.style.display = "block"
      @_h2.innerText = "#{@_type}(#{@_count})"

   getType: ( ) -> @_type
   isOpened: ( ) -> @_opened

   # リストを開く
   # 引数でアニメーションを実行するかどうかを決定する
   open: ( animate ) ->
      @_opened = true
      @trigger "toggle", @
      $( @_arrow ).addClass "opened"
      if animate is true
         $( @_list ).stop( true ).slideDown 200
      else
         @_list.style.display = "block"

   # リストを閉じる
   # 引数でアニメーションを実行するかどうかを決定する
   close: ( animate ) ->
      @_opened = false
      @trigger "toggle", @
      $( @_arrow ).removeClass "opened"
      if animate is true
         $( @_list ).stop( true ).slideUp 200
      else
         @_list.style.display = "none"

@ui.view = { } unless @ui.view?
@ui.view.GroupList = GroupList



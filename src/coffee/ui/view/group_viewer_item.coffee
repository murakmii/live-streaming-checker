"use strict"

i18n = chrome.i18n.getMessage

# グループの詳細を表示する際の、配信情報を表示するためのビュー
class GroupViewerItem extends Backbone.View

   tagName  : "div"
   className: "item"
   events   :
      "click": "_onClicked"

   _onClicked: ( ) ->
      chrome.tabs.create url: @_broadcasting.getUrl( )

   initialize: ( options ) ->
      @_broadcasting = options.broadcasting.clone( )

      # テンプレートを取得
      tpl = document.getElementById( "group-viewer-item-tpl" ).content
      @el.className = 'item live' if @_broadcasting.isLive( )      

      # アイコンの設定
      icon = tpl.querySelector "i"
      if @_broadcasting.hasImageUrl( )
         icon.style.backgroundImage = "url(#{@_broadcasting.getImageUrl( )})"
         icon.style.display = "block"
      else
         icon.style.display = "none"

      # 配信情報の名前と属するサービス名を取得
      tpl.querySelector( "h3" ).innerText = @_broadcasting.getName( )
      tpl.querySelector( "h4" ).innerText = i18n @_broadcasting.getApiName( )

      @el.appendChild tpl.cloneNode( true )

      $( @el ).data( 'powertip', @_broadcasting.getName( ) ).powerTip
         placement: "s"
         intentPollInterval: 300
         closeDelay: 50

@ui.view.GroupViewerItem = GroupViewerItem

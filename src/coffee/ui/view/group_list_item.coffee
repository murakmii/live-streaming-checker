"use strict"

i18n = chrome.i18n.getMessage

# GroupListのアイテムのビュー
class GroupListItem extends Backbone.View

   tagName: "div"
   events :
      "click a": "_onClickedLink"
      "click"  : "_onClicked"

   # 視聴ページへのリンククリック時のイベント
   _onClickedLink: ( e ) -> e.stopPropagation( )

   _onClicked: ( ) -> @trigger "click", @

   initialize: ( options ) ->

      @_gid    = options.group.getId( )
      @_count  = core.Storage.countLive @_gid

      # テンプレートを取得
      tpl = document.getElementById( "group-list-item-tpl" ).content
      $( tpl.querySelector ".title" ).text options.group.getName( )
      if @_count > 0
         $( tpl.querySelector "p" ).text i18n( "group_live_status", [ @_count ] )
      else
         $( tpl.querySelector "p" ).text i18n( "group_offline_status" )

      # アイコンを設定
      icon = tpl.querySelector "i"
      if options.group.configuredThumbnail( )
         bi = options.group.getThumbnail( )
         bi = core.Storage.getBroadcastingInfo bi.apiName, bi.id
         icon.style.backgroundImage = "url(#{bi.getImageUrl()})"
         icon.style.display = "block"
      else
         icon.style.display = "none"

      # 視聴ページが設定されている場合マウスホバー時に表示されるリンクを設定する
      a = tpl.querySelector "a"
      if options.group.getBehavior( ) is core.Group.Behavior.Optional
         a.setAttribute "href", options.group.getOptionalLink( )
         a.innerText = i18n "jump"
         a.className = "enable"
      else
         a.className = ""

      $( @el ).append tpl.cloneNode( true )
      @el.className = "offline" if @_count is 0

      @delegateEvents( )

   remove: ( ) ->
      @undelegateEvents( )
      super( )

   getGroupId: ( ) -> @_gid

   isLive: ( ) -> @_count > 0

@ui.view = { } unless @ui.view?
@ui.view.GroupListItem = GroupListItem


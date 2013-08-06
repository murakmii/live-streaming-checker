"use strict"

i18n = chrome.i18n.getMessage

# グループの保持している配信情報等の詳細を表示するビュー
class GroupViewer extends Backbone.View

   @FADE_ANIMATE_TIME: 150

   el    : "#group-viewer"
   events:
      "click #viewer-header button": "_onClickedClose" 
      "click #viewer-footer .red-button": "_onClickedRemove"
      "click #viewer-footer .gray-button": "_onClickedEdit"

   _onClickedClose: ( ) -> @trigger "close", @
   _onClickedRemove: ( ) -> @trigger "remove", @_gid
   _onClickedEdit: ( ) -> @trigger "edit", @_gid

   initialize: ( ) ->

      @_shown  = false
      @_shadow = document.getElementById "group-viewer-shadow"
      @_body   = document.getElementById "viewer-body"
      @_broadcastings = [ ]

      # UIのローカライズ
      for b in document.viewer_footer.getElementsByTagName "button"
         b.innerText = i18n b.getAttribute( "name" )

   # 表示するグループを表示する
   view: ( groupId ) ->
      @_gid = groupId
      group = core.Storage.getGroup @_gid
      count = core.Storage.countLive @_gid

      # グループがライブ中の場合はスタイルに反映する
      document.viewer_header.className = if count > 0 then "live" else ""

      # グループアイコンの表示
      i = document.viewer_header.getElementsByTagName( "i" )[ 0 ] 
      if group.configuredThumbnail( )
         bi = group.getThumbnail( )
         bi = core.Storage.getBroadcastingInfo bi.apiName, bi.id
         i.style.backgroundImage = "url(#{bi.getImageUrl( )})"
         i.style.display = "block"
      else
         i.style.display = "none"

      # グループ名の設定
      document.viewer_header.querySelector( "span.title" ).innerText = group.getName( )

      # グループの保持している配信情報を一旦クリアし再設定
      @_body.innerHTML = ""
      b.remove( ) for b in @_broadcastings

      frg = document.createDocumentFragment( )
      group.eachBroadcastingInfo ( apiName, id ) =>
         bi = core.Storage.getBroadcastingInfo apiName, id
         e = new ui.view.GroupViewerItem broadcasting: bi
         frg.appendChild e.el
         @_broadcastings.push e

      @_body.appendChild frg

   getShownGroupId: ( ) -> @_gid

   isShown: ( ) -> @_shown

   show: ( ) ->
      @_shown = true
      $( @_shadow ).fadeIn GroupViewer.FADE_ANIMATE_TIME
      $( @el ).fadeIn GroupViewer.FADE_ANIMATE_TIME

   hide: ( fn ) ->
      @_shown = false
      $( @_shadow ).fadeOut GroupViewer.FADE_ANIMATE_TIME
      $( @el ).fadeOut GroupViewer.FADE_ANIMATE_TIME, fn

@ui.view = { } unless @ui.view?
@ui.view.GroupViewer = GroupViewer


"use strict"

i18n = chrome.i18n.getMessage

class GroupEditor extends Backbone.View

   @FADE_ANIMATE_TIME: 150

   el    : "#group"
   events:
      "click #group-footer button:last-child": "_onClickedSave" 

      "click #group-header button"              : "_onClickedCancel"
      "click #group-footer button:first-child"  : "_onClickedCancel"

      "input #main-config-footer input"   : "_onChangedSearchBox"
      "change #main-config-footer input"  : "_onChangedSearchBox"

      "input #main-config-header input"   : "_onChangedGroupName"
      "change #main-config-header input"  : "_onChangedGroupName"
      "submit #main-config-header"        : "_onSubmitedGroupName"

      "click #main-config-footer button"  : "_onClickedSearch"
      "submit #main-config-footer"        : "_onSubmitedSearch"

      "click #group-tab li"               : "_onClickedTab"

      "change #group-config-link input[type=checkbox]": "_onChangedLinkConfig"
      "submit #link-config"                           : "_onSubmitedLinkConfig"

   # "保存"がクリックされた際のイベント
   # 編集したグループと、グループが保持している配信情報を引数としてsaveイベントを発行する
   _onClickedSave: ( ) ->
      @_target.setName document.main_config_header.name.value

      if document.link_config.enable.checked
         @_target.setBehavior core.Group.Behavior.Optional
         @_target.setOptionalLink document.link_config.url.value
      else
         @_target.setBehavior core.Group.Behavior.List

      @trigger "save", @_target.clone( ), ( i.getBroadcastingInfo( ) for i in @_items )

   _onClickedCancel: ( ) -> @trigger "cancel"

   # タブがクリックされた際のイベント
   _onClickedTab: ( e ) -> @_select e.target.dataset.tab

   # グループ名が編集された際のイベント
   _onChangedGroupName: ( e ) ->
      if e.target.value.length is 0
         document.group_footer.commit.setAttribute "disabled", "disabled"
      else
         document.group_footer.commit.removeAttribute "disabled"

      return true

   _onSubmitedGroupName: ( e ) -> e.preventDefault( )

   # 検索フォームへの入力状態をチェックし、"検索"ボタンの有効無効を切り替える
   _onChangedSearchBox: ( e ) ->
      if not $( e.target ).hasClass( "used-default-text" ) and e.target.value.length isnt 0
         document.main_config_footer.search.removeAttribute "disabled"
      else
         document.main_config_footer.search.setAttribute "disabled", "disabled"

      return true

   _onSubmitedSearch: ( e ) ->
      e.preventDefault( )
      @_onClickedSearch( ) if document.main_config_footer.id.value.length > 0

   # 検索の実行
   _onClickedSearch: ( ) ->
      document.main_config_footer.search.blur( )

      div = document.main_config_footer.getElementsByTagName "div"
      form =  div[ 0 ]
      loading = div[ 1 ]
      loading.style.paddingTop = loading.style.paddingBottom = ( $( form ).outerHeight( ) / 2 - 8 ) + "px"

      $( form ).fadeOut 200, ( ) =>
         $( loading ).fadeIn 200, ( ) =>

            api = core.Util.toCamelCase document.main_config_footer.api.value
            core.api[ "#{api}Api" ].search document.main_config_footer.id.value, ( success, result ) =>

               if success
                  document.main_config_footer.id.value = ""
                  $( document.main_config_footer.id ).trigger "blur"

               $( loading ).fadeOut 200, ( ) =>
                  $( form ).fadeIn 200, ( ) =>

                     if success
                        @_addBroadcastingInfo result, true
                     else
                        ui.view.ModalDialog.show result, ui.view.ModalDialog.MODE_OK

   # 動作の設定が切り替えられた際のイベント
   _onChangedLinkConfig: ( e ) ->
      if e.target.checked
         document.link_config.url.removeAttribute "disabled" 
      else
         document.link_config.url.setAttribute "disabled", "disabled"

   _onSubmitedLinkConfig: ( e ) -> e.preventDefault( )

   # 配信情報のビューの"削除"がクリックされた際のイベント
   _onClickedItemRemove: ( item ) ->

      # 内部の配列から削除
      bi = item.getBroadcastingInfo( )
      for i, index in @_items
         if i.getBroadcastingInfo( ).isEqual bi
            @_items.splice index, 1
            break

      # グループから削除
      console.log @_target
      console.log bi
      if @_target.remove bi.getApiName( ), bi.getId( )

         # サムネイル設定が解除された場合は他にサムネイルとして使用できる配信情報がないかどうか調べる
         found = false
         for i in @_items
            if ( found = ( bi = i.getBroadcastingInfo( ) ).hasImageUrl( ) )
               i.iconClickable false
               @_target.setThumbnail bi.getApiName( ), bi.getId( ) 
               @_showIcon bi.getImageUrl( )
               break

         @_hideIcon true unless found

      # ビューから削除
      @stopListening item
      item.remove( )

   # 配信情報のビューのアイコンがクリックされた際のイベント
   _onClickedItemIcon: ( item ) ->
      i.iconClickable true for i in @_items 
      item.iconClickable false

      bi = item.getBroadcastingInfo( )
      @_showIcon bi.getImageUrl( ), true

      @_target.setThumbnail bi.getApiName( ), bi.getId( )

   # アイコンを表示する
   _showIcon: ( url, animate ) ->
      @_icon.style.backgroundImage = "url(#{url})"
      @_icon.style.display = "block"

      if animate is true
         $( @_icon ).animate { width: "40px" }, 100
      else
         console.log "show"
         @_icon.style.width = "40px"

   # アイコンを非表示
   _hideIcon: ( animate ) ->
      if animate is true
         $( @_icon ).animate { width: "0px" }, 100, "swing", ( ) ->
            @style.display = "none"
      else
         @_icon.style.width = "0px"
         @_icon.style.display = "none"

   # タブを選択
   _select: ( tabName ) ->
      for e in @_tab
         if e.dataset.tab is tabName
            e.className = "selected"
            @_page[ e.dataset.tab ].style.display = "block"
         else
            e.className = ""
            @_page[ e.dataset.tab ].style.display = "none"

   # 追加された配信情報をビューへ反映
   _addBroadcastingInfo: ( broadcastingInfo, addToGroup ) ->
      item = new ui.view.GroupItem broadcasting: broadcastingInfo

      @listenTo item, "remove", @_onClickedItemRemove
      @listenTo item, "icon", @_onClickedItemIcon

      @_body.appendChild item.el
      @_items.push item

      if addToGroup is true
         if @_target.append broadcastingInfo
            @_showIcon broadcastingInfo.getImageUrl( ), true
            item.iconClickable false

      return item

   initialize: ( ) ->

      ( new Image ).src = "/image/cancel_hover.png"

      @_target = null
      @_shadow = document.getElementById "group-shadow"
      @_tab    = document.getElementById( "group-tab" ).getElementsByTagName "li"
      @_icon   = document.main_config_header.getElementsByTagName( "i" )[ 0 ]
      @_body   = document.getElementById "main-config-items"
      @_items  = [ ]
      @_page   =
         main: document.getElementById "group-config-main"
         link: document.getElementById "group-config-link"

      @_select "main"

      # 配信情報検索フォームのAPI一覧を初期化
      for api in core.Supported
         $( document.main_config_footer.api ).append "<option value=\"#{api}\">#{i18n api}</option>"

      default_text = i18n "#{document.main_config_footer.api.value}_search_box"
      ui.Util.setDefaultText document.main_config_footer.id, default_text

      # UIのローカライズ
      t.innerText = i18n "#{t.dataset.tab}_tab" for t in @_tab
      document.main_config_header.getElementsByTagName( "b" )[ 0 ].innerText = i18n "group_name"
      document.main_config_footer.search.innerText = i18n "search"
      document.group_footer.cancel.innerText = i18n "cancel"

      for e in @el.getElementsByClassName "localized"
         e.innerHTML = i18n e.dataset.localizeKey

   # 編集対象のグループを設定
   edit: ( @_target ) ->
      h1 = document.group_header.getElementsByTagName( "h1" )[ 0 ]
      if @_target?
         h1.innerText = i18n "edit_group"
         document.group_footer.commit.innerText = i18n "change"
         document.group_footer.commit.className = "blue-button"
      else
         h1.innerText = i18n "create_group"
         document.group_footer.commit.innerText = i18n "save"
         document.group_footer.commit.className = "red-button"
         @_target = new core.Group

      @_select "main"

      # グループ名をUIに設定
      document.main_config_header.name.value = @_target.getName( )
      $( document.main_config_header.name ).trigger "input"

      # 動作をUIに設定
      if @_target.getBehavior( ) is core.Group.Behavior.List
         document.link_config.enable.checked = false
         document.link_config.url.value = ""
         document.link_config.url.setAttribute "disabled", "disabled"
      else
         document.link_config.enable.checked = true
         document.link_config.url.value = @_target.getOptionalLink( )
         document.link_config.url.removeAttribute "disabled"

      # グループの保持している配信情報をビューに反映
      @clearView( )
      @_target.eachBroadcastingInfo ( apiName, id, isThumb ) =>
         item = @_addBroadcastingInfo ( bi = core.Storage.getBroadcastingInfo apiName, id )
         if isThumb
            @_showIcon bi.getImageUrl( )
            item.iconClickable false

   clearView: ( ) ->
      @_hideIcon( )
      for i in @_items
         @stopListening i
         i.remove( )
      
      @_items = [ ]

      document.main_config_footer.api.getElementsByTagName( "option" )[ 0 ].setAttribute "selected", "selected"
      document.main_config_footer.id.value = ""
      $( document.main_config_footer.id ).trigger "blur"

   show: ( ) ->
      $( @_shadow ).fadeIn GroupEditor.FADE_ANIMATE_TIME
      $( @el ).fadeIn GroupEditor.FADE_ANIMATE_TIME

   hide: ( fn ) ->
      $( @_shadow ).fadeOut GroupEditor.FADE_ANIMATE_TIME
      $( @el ).fadeOut GroupEditor.FADE_ANIMATE_TIME, fn

@ui.view ?= { }
@ui.view.GroupEditor = GroupEditor

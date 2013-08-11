"use strict"

i18n = chrome.i18n.getMessage

TOP_MENU_ID    = "top_menu"
CREATE_MENU_ID = "create_menu"
SEPARATOR_ID   = "separator"

_enabled = false

# 設定が変更されたメッセージを受け取った際にコンテキストメニューを更新する
chrome.runtime.onMessage.addListener ( msg, sender ) ->
   if sender.id is chrome.runtime.id
      switch msg.type

         # オプションページでコンテキストメニューの有効無効が切り替えられた際にそれを反映する
         when core.ConfiguredMessage
            if core.Storage.getConfig "enable_menu"
               ContextMenu.enable( )
            else
               ContextMenu.disable( )
         
         # グループが追加された際にそれをコンテキストメニューに反映する
         when core.SavedMessage
            if _enabled
               if msg.updated
                  # 更新の場合はタイトルをアップデート
                  chrome.contextMenus.update msg.groupId, title: i18n( "menu_add_group", [ core.Storage.getGroup( msg.groupId ).getName( ) ] )
               else
                  # 追加の場合はメニューを作成
                  if core.Storage.countGroup( ) is 1
                     chrome.contextMenus.create
                        id       : SEPARATOR_ID
                        type     : "separator"
                        parentId : TOP_MENU_ID

                  chrome.contextMenus.create
                     id       : msg.groupId
                     type     : "normal"
                     title    : i18n "menu_add_group", [ core.Storage.getGroup( msg.groupId ).getName( ) ]
                     parentId : TOP_MENU_ID

         # グループが削除された際にそれをコンテキストメニューに反映する
         when core.RemovedMessage
            if _enabled
               chrome.contextMenus.remove SEPARATOR_ID if core.Storage.countGroup( ) is 0
               chrome.contextMenus.remove msg.groupId

# コンテキストメニューのあるアイテムがクリックされた際のイベントハンドラ
chrome.contextMenus.onClicked.addListener ( data ) ->

   id       = null
   api_name = null

   # URLに各APIにおけるIDが含まれているかを調べる
   for api in core.Supported
      if ( id = core.api[ "#{api_name = core.Util.toCamelCase api}Api" ].extractIdFromUrl data.pageUrl )?
         break

   if id?
      console.log "OK: #{id}"
      # IDが含まれていた場合は配信情報について詳しい情報を取得
      core.api[ "#{api_name}Api" ].search id, ( success, result ) ->
         if success
            group = if data.menuItemId is CREATE_MENU_ID then new core.Group else core.Storage.getGroup data.menuItemId
            ContextMenu._addToGroup result, group, ( success ) ->
               if success
                  core.Notifier.notifySimple i18n( "menu_saved_group" ), i18n( "menu_saved_group_message", [ group.getName( ) ] )
               else
                  core.Notifier.notifySimple i18n( "sorry" ), i18n( "menu_failed_save_group" )
         else
            core.Notifier.notifySimple i18n( "sorry" ), result

class ContextMenu

   # 指定されたグループに配信情報を追加する
   @_addToGroup: ( broadcastingInfo, group, fn ) ->
      info_array = [ ]
      group.eachBroadcastingInfo ( apiName, id ) ->
         info_array.push core.Storage.getBroadcastingInfo apiName, id

      if group.emptyName( ) then group.setName broadcastingInfo.getName( )

      group.append broadcastingInfo
      info_array.push broadcastingInfo

      core.Storage.saveGroup group, info_array, fn

   # コンテキストメニューを有効にする
   @enable: ( ) ->
      return if _enabled

      # 親となるメニューを作成
      top_menu =
         id       : TOP_MENU_ID
         type     : "normal"
         title    : i18n "menu_top"
         contexts : [ "page", "link" ]

      # コンテキストメニューを表示するページを視聴ページに絞る
      urls = [ ]
      for api in core.Supported
         urls = urls.concat core.api[ "#{core.Util.toCamelCase api}Api" ].getStreamingPagePattern( )
      top_menu.documentUrlPatterns = urls

      chrome.contextMenus.create top_menu, ( ) ->
         _enabled = true
         
         # 親の作成が完了したら"新規グループとして作成"メニューと各グループへ追加するためのメニューを作成していく
         menus = [ ( id: CREATE_MENU_ID, type: "normal", title: i18n "menu_create_group" ) ]
         core.Storage.eachGroup ( group ) ->
            menus.push id: SEPARATOR_ID, type: "separator" if menus.length is 1
            menus.push
               id       : group.getId( )
               type     : "normal"
               title    : i18n "menu_add_group", [ group.getName( ) ]

         for m in menus
            m.parentId = TOP_MENU_ID
            chrome.contextMenus.create m

   @disable: ( ) ->
      return unless _enabled
      chrome.contextMenus.remove TOP_MENU_ID, ( ) -> _enabled = false

@core.ContextMenu = ContextMenu


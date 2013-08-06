"use strict"

i18n = chrome.i18n.getMessage
@core = chrome.extension.getBackgroundPage( ).core

$ =>
   # UI構築
   instance = 
      header   : new ui.view.Header
      editor   : new ui.view.GroupEditor
      viewer   : new ui.view.GroupViewer
      lives    : new ui.view.GroupList type: ui.view.GroupList.Type.Live
      offlines : new ui.view.GroupList type: ui.view.GroupList.Type.Offline

   # メッセージ受信時のイベントハンドラを設定する
   # 受信時にグループの表示更新を行う
   onMessage = ( msg, sender ) ->
      displayGroup.call instance if sender.id is chrome.runtime.id 
      if msg.type is core.UpdatedMessage and instance.viewer.isShown( )
         instance.viewer.view instance.viewer.getShownGroupId( )

   # イベントハンドラの設定と、ポップアップが閉じられた際にその設定が解除されるようにする
   chrome.runtime.onMessage.addListener onMessage
   $( window ).unload ( ) -> chrome.runtime.onMessage.removeListener onMessage

   # モーダルダイアログを初期化
   ui.view.ModalDialog.init( )

   # ヘッダーのイベントハンドラ設定
   instance.header.bind "editgroup", onClickedHeaderEdit, instance

   # グループエディタのイベントハンドラ設定
   instance.editor.bind "cancel", ( ) -> instance.editor.hide( )
   instance.editor.bind "save", onClickedEditorSave, instance

   content = document.getElementById "content"

   # ライブ中のグループリストのイベントハンドラの設定
   content.appendChild instance.lives.el
   instance.lives.bind "click", onClickedGroupListItem, instance
   instance.lives.bind "toggle", onToggledGroupList, instance
   instance.lives.open false if core.UIValue.get "live_opened"

   # オフラインのグループリストのイベントハンドラの設定
   content.appendChild instance.offlines.el
   instance.offlines.bind "click", onClickedGroupListItem, instance
   instance.offlines.bind "toggle", onToggledGroupList, instance
   instance.offlines.open false if core.UIValue.get "offline_opened"

   # グループの詳細ビューのイベントハンドラの設定
   instance.viewer.bind "close", ( ) -> instance.viewer.hide( )
   instance.viewer.bind "remove", onClickedViewerRemove, instance
   instance.viewer.bind "edit", onClickedViewerEdit, instance

   # ローディング画面とエラー画面のテキストのローカライズ
   document.getElementById( "loading-text" ).innerHTML = i18n "loading_text"
   document.getElementById( "error-text" ).innerHTML = i18n "error_text"

   # エラー時の再読み込みボタンを有効化
   reload = document.getElementById "reload"
   reload.innerText = i18n "reload"
   $( reload ).click ( ) -> chrome.runtime.reload( )

   # バックグランドでのデータを初期化状況を確認する
   if core.loadCompleted
      initScreen instance # 既に初期化が完了している場合はポップアップ画面の初期化
   else
      # 初期化が完了していない場合、ローディング画面を表示し定期的に初期化状況をチェックする
      loading = document.getElementById "loading"
      loading.style.display = "-webkit-box"

      timer = setInterval ( ) ->
         # 初期化が完了した時点でポップアップ画面の初期化を行う
         if core.loadCompleted
            clearInterval timer
            $( loading ).fadeOut 200, ( ) -> initScreen instance, true
      , 100

# バックグランドの初期化完了後に呼び出される関数
# 初期化の結果を取得し、通常のポップアップ画面若しくはエラー通知画面を表示する
initScreen = ( uiInstance, animate ) ->
   e = document.getElementById ( if core.loadSucceeded then "main" else "error" )
   if core.loadSucceeded
      e = document.getElementById "main"
      displayGroup.call uiInstance
   else
      e = document.getElementById "error"

   $( e ).fadeIn 200 if animate
   e.style.display = e.dataset.display

# グループのステータスをポップアップに反映する
displayGroup = ( ) ->
   @lives.clearAll( )
   @offlines.clearAll( )

   live_items    = [ ]
   offline_items = [ ]

   core.Storage.eachGroup ( group ) ->
      item = new ui.view.GroupListItem group: group
      if item.isLive( )
         live_items.push item
      else
         offline_items.push item

   @lives.setItems live_items
   @offlines.setItems offline_items

# ヘッダーの"追加"がクリックされた際のイベントハンドラ
onClickedHeaderEdit = ( ) ->
   @editor.edit( )
   @editor.show( )

# グループのリストのヘッダーがクリックされリストの開閉が行われた際のイベントハンドラ
onToggledGroupList = ( list ) ->
   if list.getType( ) is ui.view.GroupList.Type.Live
      core.UIValue.set "live_opened", list.isOpened( )
   else
      core.UIValue.set "offline_opened", list.isOpened( )

# グループのリストのアイテムがクリックされた際のイベントハンドラ
onClickedGroupListItem = ( groupId ) ->
   @viewer.view groupId
   @viewer.show( )

# グループの詳細の"削除"がクリックされた際のイベントハンドラ
onClickedViewerRemove = ( groupId ) ->
   # ダイアログで確認後、同意を得られれば削除を実行
   ui.view.ModalDialog.show i18n( "confirm" ), ui.view.ModalDialog.MODE_YESNO, ( result ) =>
      if result is ui.view.ModalDialog.RESULT_YES
         @viewer.hide ( ) ->
            core.Storage.removeGroup groupId, ( success ) ->
               unless success
                  ui.view.ModalDialog.show i18n( "remove_error" ), ui.view.ModalDialog.MODE_OK

# グループの詳細の"編集"がクリックされた際のイベントハンドラ 
onClickedViewerEdit = ( groupId ) ->
   @viewer.hide ( ) =>
      @editor.edit core.Storage.getGroup( groupId )
      @editor.show( )

# グループエディタの"保存"がクリックされた際のイベント
onClickedEditorSave = ( group, broadcastings ) ->
   @editor.hide ( ) ->
      core.Storage.saveGroup group, broadcastings, ( success ) ->
         unless success
            ui.view.ModalDialog.show i18n( "save_error" ), ui.view.ModalDialog.MODE_OK

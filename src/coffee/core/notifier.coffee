"use strict"

i18n = chrome.i18n.getMessage

SIMPLE_NOTIFICATION_ID  = "simple_notify"
NOTIFY_DEFAULT_ICON     = "/image/notify.png"

# 表示中の通知を管理
_shown = { }

# 通知が閉じられた際に保持しているボタン情報を削除
chrome.notifications.onClosed.addListener ( nid ) ->
   if _shown[ nid ]? then delete _shown[ nid ]

# ボタンがクリックされた際に保持しているボタン情報からページを開く
chrome.notifications.onButtonClicked.addListener ( nid, index ) ->
   if _shown[ nid ]?
      chrome.tabs.create url: _shown[ nid ][ index ]

# デスクトップへの通知を行う
class Notifier

   # 複数のグループから通知対象としてふさわしいグループを選択するメソッド
   @_selectNotifiedGroup: ( groups ) ->
      notified = null
      for g in groups
         if g.configuredThumbnail( )
            notified = g
            break

      return if notified? then notified else groups[ 0 ]

   # 引数として与えられたグループを通知対象とする場合に、適切なアイコンのURLを返す
   @_selectBestIcon: ( notifiedGroup ) ->
      icon_url = null
      if notifiedGroup.configuredThumbnail( )
         thumb    = notifiedGroup.getThumbnail( )
         bi       = core.Storage.getBroadcastingInfo thumb.apiName, thumb.id
         icon_url = bi.getImageUrl( ) if bi.hasImageUrl( )

      return if icon_url? then icon_url else NOTIFY_DEFAULT_ICON

   # ライブ中のグループを通知する際のメッセージを作成する
   @_createMessage: ( groups ) ->
      if groups.length > 1
         message = i18n "other_live_groups", [ groups.length - 1 ]
      else
         message = i18n "live_in", [ core.Storage.countLive groups[ 0 ].getId( ) ]

      return message

   # HTML5標準の通知機能を用いる
   # 特に下位互換を求めない場合、_richを使用すること
   @_legacy: ( groups ) ->
      notified = Notifier._selectNotifiedGroup groups
      if window.webkitNotifications?
         notify = webkitNotifications.createNotification(
            Notifier._selectBestIcon( notified ),
            i18n( "live_now", [ notified.getName( ) ] ),
            Notifier._createMessage( groups ),
         )

         notify.show( )

   # WindowsとChrome OSでのみ実装されている多機能な通知機能を用いる
   @_rich: ( groups ) ->
      notified = Notifier._selectNotifiedGroup groups

      # 通知に表示するボタン設定
      buttons  = [ ]
      links    = [ ]

      # 任意のWebページが設定されている場合はそのページへのリンクを表示
      if notified.getBehavior( ) is core.Group.Behavior.Optional
         links.push notified.getOptionalLink( )
         buttons.push
            iconUrl  : "/image/view_optional.png"
            title    : i18n "view_on_optional"

      # ライブ中のページへのリンクとなるボタンを列挙
      notified.eachBroadcastingInfo ( apiName, id ) ->
         bi = core.Storage.getBroadcastingInfo apiName, id
         if bi.isLive( )
            links.push bi.getUrl( )
            buttons.push
               iconUrl  : "/image/view_service.png"
               title    : i18n "view_on_service", [ i18n( bi.getApiName( ) ), bi.getName( ) ]

      nid = "notify_#{core.Util.createTimestamp( )}"
      chrome.notifications.create nid,
         type     : "basic"
         title    : i18n "live_now", [ notified.getName( ) ]
         iconUrl  : Notifier._selectBestIcon( notified )
         message  : Notifier._createMessage( groups )
         buttons  : buttons
      , ( ) ->
         _shown[ nid ] = links # 通知に表示されているボタンに対応したリンクを保持しておく

   # 新たにライブ中となったグループIDを配列で受け取り、それを通知する
   @notifyLive: ( gidArray ) ->
      groups   = ( core.Storage.getGroup gid for gid in gidArray )
      os_name  = core.Util.getOSName( )

      # Chrome 28以上、それ以下の場合はChrome OSかWindowsである場合にChrome APIの通知、
      # そうでない場合はHTML標準の通知を用いる
      if core.Storage.getConfig "do_notify"
         if core.Util.getBrowserVersion( ) >= 28 or ( os_name is "cros" or os_name is "win" )
            Notifier._rich groups
         else
            Notifier._legacy groups

   # 拡張のバッジでライブ中のグループ数を通知する
   @notifyBadge: ( ) ->
      count = core.Storage.getLiveGroupId( ).length
      if count > 0
         chrome.browserAction.setBadgeText text: "#{count}"
      else
         chrome.browserAction.setBadgeText text: ""

   @notifySimple: ( title, message ) ->
      os_name = core.Util.getOSName( )

      # notifyLiveメソッドと同様の使用API切り分け
      if core.Util.getBrowserVersion( ) >= 28 or ( os_name is "cros" or os_name is "win" )
         chrome.notifications.create SIMPLE_NOTIFICATION_ID,
            type     : "basic"
            title    : title
            iconUrl  : NOTIFY_DEFAULT_ICON
            message  : message
         , ( ) ->
      else
         webkitNotifications.createNotification(
            NOTIFY_DEFAULT_ICON,
            title,
            message
         ).show( )

@core.Notifier = Notifier

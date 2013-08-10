"use strict"

CHECK_INTERVAL = 60 * 1000 # アップデートのチェックを行う間隔

_status  = { }
_updated = [ ]

class Updater

   # アップデートが必要な配信情報のAPI名とIDを配列にして取得
   @_getUpdateNeeded: ( now ) ->
      needed = [ ]
      for apiName, set of _status
         for id, stat of set
            if now - stat.lastUpdated >= core.UpdateInterval and not stat.updating
               needed.push apiName: apiName, id: id

      return needed

   # 更新ステータスを初期化する
   @_initStatus: ( ) ->
      inited = { }
      core.Storage.eachGroup ( group ) ->
         group.eachBroadcastingInfo ( apiName, id ) ->
            inited[ apiName ] = { } unless inited[ apiName ]?

            if _status[ apiName ]? and _status[ apiName ][ id ]?
               # 更新ステータスが存在する場合は引き継ぐ
               inited[ apiName ][ id ] = _status[ apiName ][ id ]
            else
               # 存在しない場合はデフォルトの値をセット
               inited[ apiName ][ id ] =
                  lastUpdated : 0
                  updating    : false

      _status = inited

   # アップデータの初期化
   @init: ( ) ->
      Updater._initStatus( )

      # アラームを設定して定期的にアップデートされるようにする
      chrome.alarms.onAlarm.addListener ( alm ) -> Updater.exec( ) if alm.name is "updater"
      chrome.alarms.create "updater",
         periodInMinutes   : CHECK_INTERVAL / ( 60 * 1000 )

      chrome.alarms.create "test", periodInMinutes: 1
      chrome.alarms.onAlarm.addListener ( alm ) -> console.log "1 minutes" if alm.name is "test"

      # グループが変更された際に更新ステータスを初期化する
      chrome.runtime.onMessage.addListener ( msg, sender ) ->
         if sender.id is chrome.runtime.id and  msg.type & core.IsChangedMessage
            Updater._initStatus( )

      # 初期化時にアップデートを実行
      Updater.exec( )

   # アップデート
   @exec: ( ) ->
      now = +new Date
      api_class_name = null
      console.log "update: " + ( new Date )

      # アップデートが必要な配信情報のみを処理
      for b in Updater._getUpdateNeeded now

         _status[ b.apiName ][ b.id ].updating = true

         # API名が切り替わった際に各API用クラスの開始・終了メソッドを呼び出す
         if core.Util.toCamelCase( b.apiName ) isnt api_class_name
            core.api[ "#{api_class_name}Api" ].endUpdate now if api_class_name?
            core.api[ "#{api_class_name = core.Util.toCamelCase b.apiName}Api" ].standbyUpdate now
            console.log "standby: #{api_class_name}Api"

         b = core.Storage.getBroadcastingInfo b.apiName, b.id
         core.api[ "#{api_class_name}Api" ].update now, b.getId( )
         console.log "updater request: #{b.getId()}"

      # 最後に終了メソッドを呼び出しておく
      core.api[ "#{api_class_name}Api" ].endUpdate now if api_class_name?

   # ある配信情報の更新が完了した際に呼び出す
   @updated: ( apiName, id, broadcasting ) ->
      _status[ apiName ][ id ].lastUpdated   = +new Date
      _status[ apiName ][ id ].updating      = false
      _updated.push broadcasting if broadcasting? # 更新された配信情報をバッファリングする

   # バッファリングされた配信情報を取り出す
   @fetchUpdated: ( ) ->
      updated = _updated
      _updated = [ ]
      return updated

@core.Updater = Updater

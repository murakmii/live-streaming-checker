"use strict"

i18n = chrome.i18n.getMessage

class Observer

   @init: ( ) ->
      # 定期的に更新をチェックするアラームを仕込む
      chrome.alarms.onAlarm.addListener ( alm ) -> Observer.exec( ) if alm.name is "observer"
      chrome.alarms.create "observer",
         delayInMinutes    : core.UpdateInterval / ( 60 * 1000 )
         periodInMinutes   : core.UpdateInterval / ( 60 * 1000 )

      # グループの追加・削除が行われた場合にバッジを更新する
      chrome.runtime.onMessage.addListener ( msg, sender ) ->
         if sender.id is chrome.runtime.id and msg.type & core.IsChangedMessage
            core.Notifier.notifyBadge( )

      # 初回実行を5秒後に仕込む
      setTimeout Observer.exec, 5000

   @exec: ( ) ->
      
      # 更新結果を反映する前のグループのライブ状況
      before_stat = core.Storage.getGroupLiveStatus( )

      # 更新結果を反映
      core.Storage.update core.Updater.fetchUpdated( )

      # 更新結果反映後のグループのライブ状況
      after_stat = core.Storage.getGroupLiveStatus( )

      # 更新前にはライブではなかったが、更新後にライブになったグループを調べる
      started = [ ]
      for gid, live of before_stat
         if not live and after_stat[ gid ] is true
            started.push gid

      # ライブになったグループがある場合はもろもろ更新・通知を行う
      if started.length > 0
         core.Notifier.notifyLive started
         core.Notifier.notifyBadge( )
         chrome.runtime.sendMessage type: core.UpdatedMessage

@core.Observer = Observer

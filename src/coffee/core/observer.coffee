"use strict"

i18n = chrome.i18n.getMessage

class Observer

   @init: ( ) ->
      # グループの追加・削除が行われた場合にバッジを更新する
      chrome.runtime.onMessage.addListener ( msg, sender ) ->
         if sender.id is chrome.runtime.id and msg.type & core.IsChangedMessage
            core.Notifier.notifyBadge( )

      # 更新チェックを5秒枚に仕込む
      setInterval Observer.exec, 5000

   @exec: ( ) ->
      
      # 更新結果を反映する前のグループのライブ状況
      before_stat = core.Storage.getGroupLiveStatus( )

      # 更新結果を反映
      core.Storage.update core.Updater.fetchUpdated( )

      # 更新結果反映後のグループのライブ状況
      after_stat = core.Storage.getGroupLiveStatus( )

      # 更新前にはライブではなかったが、更新後にライブになったグループを調べる
      started  = [ ]
      offlined = false
      for gid, live of before_stat
         if not live and after_stat[ gid ] is true
            started.push gid
         else if live is true and after_stat[ gid ] is false
            offlined = true

      # ライブになったグループがある場合はもろもろ更新・通知を行う
      if started.length > 0
         core.Notifier.notifyLive started
         core.Notifier.notifyBadge( )
         chrome.runtime.sendMessage type: core.UpdatedMessage
      else if offlined
         # ライブになったグループがなくてもオフラインになったグループがある場合はバッジを更新する
         core.Notifier.notifyBadge( )

@core.Observer = Observer

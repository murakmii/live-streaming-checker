"use strict"

i18n  = chrome.i18n.getMessage
@core = chrome.extension.getBackgroundPage( ).core

$ ->
   # タブの切り替え機能
   $( "#sidebar li" ).click ( e ) ->
      unless $( e ).hasClass "selected"
         $( "#sidebar li" ).removeClass "selected"
         $( "#body > div" ).removeClass "selected"
         $( e.target ).addClass "selected"
         $( "#tab-#{e.target.dataset.tab}" ).addClass "selected"

   # ローカライズを行う
   $( ".localized" ).each ( ) -> @innerHTML = i18n @dataset.localizeKey

   # 保存されている設定を反映する
   document.basic.do_notify.checked = core.Storage.getConfig "do_notify"
   document.basic.enable_menu.checked = core.Storage.getConfig "enable_menu"

   # 設定の変更を反映するためのイベントハンドラを設定
   chrome.runtime.onMessage.addListener ( msg, sender ) ->
      if msg.type is core.ConfiguredMessage and sender.id is chrome.runtime.id
         document.basic.do_notify.checked = core.Storage.getConfig "do_notify"
         document.basic.enable_menu.checked = core.Storage.getConfig "enable_menu"

   # 設定が切り替えられた際にそれを保存するイベントハンドラを設定する
   $( document.basic.do_notify ).change ( e ) -> core.Storage.setConfig "do_notify", e.target.checked
   $( document.basic.enable_menu ).change ( e ) -> core.Storage.setConfig "enable_menu", e.target.checked

"use strict"

i18n = chrome.i18n.getMessage

_shadow   = null
_modal    = null
_text     = null
_callback = null

# ボタンがクリックされた際にコールバックを呼び出しダイアログを非表示にする
_onClickedHandler = ( e ) ->
   _callback( e.target.dataset.result ) if _callback?
   ModalDialog.hide( )

# モーダルダイアログクラス
# 様々なコードから参照されるため、Backboneのビューを使わない
class ModalDialog

   @FADE_ANIMATE_TIME: 150

   @MODE_YESNO : "yesno"
   @MODE_OK    : "ok"

   @RESULT_YES : "yes"
   @RESULT_NO  : "no"
   @RESULT_OK  : "ok"

   # ダイアログを初期化する
   @init: ( ) ->
      _shadow   = document.getElementById "modal-shadow"
      _modal    = document.getElementById "modal"
      _text     = _modal.getElementsByTagName( "p" )[ 0 ]

      for e in _modal.getElementsByTagName "button"
         e.innerText = i18n "modal_dialog_button_#{e.dataset.result}"
         $( e ).click _onClickedHandler

   # 内容・表示するボタンとコールバックを設定しダイアログを表示する
   @show: ( content, mode, fn ) ->
      _text.innerHTML = content
      document.modal.className = mode
      _callback = if fn? then fn else null

      $( _shadow ).fadeIn ModalDialog.FADE_ANIMATE_TIME
      $( _modal ).fadeIn( ModalDialog.FADE_ANIMATE_TIME ).css "display", "-webkit-box"

   @hide: ( ) ->
      $( _shadow ).fadeOut ModalDialog.FADE_ANIMATE_TIME
      $( _modal ).fadeOut ModalDialog.FADE_ANIMATE_TIME

@ui.view ?= { }
@ui.view.ModalDialog = ModalDialog

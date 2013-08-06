"use strict"

# UI用の値の設定と保存
_ui_value =
   live_opened    : false
   offline_opened : false

# 保存されているUI用の値を読み込む. 読み込めなかった場合はデフォルトのまま
chrome.storage.local.get "uivalue", ( read ) -> 
   _ui_value = read.uivalue if not chrome.runtime.lastError? and read.uivalue

@core.UIValue = 
   get: ( key ) -> _ui_value[ key ]
   set: ( key, value ) -> 
      _ui_value[ key ] = value
      chrome.storage.local.set uivalue: _ui_value # UI用の値は保存に失敗しても別に気にしない(エラーをチェックしない)

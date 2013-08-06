"use strict"

# createTimestampが同時刻に呼び出された回数を記録しておく
_lastTimestamp = 0
_repeated      = 0

class Util

   # GETリクエストを投げる
   @getRequest: ( url, fn ) ->
      xhr = new XMLHttpRequest
      xhr.open "GET", url, true

      xhr.onreadystatechange = ( ) ->
         if xhr.readyState is 4
            fn( xhr.status is 200, xhr )

      xhr.send null

   # ハイフン区切りの文字列をキャメルケースへ変換
   @toCamelCase: ( str ) ->
      cc = ""
      for w in str.split "-"
         if w.length > 0
            cc += w.charAt( 0 ).toUpperCase( ) + w.substr 1
      return cc

   # タイムスタンプの作成
   @createTimestamp: ( ) ->
      ts = +new Date
      if ts is _lastTimestamp
         _repeated++
      else
         _repeated = 0
         _lastTimestamp = ts

      return "#{ts}-#{_repeated}"

   # OS名を取得
   @getOSName: ( ) ->
      about_os = window.navigator.appVersion.match( /\([^\)]+\)/ )[ 0 ].toLowerCase( )
      if about_os.indexOf( "windows" ) isnt -1
         os_name = "win"
      else if about_os.indexOf( "cros" ) isnt -1
         os_name = "cros"
      else if about_os.indexOf( "mac os x" ) isnt -1
         os_name = "mac"
      else
         os_name = "other"

      return os_name

@core ?= { }
@core.Util = Util

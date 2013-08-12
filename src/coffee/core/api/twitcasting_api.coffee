"use strict"

i18n = chrome.i18n.getMessage

API_NAME                = "twitcasting"
REQUEST_INTERVAL        = 60000
REQUEST_LIMITED_COUNT   = 60

_log        = [ ]
_waitTimer  = null
_reqQueue   = [ ]

class TwitcastingApi extends core.api.Api

   # リクエストが発生したログを記録する
   @_logRequest: ( now ) ->
      _log.push now
      if _log.length > REQUEST_LIMITED_COUNT then _log.shift( )

   # 現在リクエストを実行できるかどうかを調べる
   @_canRequest: ( now ) ->
      _log.length < REQUEST_LIMITED_COUNT || now - _log[ 0 ] > REQUEST_INTERVAL

   # 現在リクエストを行う場合の待ち時間を調べる
   # すぐにリクエスト出来る場合は0を返す
   @_getWaitTime: ( now ) ->
      if TwitcastingApi._canRequest( now )
         return 0
      else
         return REQUEST_INTERVAL - ( now - _log[ 0 ] )

   # リクエストを実行
   @_request: ( now, id, fn ) ->
      TwitcastingApi._logRequest( now )
      core.Util.getRequest "http://api.twitcasting.tv/api/livestatus?type=json&user=#{id}", ( success, xhr ) ->
         fn( success and JSON.parse( xhr.responseText ).islive ) if fn?

   @getStreamingPagePattern: ( ) -> [ "http://twitcasting.tv/*" ]

   @extractIdFromUrl: ( url ) ->
      if ( matched = url.match /^http:\/\/twitcasting\.tv\/([\w\-\.~%!$&'\(\)\*\+,;=]+)$/ )
         return matched[ 1 ]
      else
         return null

   @search: ( id, fn ) ->
      if not core.Util.isSegment id
         fn( false, i18n "ustream_not_found" )
      else
         core.Util.getRequest "http://api.twitcasting.tv/api/userstatus?type=json&user=#{id}", ( success, xhr ) ->
            if success
               json = JSON.parse xhr.responseText
               if json instanceof Array
                  fn( false, i18n "ustream_not_found" )
               else
                  info = new core.BroadcastingInfo
                  info.setId json.userid
                  info.setApiName API_NAME
                  info.setName json.name
                  info.setImageUrl json.image
                  info.setLive false
                  info.setUrl "http://twitcasting.tv/#{json.userid}"
                  
                  TwitcastingApi._request ( +new Date ), id, ( live ) ->
                     info.setLive live
                     fn( true, info )
            else
               fn( false, i18n "network_error" )

   @update: ( timestamp, id ) ->
      unless _waitTimer
         # リクエスト待ちがない場合
         now = +new Date
         if ( wait_time = TwitcastingApi._getWaitTime now ) is 0
            # 待つ必要がない場合は即座にリクエストを実行
            TwitcastingApi._request now, id, ( live ) ->
               if ( info = core.Storage.getBroadcastingInfo API_NAME, id )?
                  core.Updater.updated API_NAME, id, info.setLive( live )
         else
            # 待ち時間が発生する場合はタイマを仕込んでリクエスト
            _waitTimer = setTimeout ( ) ->
               TwitcastingApi._request now, id, ( live ) ->
                  if ( info = core.Storage.getBroadcastingInfo API_NAME, id )?
                     core.Updater.updated API_NAME, id, info.setLive( live )

                  clearTimeout _waitTimer
                  _waitTimer = null

                  # リクエストを待っている間に溜まったリクエストを実行する
                  if ( next = _reqQueue.shift( ) )? then TwitcastingApi.update timestamp, next
            , wait_time
      else
         # リクエスト待ちが発生している場合はキューに突っ込んでおく
         _reqQueue.push id

@core.api.TwitcastingApi = TwitcastingApi

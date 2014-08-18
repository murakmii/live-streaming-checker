"use strict"

i18n = chrome.i18n.getMessage
API_NAME = "cavetube"
API_HOST = "gae.cavelis.net"
RSS_URL  = "http://rss.cavelis.net/index_live.xml"

# Cavetube上での配信の有無はRSSから調べるため、1回のチェックで全ての配信の有無が分かる
# なので、通常のチェックとは別に定期的にRSSのチェックを走らせて、CabetubeApi#updateではその結果を反映するのみとする
_liveUsers     = { }
_retryCount    = 0
_nextInterval  = 12000

_updateRss = ( ) ->
   core.Util.getRequest RSS_URL, ( success, xhr ) ->

      # リトライ処理。失敗した場合は3回まで10秒おきの再接続を行う
      if success or _retryCount is 3
         _retryCount   = 0
         _nextInterval = 3 * 60 * 1000 # 成功するかリトライ数を超過したら次の更新は2分後
      else
         _retryCount++
         _nextInterval = 10 * 1000 # リトライ(10秒後)

      if success
         rss = ( new DOMParser ).parseFromString xhr.responseText, "application/xml"
         _liveUsers = { }
         for name in rss.getElementsByTagName "name"
            _liveUsers[ name.textContent ] = true # 正直値は何でもいいが、trueがわかりやすいので代入

      setTimeout _updateRss, _nextInterval # 次回の更新処理をセット

_updateRss( )

class CavetubeApi extends core.api.Api

   @_parseUserPage: ( id, html ) ->
      dom = ( new DOMParser ).parseFromString html, "text/html"
      if dom.getElementsByTagName( "parseerror" ).length > 0
         return null

      img_path = dom.getElementById( "profile_image" ).getAttribute "src"
      if img_path.indexOf( "http" ) is -1
         img_path = "http://#{API_HOST}/" + img_path
     
      bi = new core.BroadcastingInfo
      bi.setId id
      bi.setApiName API_NAME
      bi.setName id # 名前とIDは同じ
      bi.setUrl "http://gae.cavelis.net/live/#{id}"
      bi.setLive _liveUsers[ id ]?
      bi.setImageUrl img_path

      return bi

   @getStreamingPagePattern: ( ) -> [
         "http://#{API_HOST}/user/*"
         "http://#{API_HOST}/live/*"
      ]

   @extractIdFromUrl: ( url ) ->
      if ( matched = url.match /^http:\/\/gae\.cavelis\.net\/(user|live)\/(.+)$/ )
         return matched[ 2 ]
      else
         return null

   @search: ( id, fn ) ->
      core.Util.getRequest "http://#{API_HOST}/user/#{id}", ( success, xhr ) ->
         if success
            bi = CavetubeApi._parseUserPage id, xhr.responseText
            fn( bi?, if bi? then bi else i18n "ustream_not_found" )
         else
            fn( false, i18n( if xhr.status is 404 then "ustream_not_found" else "network_error" ) )

   @update: ( timestamp, id ) ->
      # 配信の有無の確認は_updateRssで行われているため、ここではその結果を反映するだけ
      if ( info = core.Storage.getBroadcastingInfo API_NAME, id )?
         core.Updater.updated API_NAME, id, info.setLive( _liveUsers[ id ]? )
      
@core.api.CavetubeApi = CavetubeApi


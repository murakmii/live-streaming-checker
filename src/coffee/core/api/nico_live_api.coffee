"use strict"

i18n = chrome.i18n.getMessage

API_NAME = "nico_live"

_reqQueue   = [ ]
_requesting = false
_lastTime   = 0
_interval   = 0

setInterval ( ) ->
   if ( ( +new Date ) - _lastTime ) > _interval and not _requesting and ( id = _reqQueue.shift( ) )?
      _requesting = true
      core.Util.getRequest "http://com.nicovideo.jp/community/co#{id}", ( success, xhr ) ->

         if success
            info = NicoLiveApi._pageToObject xhr.responseText
            info.setId( id ).setUrl "http://com.nicovideo.jp/community/co#{id}"
         else if ( info = core.Storage.getBroadcastingInfo API_NAME, id )?
            info.setLive false

         core.Updater.updated API_NAME, id, info if info?

         _requesting = false
         _lastTime   = +new Date
         _interval   = if xhr.status isnt 200 then 70000 else 3000
, 2900

class NicoLiveApi extends core.api.Api

   @_pageToObject: ( text ) ->
      bi = new core.BroadcastingInfo
      # bi.setId パース後設定
      bi.setApiName API_NAME
      bi.setName if ( match = text.match /<h1\s+id="community_name">(.+)<\/h1>/ )? then match[ 1 ].replace(/&#039;/, "'") else ""
      # bi.setUrl パース後設定
      bi.setLive text.indexOf( "id=\"now_live\"" ) isnt -1

      if ( match = text.match /<img\s+[^>]*class\s*=\s*"comm_img_L"[^>]*>/ )?
         bi.setImageUrl ( match[ 0 ].match /src="([^\"]+)\??[^"]*"/ )[ 1 ]

      return bi

   @getStreamingPagePattern: ( ) -> [ "http://com.nicovideo.jp/community/co*" ]

   @extractIdFromUrl: ( url ) ->
      if ( matched = url.match /^http:\/\/com\.nicovideo\.jp\/community\/co([\w\-\.~%!$&'\(\)\*\+,;=]+)$/ )
         return matched[ 1 ]
      else
         return null

   @search: ( id, fn ) ->
      unless core.Util.isSegment id
         fn( false, i18n "ustream_not_found" )
      else
         core.Util.getRequest "http://com.nicovideo.jp/community/co#{id}", ( success, xhr ) ->
            if success
               info = NicoLiveApi._pageToObject xhr.responseText
               info.setId( id ).setUrl "http://com.nicovideo.jp/community/co#{id}"
               fn( true, info )
            else
               fn( false, i18n if xhr.status is 404 then "ustream_not_found" else "network_error" )

   @update: ( timestamp, id ) -> _reqQueue.push id

@core.api.NicoLiveApi = NicoLiveApi

"use strict"

API_NAME = "ustream"
PARARELL_REQUEST_SIZE = 20 # 1リクエスト中でチェックするチャンネル数

i18n = chrome.i18n.getMessage
_requestId = [ ]

class UstreamApi extends core.api.Api

   # レスポンスからBroadcastinginfoを作成する
   @_resultToObject: ( result ) ->
      bi = new core.BroadcastingInfo
      bi.setId parseInt( result.id )
      bi.setApiName API_NAME
      bi.setName result.title
      bi.setUrl result.url
      bi.setLive result.status is "live"

      if result.imageUrl and result.imageUrl.small
         bi.setImageUrl result.imageUrl.small

      return bi

   @_updateEach: ( ids ) ->
      if ( id = ids.shift( ) )
         core.Util.getRequest "http://api.ustream.tv/json/channel/#{id}/getInfo", ( success, xhr ) ->
            if success
               json = JSON.parse xhr.responseText
               if json.error
                  core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )
               else
                  core.Updater.updated API_NAME, id, UstreamApi._resultToObject( json.results )
                  UstreamApi._updateEach ids
            else
               core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )

   @getStreamingPagePattern: ( ) -> [ "http://www.ustream.tv/channel/*" ]

   @extractIdFromUrl: ( url ) ->
      if ( matched = url.match /^http:\/\/www\.ustream\.tv\/channel\/([\w\-\.~%!$&'\(\)\*\+,;=]+)$/ )
         return matched[ 1 ]
      else
         return null

   @search: ( id, fn ) ->
      id = id.split( ";" )[ 0 ] # セミコロンは実質使用不可とする
      core.Util.getRequest "http://api.ustream.tv/json/channel/#{id}/getInfo", ( success, xhr ) ->
         if success
            json = JSON.parse xhr.responseText
            if json.error
               fn( false, i18n( if json.error is "ERR102" then "ustream_not_found" else "ustream_search_error" ) )
            else
               fn( true, UstreamApi._resultToObject json.results )
         else
            fn( false, i18n "network_error" )

   @standbyUpdate: ( timestamp ) -> _requestId = [ ]

   @update: ( timestamp, id ) ->
      _requestId.push id if id?
      if _requestId.length is PARARELL_REQUEST_SIZE or ( id is null and _requestId.length > 0 )

         ids = ( id for id in _requestId )
         _requestId = [ ]

         core.Util.getRequest "http://api.ustream.tv/json/channel/#{ids.join ";"}/getInfo", ( success, xhr ) ->
            if success
               json = JSON.parse xhr.responseText
               if json.error
                  if ids.length > 1
                     UstreamApi._updateEach ids
                  else
                     core.Updater.updated API_NAME, ids[ 0 ], core.Storage.getBroadcastingInfo( API_NAME, ids[ 0 ] ).setLive( false )
               else
                  if ids.length > 1
                     for e in json.results
                        obj = UstreamApi._resultToObject e.result
                        core.Updater.updated API_NAME, obj.getId( ), obj
                  else
                     core.Updater.updated API_NAME, ids[ 0 ], UstreamApi._resultToObject( json.results )
            else
               for id in ids
                  core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )
      
   @endUpdate: ( timestamp ) -> UstreamApi.update timestamp, null

@core.api.UstreamApi = UstreamApi

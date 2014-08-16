"use strict"

i18n = chrome.i18n.getMessage
API_NAME = "fc2_live"

_queue = new core.RequestQueue 10000

class Fc2LiveApi extends core.api.Api

   @_createApiUrl: ( id ) ->
      return "http://live.fc2.com/api/memberApi.php?streamid=#{id}&channel=1"

   @_resultToObject: ( result ) ->
      bi = new core.BroadcastingInfo
      bi.setId result.channelid
      bi.setApiName API_NAME
      bi.setName result.title
      bi.setUrl "http://live.fc2.com/#{result.channelid}"
      bi.setLive result.is_publish
      bi.setImageUrl result.image

      return bi

   @getStreamingPagePattern: ( ) -> [ "http://live.fc2.com/*" ]

   @extractIdFromUrl: ( url ) ->
      if ( matched = url.match /^https?:\/\/live\.fc2\.com\/([\w\d_\-]+)\/?$/ )
         return matched[ 1 ]
      else
         return null

   @search: ( id, fn ) ->
      if not core.Util.isSegment id
         fn( false, i18n "ustream_not_found" )
      else
         core.Util.getRequest Fc2LiveApi._createApiUrl( id ), ( success, xhr ) ->
            if success
               json = JSON.parse xhr.responseText
               if json.status is 1 and json.data?.channel_data?.channelid.length isnt 0
                  fn( true, Fc2LiveApi._resultToObject json.data.channel_data )
               else
                  fn( false, i18n "ustream_not_found" )
            else
               fn( false, i18n if xhr.status is 404 then "ustream_not_found" else "network_error" )

   @update: ( timestamp, id ) ->
      _queue.queuing Fc2LiveApi._createApiUrl( id ), ( success, xhr ) ->
         if success
            json = JSON.parse xhr.responseText
            if json.status is 1 and json.data?.channel_data?.channelid.length isnt 0
               core.Updater.updated API_NAME, id, Fc2LiveApi._resultToObject( json.data.channel_data )
            else
               success = false

         unless success
            if ( info = core.Storage.getBroadcastingInfo API_NAME, id )?
               core.Updater.updated API_NAME, id, info.setLive( false )

@core.api.Fc2LiveApi = Fc2LiveApi


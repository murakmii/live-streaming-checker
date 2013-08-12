"use strict"

i18n = chrome.i18n.getMessage
API_NAME = "twitch"
ERR_MSG =
   404: i18n "ustream_not_found"
   422: i18n "twitch_not_avaiable"

class TwitchApi extends core.api.Api

   @_resultToObject: ( result ) ->
      bi = new core.BroadcastingInfo
      bi.setId result.name
      bi.setApiName API_NAME
      bi.setName result.display_name
      bi.setUrl result.url
      bi.setLive false

      bi.setImageUrl result.logo if result.logo?

      return bi

   @getStreamingPagePattern: ( ) -> [ "http://www.twitch.tv/*" ]

   @extractIdFromUrl: ( url ) ->
      if ( matched = url.match /^http:\/\/www\.twitch\.tv\/([\w\-\.~%!$&'\(\)\*\+,;=]+)$/ )
         return matched[ 1 ]
      else
         return null

   @search: ( id, fn ) ->
      core.Util.getRequest "https://api.twitch.tv/kraken/channels/#{id}", ( success, xhr ) ->
         if success
            json = JSON.parse xhr.responseText
            if json.error
               fn( false, if ERR_MSG[ json.status ]? then ERR_MSG[ json.status ] else i18n "ustream_search_error" )
            else
               info = TwitchApi._resultToObject json

               # チャンネル情報の取得だけではライブ中かどうか判らないため、追加でライブ中かどうかを調べる
               core.Util.getRequest "https://api.twitch.tv/kraken/streams/#{id}", ( success, xhr ) ->
                  if success
                     json = JSON.parse xhr.responseText
                     if json.error
                        fn( false, i18n "ustream_search_error" )
                     else
                        fn( true, info.setLive json.stream? )
                  else
                     fn( false, i18n "network_error" )
         else
            fn( false, i18n "network_error" )

   @update: ( timestamp, id ) ->
      core.Util.getRequest "https://api.twitch.tv/kraken/streams/#{id}", ( success, xhr ) ->
         if core.Storage.existsBroadcastingInfo API_NAME, id
            if success
               json = JSON.parse xhr.responseText
               if json.error
                  core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )
               else
                  if json.stream?
                     core.Updater.updated API_NAME, id, TwitchApi._resultToObject( json.stream.channel ).setLive( true )
                  else
                     core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )
            else
               core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )

@core.api.TwitchApi = TwitchApi

"use strict"

i18n = chrome.i18n.getMessage
API_NAME = "stickam"

class StickamApi extends core.api.Api

   @_resultToObject: ( result ) ->
      bi = new core.BroadcastingInfo
      bi.setId result.name
      bi.setApiName API_NAME
      bi.setName result.screen_name
      bi.setUrl result.profile_url
      bi.setLive result.status is "live"
      bi.setImageUrl result.profile_image if result.profile_image?

      return bi

   @search: ( id, fn ) ->
      if not core.Util.isSegment id
         fn( false, i18n "ustream_not_found" )
      else
         core.Util.getRequest "http://api.stickam.jp/api/user/#{id}/profile?mime=json", ( success, xhr ) ->
            if success
               json = JSON.parse xhr.responseText
               if json.user_id
                  fn( true, StickamApi._resultToObject json )
               else
                  fn( false, i18n "ustream_not_found" )
            else
               fn( false, i18n if xhr.status is 404 then "ustream_not_found" else "network_error" )

   @update: ( timestamp, id ) ->
      StickamApi.search id, ( success, result ) ->
         if success
            core.Updater.updated API_NAME, id, result
         else
            core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )

@core.api.StickamApi = StickamApi

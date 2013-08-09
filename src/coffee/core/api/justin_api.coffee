"use strict"

i18n = chrome.i18n.getMessage

API_NAME = "justin"
PARARELL_REQUEST_SIZE = 20

_requestId = [ ]

class JustinApi extends core.api.Api

   @_channelObjectToObject: ( channelObject ) ->
      bi = new core.BroadcastingInfo
      bi.setId channelObject.login
      bi.setApiName API_NAME
      bi.setName channelObject.title
      bi.setUrl channelObject.channel_url
      bi.setLive false

      if channelObject.image_url_small?
         bi.setImageUrl channelObject.image_url_small

      return bi
   
   @search: ( id, fn ) ->
      if id.match /[\.\/\?#]/ then fn( false, i18n "justin_invalid_char" )

      # まずはチャンネル情報を取得
      core.Util.getRequest "http://api.justin.tv/api/channel/show/#{id}.json", ( success, xhr ) ->
         if success
            ch_json = JSON.parse xhr.responseText
            if ch_json.error
               if ch_json.error is "couldn't find channel"
                  fn( false, i18n "ustream_not_found" )
               else
                  fn( false, i18n "ustream_search_error" )
            else
               # Justinはチャンネル情報だけではライブかどうかわからないので再度ライブかどうかを確認する
               core.Util.getRequest "http://api.justin.tv/api/stream/list.json?channel=#{id}", ( success, xhr ) ->
                  if success
                     st_json = JSON.parse xhr.responseText
                     if st_json.length > 0
                        # 結果が得られた場合は得られたチャンネルオブジェクトから配信情報を作成しライブ中とする
                        bi = JustinApi._channelObjectToObject st_json[ 0 ].channel
                        bi.setLive true
                     else
                        # 得られなかった場合は既に取得していたチャンネルオブジェクトで配信情報を作成
                        bi = JustinApi._channelObjectToObject ch_json

                     fn( true, bi )
                  else
                     fn( false, i18n "network_error" )
         else
            fn( false, i18n if xhr.status is 404 then "ustream_not_found" else "network_error" )

   @standbyUpdate: ( timestamp ) -> _requestId = [ ]

   @update: ( timestamp, id ) ->
      _requestId.push id if id?
      if _requestId.length is PARARELL_REQUEST_SIZE or ( id is null and _requestId.length > 0 )

         ids = ( id for id in _requestId )
         _requestId = [ ]

         core.Util.getRequest "http://api.justin.tv/api/stream/list.json?channel=#{ids.join ','}", ( success, xhr ) ->
            if success
               json = JSON.parse xhr.responseText

               # レスポンスが得られた配信情報についてIDをキーにしてオブジェクトにしておく
               chobj = { }
               for stream in json
                  info = JustinApi._channelObjectToObject( stream.channel ).setLive true
                  chobj[ bi.getId( ) ] = info

               for id in ids
                  if chobj[ id ]?
                     # レスポンスが得られたIDについて、配信情報を更新しライブ中とする
                     core.Updater.updated API_NAME, id, chobj[ id ]
                  else
                     # レスポンスが得られなかったIDはオフラインなので既に保持しているチャンネル情報を取得しライブ中フラグを折る
                     core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )
                  
            else
               for id in ids
                  core.Updater.updated API_NAME, id, core.Storage.getBroadcastingInfo( API_NAME, id ).setLive( false )

   @endUpdate: ( timestamp ) -> JustinApi.update timestamp, null

@core.api.JustinApi = JustinApi

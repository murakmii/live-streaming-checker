"use strict"

i18n = chrome.i18n.getMessage
API_NAME   = "youtube"
API_PREFIX = "https://www.googleapis.com/youtube/v3"

YOUTUBE_UPDATE_INTERVAL = 10 * 60 * 1000

_queue = new core.RequestQueue 5000
_timestamps = { }

class YoutubeApi extends core.api.Api

   @_createChannelRequestUrl: ( channelId ) ->
      key = core.ConfigFile.get('youtube_api_key')
      return "#{API_PREFIX}/channels?key=#{key}&id=#{channelId}&part=id,snippet&fields=items(id,snippet(title,thumbnails(default)))"

   @_createVideoSearchingUrl: ( channelId ) ->
      key = core.ConfigFile.get('youtube_api_key')
      return "#{API_PREFIX}/search?key=#{key}&channelId=#{channelId}&part=id&eventType=live&type=video&fields=items(id(videoId))"

   @_createLiveCheckingUrl: ( videoSearchResponse ) ->
      key = core.ConfigFile.get('youtube_api_key')
      if videoSearchResponse.items?
         ids = ( item.id.videoId for item in videoSearchResponse.items )
         return "#{API_PREFIX}/videos?key=#{key}&part=liveStreamingDetails&id=#{ids.join ','}&fields=items(liveStreamingDetails)"
      else
         return null

   @_checkLiveVideo: ( videoSearchResponse, fn ) ->
      # 検索APIが返す動画中には何故かライブ中でない動画が混じっている場合があるので動画情報を取得し本当にライブ中かどうか確認する
      # 動画情報を取得するAPIで一括して動画情報を取得し, "liveStreamingDetails"オブジェクトの中に
      # "concurrentViewers"キーを持つ動画が1つでもあればライブ中とする

      url = YoutubeApi._createLiveCheckingUrl videoSearchResponse
      unless url?
         fn( false )
         return

      core.Util.getRequest url, ( success, xhr ) ->
         if success
            json = JSON.parse xhr.responseText
            if json.items?

               live = false
               for item in json.items
                  live = item.liveStreamingDetails.concurrentViewers?
                  break if live

               fn( live )

            else
               fn( false )
         else
            fn( false )

   @_isLive: ( channelId, fn ) ->
      url = YoutubeApi._createVideoSearchingUrl channelId
      core.Util.getRequest url, ( success, xhr ) ->
         if success
            YoutubeApi._checkLiveVideo JSON.parse( xhr.responseText ), fn
         else
            fn( false )

   @_responseJsonToBroadcastingInfo: ( json ) ->
      channel = json.items[ 0 ]

      bi = new core.BroadcastingInfo
      bi.setId channel.id
      bi.setApiName API_NAME
      bi.setName channel.snippet.title
      bi.setUrl "https://www.youtube.com/channel/#{channel.id}"
      bi.setLive false
      bi.setImageUrl channel.snippet.thumbnails.default.url

      return bi

   @getStreamingPagePattern: ( ) -> [ "https://www.youtube.com/channel/*" ]

   @extractIdFromUrl: ( url ) ->
      if ( matched = url.match /^https:\/\/www\.youtube\.com\/channel\/([\w\-]+)\/?$/ )
         return matched[ 1 ]
      else
         return null

   @search: ( channelId, fn ) ->
      if not core.Util.isSegment channelId
         fn( false, i18n "youtube_channel_not_found" )
      else
         url = YoutubeApi._createChannelRequestUrl channelId
         core.Util.getRequest url, ( success, xhr ) ->
            if success
               json = JSON.parse xhr.responseText
               if json.items.length is 1

                  # 別途APIにアクセスしこの時点でライブ中かどうかを調べる
                  bi = YoutubeApi._responseJsonToBroadcastingInfo json
                  YoutubeApi._isLive bi.getId( ), ( live ) ->
                     bi.setLive live
                     fn( true, bi )

               else
                  fn( false, i18n "youtube_channel_not_found" )
            else
               fn( false, i18n "network_error" )

   @update: ( timestamp, id ) ->
      bi = core.Storage.getBroadcastingInfo API_NAME, id
      return unless bi?

      # YouTubeはRate limitの都合上, 10分に1回の更新にしたいのでタイムスタンプを確認して不要な確認を防ぐ
      before = if _timestamps[ id ]? then _timestamps[ id ] else 0
      if timestamp - before > YOUTUBE_UPDATE_INTERVAL
         _timestamps[ id ] = timestamp

         url = YoutubeApi._createVideoSearchingUrl id
         _queue.queuing url, ( success, xhr ) ->
            if success
               YoutubeApi._checkLiveVideo JSON.parse( xhr.responseText ), ( live ) ->
                  bi.setLive live
                  core.Updater.updated API_NAME, id, bi
            else
               core.Updater.updated API_NAME, id, bi

      else
         core.Updater.updated API_NAME, id, bi

@core.api.YoutubeApi = YoutubeApi

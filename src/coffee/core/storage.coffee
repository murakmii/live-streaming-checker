"use strict"

_broadcasting = { }
_group = { }

# 拡張のデフォルトの設定
_config = { }
_defaultConfig =
   do_notify   : true
   enable_menu : true

class Storage

   # どのグループからも参照されていないBroadcastinginfoを配列で返す
   @_searchDisused: ( ) ->
    
      # 保持している配信情報の一覧を作成
      disused = { }
      for apiName, set of _broadcasting
         disused[ apiName ] = { }
         for id of set
            disused[ apiName ][ id ] = true # 値は重要ではない

      # 作成した一覧から、グループから参照されている配信情報を削除
      for id, g of _group
         g.eachBroadcastingInfo ( apiName, id ) ->
            delete disused[ apiName ][ id ] if disused[ apiName ][ id ]?

      # 残った配信情報をBroadcastinginfoの配列にして返す
      broadcastings = [ ]
      for apiName, set of disused
         for id of set
            broadcastings.push Storage.getBroadcastingInfo( apiName, id ).clone( )

      return broadcastings

   # 不要なBroadcastinginfoを削除する
   @_removeDisused: ( fn ) ->
      keys = [ ]
      for b in @_searchDisused( )
         keys.push b.getStorageKey( )
         delete _broadcasting[ b.getApiName( ) ][ b.getId( ) ]

      # 削除に関して、成否を確認しない
      chrome.storage.local.remove keys, fn

   @migrateFromLocalStorage: ( ) ->
      
      migrated_data = { }

      # Ustreamのデータを移行
      ustream = localStorage.getItem "ustream"
      if ustream?
         ustream = JSON.parse ustream
         if ustream.item?
            for id, data of ustream.item
               info = new core.BroadcastingInfo
               info.setId parseInt( id )
               info.setApiName "ustream"
               info.setName data.name
               info.setUrl data.url
               info.setImageUrl data.img_url
               migrated_data[ info.getStorageKey( ) ] = info.toObject( )

      # Justinのデータを移行
      justin = localStorage.getItem "justin"
      if justin?
         justin = JSON.parse justin
         for id, data of justin
            info = new core.BroadcastingInfo
            info.setId id
            info.setApiName "justin"
            info.setName data.name
            info.setUrl data.url
            info.setImageUrl data.img_url
            migrated_data[ info.getStorageKey( ) ] = info.toObject( )

      # Stickam!のデータを移行
      stickam = localStorage.getItem "stickam"
      if stickam?
         stickam = JSON.parse stickam
         for id, data of stickam
            info = new core.BroadcastingInfo
            info.setId id
            info.setApiName "stickam"
            info.setName data.name
            info.setUrl data.url
            info.setImageUrl data.img_url
            migrated_data[ info.getStorageKey( ) ] = info.toObject( )

      # ニコ生のデータを移行
      nico_live = localStorage.getItem "niconico"
      if nico_live?
         nico_live = JSON.parse nico_live
         for id, data of nico_live
            info = new core.BroadcastingInfo
            info.setId parseInt( id )
            info.setApiName "nico_live"
            info.setName data.name
            info.setUrl data.url
            info.setImageUrl data.img_url
            migrated_data[ info.getStorageKey( ) ] = info.toObject( )

      # グループのデータを移行
      groups = localStorage.getItem "group"
      if groups?
         groups = JSON.parse groups
         for id, data of groups
            group = new core.Group
            group.setName data.name
            
            for stream in data.stream
               api_name = if stream.ctrl is "niconico" then "nico_live" else stream.ctrl
               id       = stream.id
               group.append core.BroadcastingInfo.fromObject( migrated_data[ "b_#{api_name}_#{id}" ] )
            
            group.resetTumbnail( )
            if data.img_provider?
               thumb = data.img_provider
               group.setThumbnail ( if thumb.ctrl is "niconico" then "nico_live" else thumb.ctrl ), thumb.id

            if data.behavior?
               if data.behavior.type is 0
                  group.setBehavior core.Group.Behavior.List
               else
                  group.setBehavior core.Group.Behavior.Optional
                  group.setOptionalLink data.behavior.param

            migrated_data[ group.getStorageKey( ) ] = group.toObject( )

      return migrated_data

   # ストレージを初期化
   @init: ( fn ) ->
      # バージョンの確認
      chrome.storage.local.get "version", ( read ) ->
         if chrome.runtime.lastError?
            fn( false )
         else
            written  = { }
            ver      = chrome.runtime.getManifest( ).version
            if read.version?
               if read.version isnt ver
                  written.version = ver
            else
               # バージョンが存在しない場合は過去のデータ引き継ぎを行う
               written = Storage.migrateFromLocalStorage( )
               written.version = ver

            # バージョンと、必要であれば引き継ぎデータの書き込みを行う
            chrome.storage.local.set written, ( ) ->
               if chrome.runtime.lastError?
                  fn( false )
               else
                  chrome.storage.local.get null, ( read ) ->
                     if chrome.runtime.lastError?
                        fn( false )
                     else
                        # 拡張の設定を読み込む
                        if read.config?
                           for k, v of _defaultConfig
                              _config[ k ] = if read.config[ k ]? then read.config[ k ] else v
                        else
                           _config = _defaultConfig

                        # グループと配信状況を読み込む
                        for k, v of read when k.match /^[gb]_.+/
                           switch k.charAt 0 
                              when "g"
                                 group = core.Group.fromObject v
                                 _group[ group.getId( ) ] = group
                              when "b"
                                 info     = core.BroadcastingInfo.fromObject v
                                 api_name = info.getApiName( )
                                 _broadcasting[ api_name ] = { } unless _broadcasting[ api_name ]?
                                 _broadcasting[ api_name ][ info.getId( ) ] = info

                        fn( true )  

   # 配信情報を取得する. 指定の配信情報が存在しない場合はnullを返す
   @getBroadcastingInfo: ( apiName, id ) ->
      if _broadcasting[ apiName ]? and _broadcasting[ apiName ][ id ]?
         return _broadcasting[ apiName ][ id ].clone( )
      else
         return null

   # 指定の配信情報が存在するかどうかを確認
   @existsBroadcastingInfo: ( apiName, id ) ->
      return _broadcasting[ apiName ]? and _broadcasting[ apiName ][ id ]?

   # 保持しているグループを走査する
   @eachGroup: ( fn ) ->
      groups = ( v for k, v of _group )

      # グループIDはタイムスタンプになっているのでそれを元に昇順ソートしておく
      groups.sort ( a, b ) ->
         a_ts = a.getId( ).split "-"
         b_ts = b.getId( ).split "-"

         idx = +( a_ts[ 0 ] is b_ts[ 0 ] )
         return parseInt( a_ts[ idx ] ) - parseInt( b_ts[ idx ] )

      fn( g.clone( ) ) for g in groups

   # グループを取得
   @getGroup: ( groupId ) -> _group[ groupId ].clone( )

   # グループ中でライブ中の配信情報をカウントする
   @countLive: ( groupId ) ->
      count = 0
      _group[ groupId ].eachBroadcastingInfo ( apiName, id ) ->
         count++ if Storage.getBroadcastingInfo( apiName, id ).isLive( )

      return count

   # グループの数をカウント
   @countGroup: ( ) ->
      count = 0
      for gid, group of _group then count++
      return count

   # グループ情報を保存する
   @saveGroup: ( group, broadcastings, fn ) ->

      # 書き込みデータを作成
      written = { }
      written[ group.getStorageKey( ) ]   = group.toObject( )
      written[ b.getStorageKey( ) ]       = b.toObject( ) for b in broadcastings

      chrome.storage.local.set written, ( ) =>
         if chrome.runtime.lastError?
            fn( false )
         else
            # 内部データを更新
            updated = _group[ group.getId( ) ]?
            _group[ group.getId( ) ] = group.clone( )
            for b in broadcastings
               _broadcasting[ b.getApiName( ) ] = { } unless _broadcasting[ b.getApiName( ) ]?
               _broadcasting[ b.getApiName( ) ][ b.getId( ) ] = b.clone( )
   
            # グループが更新された場合、不要な配信情報が発生する可能性があるので削除を実行する
            @_removeDisused ( ) ->
               chrome.runtime.sendMessage type: core.SavedMessage, groupId: group.getId( ), updated: updated
               fn( true )

   # グループを削除する
   @removeGroup: ( groupId, fn ) ->
      chrome.storage.local.remove "g_#{groupId}", ( ) =>
         if chrome.runtime.lastError?
            fn( false )
         else
            # データを更新
            backup = _group[ groupId ].clone( )
            delete _group[ groupId ]

            @_removeDisused ( ) ->
               chrome.runtime.sendMessage type: core.RemovedMessage, groupId: groupId
               fn( true )

   # グループがライブかどうかを、グループIDをプロパティ名としたオブジェクトとして返す
   @getGroupLiveStatus: ( ) ->
      stat = { }
      stat[ gid ] = Storage.countLive( gid ) > 0 for gid of _group
      return stat

   @getLiveGroupId: ( ) ->
      live = [ ]
      for gid of _group
         live.push gid if Storage.countLive( gid ) > 0

      return live

   # 配信情報を更新する
   # 既知の配信情報以外は渡されても無視する
   @update: ( broadcastings ) ->
      written = { }
      need_write = false # 書き込みフラグ

      for b in broadcastings

         api_name = b.getApiName( )
         id = b.getId( )

         # 配信情報を厳密に比較し、変更点がある場合は内部データの更新と書き込みフラグをON
         if _broadcasting[ api_name ][ id ]? and not b.isStrictlyEqual _broadcasting[ api_name ][ id ]
            _broadcasting[ api_name ][ id ] = b.clone( )
            written[ _broadcasting[ api_name ][ id ].getStorageKey( ) ] = _broadcasting[ api_name ][ id ].toObject( )
            need_write = true
         else
            _broadcasting[ api_name ][ id ] = b.clone( ) # 変更点がない場合は内部データの更新のみ

      chrome.storage.local.set written if need_write

   # 拡張の設定の取得と設定
   @getConfig: ( key ) -> if _config[ key ]? then _config[ key ] else null
   @setConfig: ( key, value ) ->
      _config[ key ] = value
      chrome.runtime.sendMessage type: core.ConfiguredMessage
      chrome.storage.local.set ( config: _config ) # 設定の保存に関して成否を確認しない

@core.Storage = Storage

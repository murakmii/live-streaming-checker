"use strict"

_broadcasting = { }
_group = { }

# 拡張のデフォルトの設定
_config =
   do_notify: true

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

   @migrateFromLocalStorage: ( ) -> { }

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
                        _config = read.config if read.config?

                        # グループと配信状況を読み込む
                        for k, v of read when k.match /[gb]_.+/
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
            _group[ group.getId( ) ] = group.clone( )
            for b in broadcastings
               _broadcasting[ b.getApiName( ) ] = { } unless _broadcasting[ b.getApiName( ) ]?
               _broadcasting[ b.getApiName( ) ][ b.getId( ) ] = b.clone( )
   
            # グループが更新された場合、不要な配信情報が発生する可能性があるので削除を実行する
            @_removeDisused ( ) -> 
               chrome.runtime.sendMessage type: core.SavedMessage, option: group.clone( )
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
               chrome.runtime.sendMessage type: core.RemovedMessage, option: backup
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

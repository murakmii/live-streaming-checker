"use strict"

# 拡張を起動する上で始点となるコード

_completed  = false
_succeeded  = false

# 初回ロードの終了と成功をUI側から読み取れるようにプロパティを定義
Object.defineProperty @core, "loadCompleted", get: ( ) -> _completed
Object.defineProperty @core, "loadSucceeded", get: ( ) -> _succeeded

# 初回ロードと定期アップデートの起動
core.Storage.init ( success ) ->
   _completed = true
   _succeeded = success

   if success
      core.Updater.init( )
      core.Observer.init( )
      core.ContextMenu.enable( ) if core.Storage.getConfig "enable_menu"

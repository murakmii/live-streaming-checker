"use strict"

class Group

   @Behavior:
      List     : 0
      Optional : 1

   _find: ( apiName, id ) ->
      for b, i in @_broadcastings
         if b.apiName is apiName and b.id is id
            return i

      return -1

   constructor: ( ) ->
      @_id = core.Util.createTimestamp( )
      @_name = ""
      @_broadcastings = [ ]
      @_thumb = null
      @_behavior = Group.Behavior.List
      @_optionalLink = ""

   getId: ( ) -> @_id
   setId: ( @_id ) ->

   getName: ( ) -> @_name
   setName: ( @_name ) ->
      unless @_name? then @_name = ""

   emptyName: ( ) -> @_name.length is 0

   getBehavior: ( ) -> @_behavior
   setBehavior: ( @_behavior ) ->

   getOptionalLink: ( ) -> @_optionalLink
   setOptionalLink: ( @_optionalLink ) ->

   has: ( apiName, id ) -> @_find( apiName, id ) isnt -1

   # サムネイルの自動設定が行われた場合はtrueを返す
   append: ( broadcastingInfo ) ->
      api_name    = broadcastingInfo.getApiName( )
      id          = broadcastingInfo.getId( )

      if @has api_name, id
         throw new Error "[Group::append] same BroadcastingInfo already exists"

      @_broadcastings.push apiName: api_name, id: id
      if ( configured = not @_thumb? and broadcastingInfo.hasImageUrl( ) )
         @_thumb = apiName: api_name, id: id

      return configured

   # サムネイルの設定が解除された場合はtrueを返す
   remove: ( apiName, id ) ->
      if ( index = @_find apiName, id ) is -1
         throw new Error "[Group::remove] BroadcastingInfo doesn't exists"

      @_broadcastings.splice index, 1

      if ( unconfigured = ( @_thumb? and apiName is @_thumb.apiName and id is @_thumb.id ) )
         @_thumb = null

      return unconfigured

   eachBroadcastingInfo: ( fn ) ->
      for b in @_broadcastings
         fn( b.apiName, b.id, ( @configuredThumbnail( ) and b.apiName is @_thumb.apiName and b.id is @_thumb.id ) )

   configuredThumbnail: ( ) -> @_thumb?

   setThumbnail: ( apiName, id ) ->
      unless @has apiName, id
         throw new Error "[Group::setThumbnail] BroadcastingInfo doesn't exists"

      @_thumb = apiName: apiName, id: id

   getThumbnail: ( ) ->
      if @configuredThumbnail( )
         return (
            apiName  : @_thumb.apiName
            id       : @_thumb.id
         )
      else
         return null

   getStorageKey: ( ) -> "g_#{@getId( )}"

   clone: ( ) -> Group.fromObject @toObject( )

   toObject: ( ) ->
      group =
         i : @_id
         n : @_name
         bs: [ ]
         b : @_behavior
         o : @_optionalLink

      if @configuredThumbnail( )
         group.t = ( a: @_thumb.apiName, i: @_thumb.id )
      else
         group.t = null

      for b in @_broadcastings
         group.bs.push
            a: b.apiName
            i: b.id

      return group

   @fromObject: ( object ) ->
      group = new Group
      group.setId object.i
      group.setName object.n
      group.setBehavior object.b
      group.setOptionalLink object.o

      for b in object.bs
         group._broadcastings.push apiName: b.a, id: b.i

      group.setThumbnail object.t.a, object.t.i if object.t?

      return group

@core.Group = Group

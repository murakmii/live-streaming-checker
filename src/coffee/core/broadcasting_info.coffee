"use strict"

class BroadcastingInfo

   constructor: ( ) ->
      @_id        = null
      @_apiName   = ""
      @_name      = ""
      @_url       = ""
      @_imgUrl    = ""
      @_live      = false

   getId: ( ) -> @_id
   setId: ( @_id ) -> return @

   getApiName: ( ) -> @_apiName
   setApiName: ( @_apiName ) -> return @

   isEqual: ( target ) -> @_id is target.getId( ) and @_apiName is target.getApiName( )

   isStrictlyEqual: ( target ) ->
      equal = (
         @getId( ) is target.getId( ) and
         @getApiName( ) is target.getApiName( ) and
         @getName( ) is target.getName( ) and
         @hasImageUrl( ) is target.hasImageUrl( )
      )

      if equal and @hasImageUrl( )
         equal = @getImageUrl( ) and target.getImageUrl( )

      return equal

   getName: ( ) -> @_name
   setName: ( @_name ) -> return @

   getUrl: ( ) -> @_url
   setUrl: ( @_url ) -> return @

   setImageUrl: ( @_imgUrl ) ->
      @_imgUrl = "" unless @_imgUrl?
      return @

   getImageUrl: ( ) -> @_imgUrl
   hasImageUrl: ( ) -> @_imgUrl.length isnt 0

   setLive: ( @_live ) -> return @
   isLive: ( ) -> @_live

   clone: ( ) ->
      cloned = BroadcastingInfo.fromObject @toObject( )
      cloned.setLive @isLive( )
      return cloned

   getStorageKey: ( ) -> "b_#{@getApiName( )}_#{@getId( )}"

   toObject: ( ) ->
      i : @_id
      a : @_apiName
      n : @_name
      u : @_url
      m : @_imgUrl

   @fromObject: ( object ) ->
      info = new BroadcastingInfo
      info.setId object.i
      info.setApiName object.a
      info.setName object.n
      info.setUrl object.u
      info.setImageUrl object.m
      return info

@core.BroadcastingInfo = BroadcastingInfo

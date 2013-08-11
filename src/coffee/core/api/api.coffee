"use strict"

class Api

   @getStreamingPagePattern: ( ) ->
      throw new Error "Api::getStreamingPagePattern hasn't implemented"

   @extractIdFromUrl: ( ) ->
      throw new Error "Api::extractIdFromUrl hasn't implemented"

   @search: ( id, fn ) ->
      throw new Error "Api::search hasn't implemented"

   @standbyUpdate: ( timestamp ) ->

   @update: ( timestamp, id ) ->
      throw new Error "Api::update hasn't implemented"

   @endUpdate: ( timestamp ) ->

@core.api ?= { }
@core.api.Api = Api

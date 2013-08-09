"use strict"

class Api

   @search: ( id, fn ) ->
      throw new Error "Api::search hasn't implemented"

   @standbyUpdate: ( timestamp ) ->

   @update: ( timestamp, id ) ->
      throw new Error "Api::update hasn't implemented"

   @endUpdate: ( timestamp ) ->

@core.api ?= { }
@core.api.Api = Api

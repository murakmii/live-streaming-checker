"use strict"

class Api 

   @search: ( id, fn ) -> 
      throw new Error "Api::search hasn't implemented"

   @standbyUpdate: ( timestamp ) ->
      throw new Error "Api::standbyUpdate hasn't implemented"

   @update: ( timestamp, id ) ->
      throw new Error "Api::update hasn't implemented"

   @endUpdate: ( timestamp ) ->
      throw new Error "Api::endUpdate hasn't implemented"

@core.api ?= { }
@core.api.Api = Api

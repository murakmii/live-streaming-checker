"use strict"

_config = { }

class ConfigFile

   @init: ( fn ) ->

      errorCallback = ( ) -> fn( false )

      chrome.runtime.getPackageDirectoryEntry ( root ) ->
         root.getFile 'config.json', ( create: false ), ( config ) ->
            config.file ( file ) ->

               reader = new FileReader
               reader.onerror = errorCallback
               reader.onload = ( e ) ->
                  _config = JSON.parse e.target.result
                  fn( true )

               reader.readAsText file, 'utf-8'

            , errorCallback
         , errorCallback

   @get: ( key ) ->
      if _config[ key ]? then _config[ key ] else null

@core.ConfigFile = ConfigFile

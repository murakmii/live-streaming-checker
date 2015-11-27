"use strict"

@core =
   Supported: [ "ustream", "justin", "twitch", "nico_live", "stickam", "twitcasting", "fc2_live", "youtube" ]

   getSupported: ( ) ->
      supported = [ ]
      for api in core.Supported
         supported.push api unless core.api[ "#{core.Util.toCamelCase api}Api" ].hasDeprecated( )

      return supported

   UpdateInterval : 3 * 60 * 1000

   UpdatedMessage    : 0
   SavedMessage      : 8
   RemovedMessage    : 16
   IsChangedMessage  : 24
   ConfiguredMessage : 32

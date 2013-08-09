"use strict"

class Util

   @setDefaultText: ( textbox, defaultText ) ->
      className = "used-default-text"

      $( textbox ).attr "data-default-text", defaultText

      $( textbox ).bind "focus", ( ) ->
         if $( @ ).hasClass className
            $( @ ).removeClass className
            @value = ""

      $( textbox ).bind "blur", ( ) ->
         if @value.length is 0
            $( @ ).addClass className
            @value = @dataset.defaultText

      if $( textbox ).hasClass className
         textbox.value = defaultText

@ui ?= { }
@ui.Util = Util

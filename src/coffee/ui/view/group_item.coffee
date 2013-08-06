"use strict"

i18n = chrome.i18n.getMessage

class GroupItem extends Backbone.View

   tagName  : "div"
   className: "group-item"

   events:
      "click .remove": "_onClickedRemove"
      "click i": "_onClickedIcon"

   _onClickedRemove: ( ) -> @trigger "remove", @
   _onClickedIcon: ( ) -> if @_iconClickable then @trigger "icon", @

   initialize: ( options ) ->

      @_iconClickable = false
      @_broadcasting = options.broadcasting

      tpl = document.getElementById( "group-item-tpl" ).content
      $( tpl.querySelector "h2" ).text @_broadcasting.getName( )
      $( tpl.querySelector "h3" ).text i18n( @_broadcasting.getApiName( ) )
      $( tpl.querySelector "a" ).text i18n( "remove" )

      icon = tpl.querySelector "i"
      if @_broadcasting.hasImageUrl( )
         icon.style.backgroundImage = "url(\"#{@_broadcasting.getImageUrl()}\")"
         icon.style.display = "block"
      else
         icon.style.display = "none"

      $( @el ).append tpl.cloneNode( true )

      # ツールチップの設定
      @_icon = @el.getElementsByTagName( "i" )[ 0 ]
      $( @_icon ).data "powertip", i18n( "group_icon" )
      @iconClickable true

      @delegateEvents( )

   remove: ( ) ->
      @undelegateEvents( )
      super( )

   getBroadcastingInfo: ( ) -> @_broadcasting

   iconClickable: ( @_iconClickable ) ->
      if @_iconClickable
         @_icon.className = ""
         $( @_icon ).powerTip placement: "e"
      else
         @_icon.className = "selected"
         document.getElementById( "powerTip" ).style.display = "none"
         $( @_icon ).powerTip "destroy"

@ui.view ?= { }
@ui.view.GroupItem = GroupItem

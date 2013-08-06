"use strict"

i18n = chrome.i18n.getMessage

# ポップアップのヘッダビュー
class Header extends Backbone.View

   el    : "#header"
   events: 
      "click button": "_onClickedAdd"

   _onClickedAdd: ( ) -> @trigger "editgroup", null

   initialize: ( ) ->　document.header.add.innerText = i18n "header_button"

@ui.view ?= {}
@ui.view.Header = Header

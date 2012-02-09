###

Usage:

  {dialog} = require "stratus-ui"
  dlg = dialog "Open Project", $body
  
  dlg.on "close", -> console.log "You closed the dialog"

###
{EventEmitter} = require 'events'

FADE_IN  = 100
FADE_OUT = 150

# Public: Create a dialog.
# 
# title - The title text.
# body  - The HTML or jQuery element that will be the body content
#         of the dialog.
# options - (optional)
#         * draggable - (default: false)
#         * closeable - (default: true)
#         * modal     - (default: false) whether or not to shade
#                       the page content behind the dialog.
# 
# Returns Dialog.
module.exports = (title, body, options = {}) ->
  return new Dialog title, body, options


# Options:
# 
#   * draggable - Whether or not the dialog can be dragged around.
#   * closeable - Whether or not the dialog has a close button.
#   * modal     - Whether or not the area behind the dialog should be shaded.
# 
# Events:
# 
#   * close - called when the dialog is closed.
# 
class Dialog extends EventEmitter
  constructor: (@title, @body, options) ->
    {@draggable, @closeable, @modal} = options
    @draggable ?= false
    @closeable ?= true
    @modal     ?= false
    @open()
    
    @showModal() if @modal
  
  open: ->
    @$el  = $(@markup()).appendTo "body"
    @$el.find(".body").append @body
    @$el.hide().fadeIn(FADE_IN)
    
    @$el.find("header > .close").on "click", =>
      @close()
    
    if @draggable
      @$el
        .css
          top:  $("body").height() / 2 - @$el.height() / 2
          left: $("body").width()  / 2 - @$el.width()  / 2
        .draggable
          handle:      "header"
          containment: "body"
          cursor:      "move"
  
  close: ->
    @modal && @modal.hide()
    @$el.fadeOut FADE_OUT, =>
      @$el.remove()
      @emit "close"
  
  showModal: ->
    @modal = new Modal()
    @modal.on "click", => @close()
  
  markup: ->
    close = if @closeable
      "<button class='close iconic x'></button>"
    else
      ""
    extraClass = if @draggable
      " dialog-draggable"
    else
      ""
    return "<div class='dialog#{ extraClass }'>
      <header>
        <h1>#{ @title }</h1>
        #{ close }
      </header>
      <section class='body'></section>
      <footer></footer>
    </div"

# Events:
# click - Called when the modal is hidden/removed.
class Modal extends EventEmitter
  constructor: ->
    @$el = $("<div/>", class: "modal").appendTo "body"
    @$el.hide().fadeIn(FADE_IN)
    @$el.on "click", => @emit "click"
  
  hide: ->
    @$el.fadeOut FADE_OUT, => @$el.remove()


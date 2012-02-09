{EventEmitter} = require 'events'

# Public: A select box(ish) control.
# 
# $target  - The target element.
# onSelect - A function called when the value changes, with the
#            argument `(value)`.
# options  - (optional)
#          * items  - Array of String
#          * height - Integer
#          * width  - Integer
# 
# Examples
# 
#   select $button, (value) ->
#     console.log "You selected #{value}"
#   , items: ["cheese", "pickles", "crackers"]
# 
# Returns a Select.
module.exports = select = (onSelect, options={}) ->
  s = new Select options
  s.on "select", onSelect
  return s


# Public: A select box(ish) control.
# 
# Same as `module.exports`, except it also binds a toggle listener
# to the target element.
# 
# Returns a Select.
select.toggle = ($target, onSelect, options={}) ->
  s = select onSelect, options
  $target.mousedown (event) =>
    # Already selected - hide.
    if $target.hasClass("active")
      s.hide()
    # Not selected - show.
    else if s.items.length
      s.show()
    return false
  $target.click -> false
  s.on "hide", -> $target.removeClass "active"
  s.on "show", ->
    $target?.addClass "active"
    s.rePosition $target
  return s


# Events:
# 
#   * select
#   * show
#   * hide
# 
# Properties:
# 
#   * items
#   * $target
#   * $list
# 
class Select extends EventEmitter
  # Internal: Initialize a Select.
  # See arguments for `module.exports` for `options`.
  constructor: (options) ->
    {@items, @height, @width} = options
    @$el = $ "<menu></menu>", class: "menu"
    @$el.hide().appendTo "body"
    
    $("body").click => @hide()
    @$el.on "click", "li", (event) =>
      @emit "select", $(event.currentTarget).text()
  
  # Internal: Get the html for the inner list items.
  # 
  # Returns String html.
  innerMarkup: ->
    html = ""
    for item in @items
      html += "<li>#{item}</li>"
    return html
  
  # Internal: Position the element.
  # 
  # $target (optional)
  # 
  rePosition: ($target) ->
    $target ||= $target
    offset    = $target.offset()
    top       = offset.top  + $target.outerHeight()
    left      = offset.left + $target.outerWidth() - @width
    @$el.css {top, left, @height, @width}
  
  # Internal: Hide the menu.
  hide: ->
    @$el.hide()
  
  # Internal: Show the menu.
  show: ->
    @emit "show"
    @$el.html(@innerMarkup()).show()
  

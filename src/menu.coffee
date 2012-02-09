###
A context menu is triggered when an element is right-clicked. This overrides
the browser's default context menu.

When a menu is being displayed, it's target element is given the class
"active".

  menu             $target, [{text, action}, ...], gravity: right, width: 350
  menu.contextmenu $target, [{text, action}, ...]
  menu.toolbar     $target, {File: [{text, action}, ...]}

###

# Public: When $target is *left* clicked, display a menu.
# 
# $target - The target element.
# actions - A list of objects. Each must have one of the following
#           combos of properties.
#           
#           Normal:
#             * `text` and `click`:
#               The `click` function receives the element clicked.
#             * Instead of `click`, you can pass an `href` option
#               which will be opened in a new tab.
#           
#           Nested dropdown (cascade):
#             * `text` and `actions` where `actions` is a list of actions.
#             * `text` and `actions` where `actions` is a function which
#               returns a list of actions.
#           
#           Divider:
#             * No properties (`{}`).
# 
# Examples
# 
#   {menu} = require 'stratus-ui'
#   menu $el, [
#     { text: "Action 1", click: ($el) -> ... }
#     { text: "Action 2", click: ($el) -> ... }
#     {} # a divider
#     { text: "Action 3", click: ($el) -> ... }
#   ]
# 
# Return an instance of Menu.
module.exports = menu = ($target, actions) ->
  _menu = new Menu actions, "toolbar", $target
  $target.on "click", (ev) ->
    if $target.hasClass "active"
      _menu.hide()
    else
      _menu.show(ev)
  return _menu

# Attach a context menu to $target (triggered on *right* click).
# 
# $target - The target element.
# actions - See `menu()`
# 
# Examples
# 
#   {contextmenu} = require('stratus-ui').menu
#   contextmenu $el, [
#     { text: "Action 1", click: ($el) -> ... }
#     { text: "Action 2", click: ($el) -> ... }
#     {} # a divider
#     { text: "Action 3", click: ($el) -> ... }
#   ]
# 
# Return an instance of Menu.
module.exports.contextmenu = ($target, actions) ->
  _menu    = new Menu actions, "contextmenu", $target
  showMenu = (ev) -> _menu.show(ev)
  $target.on "contextmenu", showMenu
  
  _menu.unbind = -> $target.off "contextmenu", showMenu
  
  return _menu

# Change $target into a toolbar.
# 
# $target - The target element.
# actions - See `menu()`
# 
# Examples
# 
# Using the following markup (in Jade):
# 
#   ul.toolbar
#     li File
#     li Edit
#     li View
# 
#   {toolbar} = require('stratus-ui').menu
#   toolbar $(".toolbar"),
#     File: [ {text: "New file",    click: -> ... }
#           , {text: "Save file",   click: -> ... }
#           , {text: "Open recent", items:
#               [ {text: "server.js", click: -> ...}
#               , {text: "packages.json", click: -> ...}
#               ]
#             }
#           ]
#     Edit: [{text: "Copy",         click: -> ...}]
#     View: [{text: "Split screen", click: -> ...}]
# 
# Return an object where the keys are the labels and the
# values are instances of Menu.
module.exports.toolbar = ($toolbar, dropdowns) ->
  tb = {}
  $toolbar.find("> ul > li").each ->
    $target   = $(this)
    label     = $target.text()
    _menu     = menu $target, dropdowns[label]
    tb[label] = _menu
    
    $target.on "hover", ->
      if $(".menu-target.active").length
        hideAllMenus()
        _menu.show()
  return tb


class Menu
  # actions - See module.exports.
  # type    - "contextmenu" or "toolbar"
  # $target - The element that will be clicked to trigger the menu.
  #           *Important*: this does *not* bind the click event to Menu#show,
  #           you must do that!
  constructor: (@actions, @type, @$target) ->
    @$target.addClass "menu-target"
  
  
  # Public: Add an action to the end of the list.
  # 
  # action - An object (see module.exports for properties).
  # 
  # No return.
  append: (action) ->
    @$el?.append @_actionMarkup(action)
    @actions.push action
    return
  
  createElement: ->
    @$el = $ @_markup()
    @$el.appendTo "body"
    
    @$el.on "click", "li:not(.divider)", (ev) =>
      @trigger $ ev.currentTarget
    
    @$el.on "hover", "li:not(.cascade):not(.divider)", (ev) =>
      # When hovering over a normal item, hide siblings' cascades.
      for action in @actions
        action.submenu?.hide()
    
    @$el.on "mouseover", "li.cascade", (ev) =>
      @cascade $ ev.currentTarget
  
  
  # Display the menu.
  # 
  # event - An event object, which is used to position the menu.
  # 
  show: (event) ->
    @$target.addClass "active"
    if @type == "contextmenu"
      hideAllMenus()
    
    if @$el
      @$el.show()
    else
      @createElement()
    
    if @type == "contextmenu"
      @_positionContextmenu event
    else if @type == "toolbar"
      @_positionToolbar event
    else if @type == "cascade"
      @_positionCascade event
    else
      throw new Error "'#{@type}' is not a valid Menu type."
    
    return false
  
  # Remove the menu.
  hide: ->
    # Hide siblings' cascades.
    for action in @actions
      action.submenu?.hide()
    
    @$el?.hide()
    @$target.removeClass "active"
    return false
  
  # Run the action corresponding with the item.
  trigger: ($item) ->
    itemNum = $item.index()
    @actions[itemNum].click? $item
    return
  
  # Display the sub-menu.
  cascade: ($item) ->
    for action in @actions
      action.submenu?.hide()
    
    itemNum         = $item.index()
    action          = @actions[itemNum]
    # Dont cache the sub-menu for function actions.
    if _.isFunction action.actions
      action.submenu = new Menu @_subActions(action), "cascade", $item
    else
      action.submenu ?= new Menu @_subActions(action), "cascade", $item
    action.submenu.show()
  
  
  # Return the html markup (string) of the menu.
  _markup: ->
    html = "<menu type='#{@type}' class='menu #{@type}'>"
    for item in (@actions || [])
      html += @_actionMarkup item
    html += "</menu>"
    return html
  
  # Return the html markup (string) of the action.
  _actionMarkup: (action) ->
    if action.text
      cssClass = if action.actions then " class='cascade'" else ""
      if action.href
        link = "<a href='#{action.href}' target='_blank'>#{ action.text }</a>"
        return "<li#{cssClass}>#{ link }</li>"
      else
        return "<li#{cssClass}>#{ action.text }</li>"
    else
      return "<li class='divider'></li>"
  
  # Position the toolbar.
  # 
  # The ideal position for the drop down is directly below the target, with
  # the left edges aligned.
  # 
  _positionToolbar: (event) ->
    {left, top}  = @$target.offset()
    targetHeight = @$target.outerHeight()
    menuHeight   = @$el.outerHeight()
    menuPos      =
      left: left
      top:  top + targetHeight
    
    if @_isTooFarDown menuPos.top
      menuPos.bottom = 0
    if @_isTooFarRight menuPos.left
      targetWidth   = @$target.outerWidth()
      menuPos.left  = "auto"
      menuPos.right = $("body").width() - left - targetWidth
    
    @$el.css menuPos
  
  # Position the menu.
  # 
  # The position is offset by 2 pixels in each direction from where the
  # cursor clicked. Ideally, the dropdown will be to the bottom-right,
  # of the click. If that would place the dropdown off-screen, it will
  # go to the left/top as necessary.
  # 
  _positionContextmenu: (event) ->
    left = event.pageX + 2
    top  = event.pageY + 2
    if @_isTooFarRight left
      right  = $("body").width() - left + 2
      left   = "auto"
    if @_isTooFarDown top
      bottom = $("body").height() - top + 2
      top    = "auto"
    @$el.css { left, right, top, bottom }
  
  # Position the cascaded menu.
  # 
  # Ideal position for the cascade is to the left of the target, with
  # the top edges aligned.
  _positionCascade: (event) ->
    {left, top} = @$target.offset()
    targetWidth = @$target.outerWidth()
    menuHeight  = @$el.outerHeight()
    menuPos     =
      left: left + targetWidth
      top:  top
    
    if @_isTooFarDown menuPos.top
      menuPos.top    = "auto"
      menuPos.bottom = $("body").height() - top
    if @_isTooFarRight menuPos.left
      menuPos.left  = "auto"
      menuPos.right = $("body").width() - left
    
    @$el.css menuPos
  
  # Return whether or not the menu will overflow off of the bottom of
  # the screen.
  _isTooFarDown: (top) ->
    return top + @$el.outerHeight() >= $("body").height()
  
  # Return whether or not the menu will overflow off of the right side of
  # the screen.
  _isTooFarRight: (left) ->
    return left + @$el.outerWidth() >= $("body").width()
  
  
  # Get the action's sub-items.
  _subActions: (action) ->
    if _.isFunction action.actions
      return action.actions()
    else
      return action.actions


hideAllMenus = ->
  $(".menu").hide()
  $(".menu-target").removeClass "active"

jQuery ($) ->
  $("body").click -> hideAllMenus()


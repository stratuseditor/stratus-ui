###

  {tree} = require 'stratus-ui'
  tree [
    {text: "README.md",     icon: "/icon.png"}
    {text: "server.coffee", icon: "/icon.png"}
    {text: "client",        icon: "/icon.png", isExpandable: true}
  ], (text, path) ->
    console.log "You clicked on #{text}"
    
  , (text, path, callback) ->
    fs.readDir path, (files) ->
      callback files

###
keyboard      = require 'stratus-keyboard'
{contextmenu} = require './menu'

TREE_SCOPE    = "stratus-ui-tree"

module.exports = tree = (labels, click, expand) ->
  return new Tree labels, click, expand


# Events:
# 
class Tree
  @current: null
  
  constructor: (leaves, @onClick, @onExpand) ->
    @children     = {}
    @$root        = $ "<ul/>", class: "tree"
    @selectedLeaf = null
    for leafOptions in leaves
      @addLeaf leafOptions
    
    @$root.on "click", [
      ".leaf.normal > .leaf-label"
      ".leaf.normal > .leaf-icon-1"
    ].join(", "), (event) =>
      @_setCurrentTree()
      
      $leaf = $(event.currentTarget).parent()
      label = $leaf.children(".leaf-label").text()
      path  = @findPath($leaf)
      @onClick label, path
      
      leaf = @findLeaf path
      @select leaf
      return false
    
    @$root.on "click", [
      ".leaf.expandable > .leaf-label"
      ".leaf.expandable > .leaf-icon-1"
      ".leaf.expandable > .leaf-triangle"
    ].join(", "), (event) =>
      @_setCurrentTree()
      
      $leaf = $(event.currentTarget).parent()
      label = $leaf.children(".leaf-label").text()
      path  = @findPath $leaf
      leaf  = @findLeaf path
      
      @select leaf
      
      if leaf.isExpanded
        @collapse path
      else
        @expand path
      return false
    
    @$root.on "click", ".leaf", (event) =>
      @_setCurrentTree()
      
      $leaf = $(event.currentTarget)
      leaf  = @find$Leaf $leaf
      
      @select leaf
      
      # Make sure the context menus get hidden.
      $("body").click()
      return false
  
  
  # Public: Add a leaf to the tree.
  addLeaf: (leafOptions) ->
    leafOptions.parent          = this
    @children[leafOptions.text] = leaf = new Leaf leafOptions
    @$root.append leaf.$el
  
  # Get the path of the leaf element by recursing up the tree.
  findPath: ($leaf) ->
    path = $leaf.children(".leaf-label").text()
    while ($leaf = $leaf.parent().parent()) && $leaf.hasClass("leaf")
      path = "#{ $leaf.children(".leaf-label").text() }/#{ path }"
    return path
  
  # Return an instance of Leaf at the given path.
  findLeaf: (path) ->
    return this if !path
    parts = path.split "/"
    parts.shift() if !parts[0]
    leaf  = @children[parts[0]]
    for part in parts[1..-1]
      leaf = leaf.children[part]
    return leaf
  
  # Find a leaf instance using the leaf's element.
  find$Leaf: ($leaf) ->
    path = @findPath $leaf
    return @findLeaf path
  
  # Public: Expand the leaf identified by the given path.
  expand: (path) ->
    leaf = @findLeaf path
    return unless leaf.isExpandable
    return if leaf.isExpanded
    # The leaf has expanded before.
    if !leaf.$children
      label = _.last path.split "/"
      @onExpand label, path, (leaves) ->
        for leafOptions in leaves
          leaf.addLeaf leafOptions
        return
    leaf.expand()
  
  # Public: Collapse the leaf identified by the given path.
  collapse: (path) ->
    leaf = @findLeaf path
    return unless leaf.isExpandable
    return if !leaf.isExpanded
    leaf.collapse()
  
  # Public: Remove the leaf from the tree.
  # 
  # path - The path of the leaf to remove.
  # 
  # Examples
  # 
  #   tree.removeLeaf "client/server.coffee"
  # 
  removeLeaf: (path) ->
    leaf = @findLeaf path
    leaf.remove()
  
  # Public: Make the given leaf editable.
  # 
  # path     - The path of the leaf to edit.
  # callback - Receives `(newText, oldText)`. This is only called if
  #            the text changes.
  # 
  # Examples
  # 
  #   tree.editLeaf "client/server.coffee", (newFileName) ->
  #     # ...
  # 
  editLeaf: (path, callback) ->
    leaf = @findLeaf path
    leaf.editable callback
  
  # Public: Attach a context menu to the leaves.
  # 
  # callback - When a context menu is triggered on a leaf, the
  #            callback is called with that leaf as it's argument.
  #            It should return a list of actions to be passed to
  #            `menu.contextmenu`.
  # 
  # Examples
  # 
  #   my_tree.contextmenu (path, leaf) ->
  #     if leaf.isExpandable
  #       return [{ text: "Expandable leaf", click: -> console.log("1") }]
  #     else
  #       return [{ text: "Regular leaf", click: -> console.log("1") }]
  # 
  # No return.
  contextmenu: (callback) ->
    @$root.on "contextmenu", ".leaf", (event) =>
      $leaf   = $(event.currentTarget)
      path    = @findPath $leaf
      leaf    = @findLeaf path
      @select leaf
      
      actions = callback path, leaf
      menu    = contextmenu $leaf, actions
      menu.show event
      menu.unbind()
      return false
  
  select: (leaf) ->
    @selectedLeaf?.deselect()
    @selectedLeaf = leaf
    @selectedLeaf.select()
  
  # Mark that this tree is focused.
  _setCurrentTree: ->
    Tree.current = this
    keyboard.scope TREE_SCOPE



# Options:
# text         - The leaf's label.
# icon         - A 16x16 pixel image displayed just to the left of the label.
# icon2        - A 16x16 pixel image displayed on the far right of the
#                leaf's row. (optional)
# isExpandable - Whether or not the leaf is a parent node.
# parent       - An instance of Tree or Leaf.
class Leaf
  constructor: (options) ->
    {@text, @icon, @icon2, @isExpandable, @parent} = options
    @isExpanded = false
    @children   = {}
    @$el        = $ @markup()
    @$label     = @$el.children(".leaf-label")
  
  markup: ->
    cssClass = if @isExpandable then "expandable" else "normal"
    triangle = if @isExpandable then "<div class='leaf-triangle'/>" else ""
    icon2    = if @icon2
      "<img class='leaf-icon-2' src='#{ @icon2 }'/>"
    else
      ""
    return "<li class='leaf #{cssClass}'>
      <div class='selection'/>
      #{ triangle }
      <img class='leaf-icon-1' src='#{ @icon }'/>
      <span class='leaf-label'>#{ @text }</span>
      #{icon2}
    </li>"
  
  # Public: 
  setIcon: (@icon) ->
    @$el.children(".leaf-icon-1").attr "src", @icon
  
  # Public: 
  setIcon2: (@icon2) ->
    @$el.children(".leaf-icon-2").attr "src", @icon
  
  # Public: 
  setText: (newText) ->
    @parent.children[@text] = null
    @text                   = newText
    @parent.children[@text] = this
    @$label.text @text
  
  # Add a leaf to the tree.
  addLeaf: (leafOptions) ->
    leafOptions.parent          = this
    @children[leafOptions.text] = leaf = new Leaf leafOptions
    
    if !@$children
      @$children = $("<ul/>").appendTo @$el
    
    @$children.append leaf.$el
  
  
  # Expand the leaf. Note that this only displays children which have
  # already been added elsewhere.
  expand: ->
    @isExpanded = true
    @$el.addClass "expanded"
    @$children.show() if @$children
  
  # Hide the child leaves.
  collapse: ->
    @isExpanded = false
    @$el.removeClass "expanded"
    @$children.hide()
  
  remove: ->
    @$el.remove()
    delete @parent.children[@text]
  
  editable: (callback) ->
    oldText = @text
    $input  = $ "<input/>"
      type:  "text"
      class: "leaf-edit"
      value: oldText
    @$label.hide().after $input
    
    $input.focus().on "keydown", (event) =>
      key = keyboard.keyMap[event.which]
      if key == "\n"
        newText = $input.val()
        if newText != oldText
          callback newText, oldText
          @setText newText
        $input.remove()
        @$label.show()
        return false
      else if key == "Escape"
        $input.remove()
        @$label.show()
      else
        return true
  
  deselect: ->
    @$el.removeClass "selected"
  
  select: ->
    @$el.addClass "selected"



TreeNavigator =
  _tree: -> Tree.current
  
  # Previous
  Up: ->
    tree           = TreeNavigator._tree()
    {selectedLeaf} = tree
    $leaf          = selectedLeaf.$el
    $prev          = $leaf.prev()
    
    # Previous sibling('s last child.)
    if $prev.length && $prev.hasClass "expandable"
      $child = $prev.find(".leaf:visible:last")
      $prev  = $child if $child.length
    
    # Parent node.
    $prev = $leaf.parent().closest ".leaf" if !$prev.length
    
    tree.select tree.find$Leaf $prev if $prev.length
  
  # Next
  Down: ->
    tree           = TreeNavigator._tree()
    {selectedLeaf} = tree
    $leaf          = selectedLeaf.$el
    
    # Child leaf
    $next = if $leaf.hasClass("expandable")
      $leaf.find(".leaf:visible:first")
    else
      []
    
    # Sibling leaf
    $next = $leaf.next() if !$next.length
    
    # Parent's sibling leaf
    if !$next.length
      $parent = $leaf
      while !$next.length and $parent.length and $parent.hasClass("leaf")
        $parent = $parent.parent().closest(".leaf")
        $next   = $parent.next() if $parent.length
    
    tree.select tree.find$Leaf $next if $next.length
  
  # Expand
  Right: ->
    tree           = TreeNavigator._tree()
    {selectedLeaf} = tree
    path           = tree.findPath selectedLeaf.$el
    tree.expand path
  
  # Collapse.
  Left: ->
    tree           = TreeNavigator._tree()
    {selectedLeaf} = tree
    path           = tree.findPath selectedLeaf.$el
    tree.collapse path
  
  # First
  Home: ->
    tree  = TreeNavigator._tree()
    $leaf = tree.$root.find ".leaf:visible:first"
    tree.select tree.find$Leaf $leaf if $leaf.length
  
  # Last
  End: ->
    tree  = TreeNavigator._tree()
    $leaf = tree.$root.find ".leaf:visible:last"
    tree.select tree.find$Leaf $leaf if $leaf.length
  
  # First sibling
  PageUp: ->
    tree           = TreeNavigator._tree()
    {selectedLeaf} = tree
    $leaf          = selectedLeaf.$el.parent().children ".leaf:first"
    tree.select tree.find$Leaf $leaf if $leaf.length
  
  # Last sibling
  PageDown: ->
    tree           = TreeNavigator._tree()
    {selectedLeaf} = tree
    $leaf          = selectedLeaf.$el.parent().children ".leaf:last"
    tree.select tree.find$Leaf $leaf if $leaf.length
  

# Toggle an expandable leaf, or select a normal left.
# (Same behavior as clicking the leaf).
TreeNavigator["\n"] = ->
  tree           = TreeNavigator._tree()
  {selectedLeaf} = tree
  selectedLeaf.$label.click()


# Skip to the next expandable leaf.
TreeNavigator["\t"] = ->
  tree   = TreeNavigator._tree()
  origin = tree.selectedLeaf
  while {selectedLeaf} = tree
    TreeNavigator.Down()
    newLeaf = tree.selectedLeaf
    break if newLeaf.text == selectedLeaf.text
    break if newLeaf.isExpandable
  tree.select origin if !newLeaf.isExpandable
  return false


# Skip to the previous expandable leaf.
TreeNavigator["Shift-\t"] = ->
  tree           = TreeNavigator._tree()
  origin = tree.selectedLeaf
  while {selectedLeaf} = tree
    TreeNavigator.Up()
    newLeaf = tree.selectedLeaf
    break if newLeaf.text == selectedLeaf.text
    break if newLeaf.isExpandable
  tree.select origin if !newLeaf.isExpandable
  return false


# A keyboard scope for navigating the tree.
# Summary:
# 
#   * Up/Down      - Navigate among visible leaves.
#   * Left         - Collapse expandable leaf.
#   * Right        - Expand expandable leaf.
#   * Home/end     - Navigate to first or last visible leaf.
#   * Page up/down - Navigage to the first or last sibling of the current leaf.
#   * Enter        - Equivalent to clicking the leaf.
#   * Tab          - Navigate to the next expandable leaf.
#   * Shift-Tab    - Navigate to the previous expandable leaf.
# 
keyboard TREE_SCOPE, TreeNavigator


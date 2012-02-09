###
The filterbox control is inspired by TextMate's "Go To File" feature.
The text you type into the input box is used to filter a list of items.
Use the arrow keys to navigate them, and press _enter_ to select one.

## Keybinding summary

  * Enter        - Select the highlighted item
  * Down/Tab     - Highlight the next item
  * Up/Shift-Tab - Highlight the previous item
  * Escape       - Hide the dialog (if any, it isn't necessary).
  * Home         - Highlight the first item in the list.
  * End          - Highlight the last item in the list.

## API

  require('stratus-ui').filterbox $input, $list,
    items: ["dj/stratus", "dj/foo", "dj/bar"]
    
    select: ($item) ->
      console.log "You selected", $item
    
    cancel: ->
      console.log "Cancel selection"
    
    filter: "contains"
    
    itemToHtml: (item) -> "<li class='project'>#{ item }</li>"


###
keyboard = require 'stratus-keyboard'
fuzzy    = require 'fuzzy-filter'

KEYBOARD_SCOPE = "Filterbox"

# Create a filterbox.
# 
# For arguments, see Filterbox#constructor.
# 
# Return an instance of Filterbox.
module.exports = filterbox = ($input, $list, options) ->
  return new Filterbox $input, $list, options


# Filtering algorithms.
# Each receives `(string, items, options)` and return a list of items
# that match.
class Filters
  # Filter items by inclusion of the substring (case-insensitive).
  @contains: (substring, items) ->
    substring = substring.toLowerCase()
    _(items).filter (item) ->
      return item.toLowerCase().indexOf(substring) > -1
  
  # Fuzzy filter.
  @fuzzy: (pattern, items, options) ->
    fuzzy pattern, items, options


class Filterbox
  @current: null
  
  # @$input - An input element to filter by.
  # @$list  - The list element of items. It's children should be the
  #           items in the list.
  # options - Some other stuff
  #           items  - An array of strings, the items to filter through.
  #           select - A callback which is passed the chosen $item.
  #           cancel - A function called when the user hits escape.
  #           filter - A filter function name: "contains" or
  #                    ... (optional).
  #           itemToHtml - A function which receives an item (string)
  #                       and returns an html string (optional).
  #           empty  - Boolean: set to true to not display anything when
  #                    the text field is empty.
  #           wrap   - Boolean: whether or not to wrap around.
  #                    (default: false).
  # 
  # Examples
  # 
  #   filterbox $input, $list,
  #     items: ["stratus", "foo", "bar"]
  #     
  #     select: ($item) ->
  #       console.log "You selected", $item
  #     
  #     cancel: ->
  #       console.log "Cancel selection"
  #     
  #     filter: "contains"
  #     
  #     itemToHtml: (item) -> "<li class='project'>#{ item }</li>"
  # 
  constructor: (@$input, @$list, options) ->
    {@select, @cancel, @filter, @items,
     @itemToHtml, @empty, @filterOpts, @wrap} = options
    @empty       ?= false
    @filter     ||= "contains"
    @itemToHtml ||= (item) -> "<li>#{ item }</li>"
    @wrap        ?= false
    
    @$input.on
      input: =>
        @filterItems()
      focus: =>
        Filterbox.current = this
        @highlightFirst() unless @$list.children(".current").length
        return
      blur: =>
        Filterbox.current = null
    keyboard.focus @$input, KEYBOARD_SCOPE
    
    # Populate the list with items.
    if !@empty
      @$list.html _(@items).map(@itemToHtml).join("")
    
    @$list.on "click", "li", (event) =>
      @enter $(event.currentTarget), event
      return false
  
  # Filter the items, and display the results.
  filterItems: ->
    filterText = @$input.val()
    if !filterText && @empty
      @$list.empty()
      return
    items      = Filters[@filter] filterText, @items, @filterOpts
    @$list.html _(items).map(@itemToHtml).join("")
    @highlightFirst()
  
  
  # Highlight the previous item in the list.
  # Do nothing at the beginning of the list.
  # 
  # No return.
  prev: ->
    if ($p = @$currentItem.prev()).length
      @highlight $p
    else if @wrap
      @highlight @$list.children(":last-child")
  
  # Highlight the next item in the list.
  # Do nothing at the end of the list.
  # 
  # No return.
  next: ->
    if ($p = @$currentItem.next()).length
      @highlight $p
    else if @wrap
      @highlight @$list.children(":first-child")
  
  
  # Highlight the given item.
  # 
  # No return.
  highlight: ($item) ->
    @$currentItem?.removeClass "current"
    @$currentItem = $item.addClass "current"
    
    # Scroll the list in order to make the current item visible (if it is not).
    # ###
    
    # The distance from the top of the list to the top of the visible
    # portion of the list.
    yScroll    = @$list.scrollTop()
    # The height of the visible portion of the list.
    listHeight = @$list.height()
    # The position relative to the top of the visible portion of the list.
    yItemPos   = @$currentItem.position().top - @$list.position().top
    # The height of a single list item.
    itemHeight = @$currentItem.height()
    
    # Too far down -> scroll down.
    # And now, a confusing diagram:
    # ____________
    # | Item 1 |  \___ yScroll
    # | Item 2 |__/
    # - - - - - ---\--------------------\
    # | Item 3 |    \_ Visible content   \__ yItemPos
    # | Item 4 |    /  : listHeight      /
    #  - - - - ----/                    /
    # |*Item 5*|-----------------------/
    # |--------|
    if yItemPos + 2*itemHeight + 1 > listHeight
      newScroll = yScroll + yItemPos - listHeight + 2*itemHeight
      @$list.scrollTop newScroll
    
    # Too far up -> scroll up
    else if yItemPos - itemHeight < 0
      newScroll = yScroll + yItemPos - itemHeight
      @$list.scrollTop newScroll
  
  
  # Highlight the first item in the list.
  highlightFirst: ->
    $item = @$list.children(":first-child")
    @highlight $item if $item.length
  
  # Highlight the last item in the list.
  highlightLast: ->
    $item = @$list.children(":last-child")
    @highlight $item if $item.length
  
  # Select the item.
  # If no item is selected, do nothing.
  # 
  # $item - The item to select. If not passed, use the currently selected
  #         item (optional).
  # 
  enter: ($item=null, event=null) ->
    $item ||= @$currentItem
    if $item && $item.is(":visible")
      @select $item, event
  
  # Focus the input of the filterbox.
  focus: ->
    @$input.focus()



keyboard KEYBOARD_SCOPE,
  "\n":       -> Filterbox.current?.enter?();  false
  "Escape":   -> Filterbox.current?.cancel?(); false
  
  "Down":     -> Filterbox.current?.next?();   false
  "Up":       -> Filterbox.current?.prev?();   false
  "\t":       -> Filterbox.current?.next?();   false
  "Shift-\t": -> Filterbox.current?.prev?();   false
  "Home":     -> Filterbox.current?.highlightFirst?(); false
  "End":      -> Filterbox.current?.highlightLast?();  false



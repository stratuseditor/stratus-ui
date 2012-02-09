###
Sample tab markup:

  <div class='tabs'>
    <nav><ul>
      <li>Tab 1</li>
      <li>Tab 2</li>
      <li>Tab 3</li>
    </ul></nav>
    
    <div class='tab-contents'>
      <section>
        Contents 1
      </section>
      
      <section>
        Contents 2
      </section>
      
      <section>
        Contents 3
      </section>
    </div>
  </div>

Usage:

  tabs = require("stratus-ui").tabs $(".tabs"),
    closeable: true
    draggable: true
  
  tabs.append "Another Tab", "<h1>Magnificent content!</h1>"

###
{EventEmitter} = require 'events'

# Events:
# 
# 
class TabContainer extends EventEmitter
  constructor: (@$el, options) ->
    {@draggable} = options
    @draggable  ?= false
    
    @tabs       = []
    @currentTab = null
    
    @$el.find("> nav > ul > li").each (i, el) =>
      $tab        = $(el)
      index       = $tab.index()
      $contents   = @$el.find(".tab-contents > section:eq(#{index})")
      tab         = @append $tab, $contents, false
      if $tab.hasClass "current"
        @currentTab = tab
  
  # Iterate the tabs, passing each into the callback.
  each: (callback) ->
    for tab in @tabs
      callback tab
  
  # Select the given tab.
  show: (tab) ->
    return if tab == @currentTab
    @currentTab?.deselect()
    @currentTab = tab
    @currentTab.select()
  
  # Add the tab to the container.
  # 
  # $handle  - The handle element.
  # $content - The content
  # addToDOM - Whether or not the $handle and $content need to be appended
  #            to the appropriate containers.
  #            This should only be set to false when the tab is already in
  #            the markup (as in, on initialization) (optional).
  # 
  # Return an instance of Tab.
  append: ($handle, $content, addToDOM = true) ->
    tab = new Tab $handle, $content
    @tabs.push tab
    
    # Tab events
    $handle.on "mousedown", => @show tab
    return tab

# Events:
# close - 
# move  - 
class Tab extends EventEmitter
  constructor: (@$handle, @$content) ->
    #{@draggable} = options
  
  # Close the tab, removing it from the DOM.
  # This emits the "close" event.
  close: ->
    @$handle.remove()
    @$content.remove()
    @emit "close"
  
  # Hide the tab's content.
  deselect: ->
    @$handle.removeClass "current"
    @$content.removeClass "current"
  
  # Show the tab's content. Note that this does *not* deselect whichever tab
  # is currently selected! You should use TabContainer#show(tab) instead.
  select: ->
    @$handle.addClass "current"
    @$content.addClass "current"

module.exports = ($el, options = {}) ->
  return new TabContainer $el, options

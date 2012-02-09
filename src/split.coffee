###
 resizable split view between 2 panes.

Given the markup (Jade):

  #splitme
    section: h1 Split A
    section: h1 Split B


  {split} = require 'stratus-ui'

Top/bottom split:

  split.tb $("#splitme")

Left/right split:

  split.lr $("#splitme")


###
{EventEmitter} = require 'events'


# Public: Split $el's 2 children left/right.
# 
# $el     - The root element.
# options - Extra options (optional).
#           size1, size2 - The default width of pane 1 or 2.
# 
# Return an instance of TBSplit.
exports.tb = tb = ($el, options = {}) ->
  new TBSplit $el, options


# Public: Split $el's 2 children left/right.
# 
# $el     - The root element.
# options - Extra options (optional).
#           size1, size2 - The default width of pane 1 or 2.
# 
# Return an instance of LRSplit.
exports.lr = lr = ($el, options = {}) ->
  new LRSplit $el, options


# Events:
# 
#   * resize
# 
class Split extends EventEmitter
  constructor: (@$root, options) ->
    @$pane1 = @$root.children(":first-child").addClass "split-1"
    @$pane2 = @$root.children(":last-child").addClass "split-2"
    {@max1, @max2,
     @size1, @size2} = options
    
    # Slider dragging.
    @$slider = $("<div/>", class: "split-slider #{@cssClass}")
      .insertAfter @$pane1
    @sliderSize = @$slider[@size]()
    @$slider.mousedown =>
      @dragging = true
      return false
    $("body").mousemove (event) =>
      @drag event if @dragging
    $("body").mouseup (event) =>
      if @dragging
        @dragging = false
        @drag event, true
    
    @initPosition()
  
  
  # Place the slider at the intial position.
  initPosition: ->
    fullSize = @fullSize()
    if @size1
      @position @size1 / fullSize
    else if @size2
      @position 1.0 - (@size2 / fullSize)
    else
      @position 0.5
  
  
  # Public: Get or set the slider position.
  # 
  # Examples
  # 
  #   # Reset the position.
  #   lr_split.position 0.5
  # 
  #   lr_split.position()
  #   # => 0.5
  # 
  # Return the width in pixels of the left side of the slider.
  position: (percent) ->
    return @lastPerc if _.isUndefined percent
    return if percent == @lastPerc
    percent   = 0.0 if percent < 0.0
    percent   = 1.0 if percent > 1.0
    @lastPerc = percent
    fullSize  = @fullSize()
    #pane1Size = Math.floor (fullSize * percent) - (@sliderSize/2.0)
    
    p1          = {}
    p1[@size]   = "#{percent*100}%"
    p1[@posEnd] = "auto"
    @$pane1.css p1
    
    p2            = {}
    p2[@size]     = "#{ (1.0 - percent - (@sliderSize / fullSize))*100 }%"
    p2[@posStart] = "auto"
    @$pane2.css p2
    
    s            = {}
    s[@other1]   = 0
    s[@other2]   = 0
    s[@posStart] = "#{percent*100}%"
    @$slider.css s
    
    @emit "resize"
  
  # Public: Refresh the positioning.
  # This needs to be called when the container's size is changed.
  # 
  # Returns nothing.
  refresh: ->
    @position @lastPerc
  
  # Position the slider based on an event.
  # 
  # resize - If true, perform the resize. Otherwise, just hint it (optional).
  # 
  # Returns nothing.
  drag: (event, resize = false) ->
    sliderPos = event[@eventPos] - @$root.offset()[@posStart]
    @_hideHint()
    if resize
      @position sliderPos / @fullSize()
    else
      pos            = {}
      fullSize       = @fullSize()
      pos[@posStart] = sliderPos / fullSize
      pos[@size]     = (@lastPerc - sliderPos / fullSize)
      
      if pos[@size] < 0
        pos[@posStart] = @lastPerc + @sliderSize / fullSize
        pos[@size]     = -pos[@size]
      
      pos[@posStart] = "#{pos[@posStart] * 100}%"
      pos[@size]     = "#{pos[@size] * 100}%"
      @_showHint pos
    return
  
  # Hide the semi-transparent hint box.
  _hideHint: ->
    $(".split-hint").remove()
  
  # Display the hint at the given position.
  _showHint: (pos) ->
    $("<div/>", class: "split-hint #{@cssClass}")
      .insertAfter(@$slider)
      .css(pos)
  
  # Return the width of the split container.
  fullSize: ->
    return @$root[@size]()


# |-------|-------|
# | Panel | Panel |
# |   1   |   2   |
# |-------|-------|
class LRSplit extends Split
  cssClass: "lr"
  size:     "width"
  posStart: "left"
  posEnd:   "right"
  other1:   "top"
  other2:   "bottom"
  eventPos: "pageX"
  

# |---------|
# | Panel 1 |
# |---------|
# | Panel 2 |
# |---------|
class TBSplit extends Split
  cssClass: "tb"
  size:     "height"
  posStart: "top"
  posEnd:   "bottom"
  other1:   "left"
  other2:   "right"
  eventPos: "pageY"



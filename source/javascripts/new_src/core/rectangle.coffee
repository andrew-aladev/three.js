# @author mr.doob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

class Rectangle
  constructor: ->
    @_isEmpty   = true
  
  resize: ->
    @_width   = @_right   - @_left
    @_height  = @_bottom  - @_top
  
  getX: ->
    @_left

  getY: ->
    @_top

  getWidth: ->
    @_width

  getHeight: ->
    @_height

  getLeft: ->
    @_left

  getTop: ->
    @_top

  getRight: ->
    @_right

  getBottom: ->
    @_bottom

  set: (left, top, right, bottom) ->
    @_isEmpty   = false
    @_left      = left
    @_top       = top
    @_right     = right
    @_bottom    = bottom
    @resize()

  addPoint: (x, y) ->
    if @_isEmpty
      @_isEmpty   = false
      @_left      = x
      @_top       = y
      @_right     = x
      @_bottom    = y
    else
      unless @_left < x
        @_left = x
      unless @_top < y
        @_top = y
      unless @_right > x
        @_right = x
      unless @_bottom > y
        @_bottom = y
    @resize()

  add3Points: (x1, y1, x2, y2, x3, y3) ->
    if @_isEmpty
      @_isEmpty   = false
      if x1 < x2
        if x1 < x3
          @_left = x1
        else
          @_left = x3
      else if x2 < x3
        @_left = x2
      else
        @_left = x3

      if y1 < y2
        if y1 < y3
          @_top = y1
         else
          @_top = y3
      else if y2 < y3
        @_top = y2
      else
        @_top = y3
      
      if x1 > x2
        if x1 > x3
          @_right = x1
        else
          @_right = x3
      else if x2 > x3
        @_right = x2
      else
        @_right = x3

      if y1 > y2
        if y1 > y3
          @_bottom = y1
        else
          @_bottom = y3
      else if y2 > y3
        @_bottom = y2
      else
        @_bottom = y3
 
    else
      if x1 < x2
        if x1 < x3
          if x1 < @_left
            @_left = x1
        else if x3 < @_left
          @_left = x3
      else if x2 < x3
        if x2 < @_left
          @_left = x2
      else if x3 < @_left
        @_left = x3
    
      if y1 < y2
        if y1 < y3
          if y1 < @_top
            @_top = y1
        else if y3 < @_top
          @_top = y3
      else if y2 < y3
        if y2 < @_top
          @_top = y2
      else if y3 < @_top
        @_top = y3
      
      if x1 > x2
        if x1 > x3
          if x1 > @_right
            @_right = x1
        else if x3 > @_right
          @_right = x3
      else if x2 > x3
        if x2 > @_right
          @_right = x2
      else if x3 > @_right
        @_right = x3

      if y1 > y2
        if y1 > y3
          if y1 > @_bottom
            @_bottom = y1
        else if y3 > @_bottom
          @_bottom = y3
      else if y2 > y3
        if y2 > @_bottom
          @_bottom = y2
      else if y3 > @_bottom
        @_bottom = y3
      
    @resize()

  addRectangle: (r) ->
    if @_isEmpty
      @_isEmpty = false
      @_left    = r.getLeft()
      @_top     = r.getTop()
      @_right   = r.getRight()
      @_bottom  = r.getBottom()
    else
      unless @_left < r.getLeft()
        @_left = r.getLeft()
      unless @_top < r.getTop()
        @_top = r.getTop()
      unless @_right > r.getRight()
        @_right = r.getRight()
      unless @_bottom > r.getBottom()
        @_bottom = r.getBottom()
    @resize()

  inflate: (v) ->
    @_left    -= v
    @_top     -= v
    @_right   += v
    @_bottom  += v
    @resize()

  minSelf: (r) ->
    unless @_left > r.getLeft()
      @_left = r.getLeft()
    unless @_top > r.getTop()
      @_top = r.getTop()
    unless @_right < r.getRight()
      @_right = r.getRight()
    unless @_bottom < r.getBottom()
      @_bottom  = r.getBottom()
    @resize()

  intersects: (r) ->
    # http://gamemath.com/2011/09/detecting-whether-two-boxes-overlap/
    return false if @_right   < r.getLeft()
    return false if @_left    > r.getRight()
    return false if @_bottom  < r.getTop()
    return false if @_top     > r.getBottom()
    true

  empty: ->
    @_isEmpty   = true
    @_left      = 0
    @_top       = 0
    @_right     = 0
    @_bottom    = 0
    @resize()

  isEmpty: ->
    @_isEmpty

namespace "THREE", (exports) ->
  exports.Rectangle = Rectangle
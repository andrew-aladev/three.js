# @author mr.doob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

class Rectangle
  constructor: ->
    @_left      = undefined
    @_top       = undefined
    @_right     = undefined
    @_bottom    = undefined
    @_width     = undefined
    @_height    = undefined
    @_isEmpty   = true
  
  resize: ->
    @_width   = @_right - @_left
    @_height  = @_bottom - @_top
  
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
      @_left    = (if @_left < x    then @_left else x)     # Math.min( _left, x )
      @_top     = (if @_top < y     then @_top else y)      # Math.min( _top, y )
      @_right   = (if @_right > x   then @_right else x)    # Math.max( _right, x )
      @_bottom  = (if @_bottom > y  then @_bottom else y)   # Math.max( _bottom, y )
    @resize()

  add3Points: (x1, y1, x2, y2, x3, y3) ->
    if @_isEmpty
      @_isEmpty   = false
      @_left      = (if x1 < x2 then (if x1 < x3 then x1 else x3) else (if x2 < x3 then x2 else x3))
      @_top       = (if y1 < y2 then (if y1 < y3 then y1 else y3) else (if y2 < y3 then y2 else y3))
      @_right     = (if x1 > x2 then (if x1 > x3 then x1 else x3) else (if x2 > x3 then x2 else x3))
      @_bottom    = (if y1 > y2 then (if y1 > y3 then y1 else y3) else (if y2 > y3 then y2 else y3))
    else
      @_left    = (if x1 < x2 then (if x1 < x3 then (if x1 < @_left   then x1 else @_left)    else (if x3 < @_left    then x3 else @_left))   else (if x2 < x3 then (if x2 < @_left   then x2 else @_left)    else (if x3 < @_left then x3   else @_left)))
      @_top     = (if y1 < y2 then (if y1 < y3 then (if y1 < @_top    then y1 else @_top)     else (if y3 < @_top     then y3 else @_top))    else (if y2 < y3 then (if y2 < @_top    then y2 else @_top)     else (if y3 < @_top then y3    else @_top)))
      @_right   = (if x1 > x2 then (if x1 > x3 then (if x1 > @_right  then x1 else @_right)   else (if x3 > @_right   then x3 else @_right))  else (if x2 > x3 then (if x2 > @_right  then x2 else @_right)   else (if x3 > @_right then x3  else @_right)))
      @_bottom  = (if y1 > y2 then (if y1 > y3 then (if y1 > @_bottom then y1 else @_bottom)  else (if y3 > @_bottom  then y3 else @_bottom)) else (if y2 > y3 then (if y2 > @_bottom then y2 else @_bottom)  else (if y3 > @_bottom then y3 else @_bottom)))
    @resize()

  addRectangle: (r) ->
    if @_isEmpty
      @_isEmpty = false
      @_left    = r.getLeft()
      @_top     = r.getTop()
      @_right   = r.getRight()
      @_bottom  = r.getBottom()
    else
      @_left    = (if @_left < r.getLeft()      then @_left else r.getLeft())       # Math.min(_left, r.getLeft() )
      @_top     = (if @_top < r.getTop()        then @_top else r.getTop())         # Math.min(_top, r.getTop() )
      @_right   = (if @_right > r.getRight()    then @_right else r.getRight())     # Math.max(_right, r.getRight() )
      @_bottom  = (if @_bottom > r.getBottom()  then @_bottom else r.getBottom())   # Math.max(_bottom, r.getBottom() )
    @resize()

  inflate: (v) ->
    @_left    -= v
    @_top     -= v
    @_right   += v
    @_bottom  += v
    @resize()

  minSelf: (r) ->
    @_left    = (if @_left > r.getLeft()      then @_left else r.getLeft())       # Math.max( _left, r.getLeft() )
    @_top     = (if @_top > r.getTop()        then @_top else r.getTop())         # Math.max( _top, r.getTop() )
    @_right   = (if @_right < r.getRight()    then @_right else r.getRight())     # Math.min( _right, r.getRight() )
    @_bottom  = (if @_bottom < r.getBottom()  then @_bottom else r.getBottom())   # Math.min( _bottom, r.getBottom() )
    @resize()

  intersects: (r) ->
    # http://gamemath.com/2011/09/detecting-whether-two-boxes-overlap/
    return false  if @_right < r.getLeft()
    return false  if @_left > r.getRight()
    return false  if @_bottom < r.getTop()
    return false  if @_top > r.getBottom()
    true

  empty = ->
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
# @author mr.doob / http://mrdoob.com/
# @autor aladjev.andrew@gmail.com

class window.Three::Rectangle
  contructor: ->
    @left     = 0
    @top      = 0
    @right    = 0
    @bottom   = 0
    @width    = 0
    @height   = 0
    @is_empty = true

  resize: ->
    @width  = @right  - @left
    @height = @bottom - @top
    
  get_x: ->
    @left

  get_y: ->
    @top

  get_width: ->
    @width

  get_height: ->
    @height

  get_left: ->
    @left

  get_top: ->
    @top

  get_right: ->
    @right

  get_bottom: ->
    @bottom

  set: (left, top, right, bottom) ->
    @is_empty = false
    @left     = left
    @top      = top
    @right    = right
    @bottom   = bottom
    @resize()

  add_point: (x, y) ->
    if @is_empty
      @is_empty = false
      @left     = x
      @top      = y
      @right    = x
      @bottom   = y
      @resize()
    else
      @left     = x if @left > x
      @top      = y if @top > y
      @right    = x if @right < x
      @bottom   = y if @bottom < y
      @resize()

  add_3_points: (x1, y1, x2, y2, x3, y3) ->
    if @is_empty
      @is_empty = false
      
      if x1 < x2
        if x1 < x3
          @left = x1
        else
          @left = x3
      else
        if x2 < x3
          @left = x2
        else
          @left = x3
          
      if y1 < y2
        if y1 < y3
          @top = y1
        else
          @top = y3 
      else
        if y2 < y3
          @top = y2
        else
          @top = y3

      if x1 > x2
        if x1 > x3
          @right = x1
        else
          @right = x3
      else
        if x2 > x3
          @right = x2
        else
          @right = x3

      if y1 > y2
        if y1 > y3
          @bottom = y1
        else
          @bottom = y3
      else
        if y2 > y3
          @bottom = y2
        else
          @bottom = y3
      @resize()
    else
      if x1 < x2
        if x1 < x3 and x1 < @left
          @left = x1
        else if x3 < @left
          @left = x3
      else
        if x2 < x3 and x2 < @left
          @left = x2
        else if x3 < @left
          @left = x3
          
      if y1 < y2
        if y1 < y3 and y1 < @top
          @top = y1
        else if y3 < @top
          @top = y3
      else
        if y2 < y3 and y2 < @top
          @top = y2
        else if y3 < @top
          @top = y3
    
      if x1 > x2
        if x1 > x3 and x1 > @right
          @right = x1
        else if x3 > @right
          @right = x3
      else
        if x2 > x3 and x2 > @right
          @right = x2
        else if x3 > @right
          @right = x3
      
      if y1 > y2
        if y1 > y3 and y1 > @bottom
          @bottom = y1
        else if y3 > @bottom
          @bottom = y3
      else
        if y2 > y3 and y2 > @bottom
          @bottom = y2
        else if y3 > @bottom
          @bottom = y3
      
      @resize()

  add_rectangle: (r) ->
    if @is_empty
      @is_empty  = false
      @left     = r.get_left()
      @top      = r.get_top()
      @right    = r.get_right()
      @bottom   = r.get_bottom()
      @resize()
    else
      @left     = r.get_left()    if @left    > r.get_left()
      @top      = r.get_top()     if @top     > r.get_top()
      @right    = r.get_right()   if @right   < r.get_right()
      @bottom   = r.get_bottom()  if @bottom  < r.get_bottom()
      @resize()

  inflate: (v) ->
    @left   -= v
    @top    -= v
    @right  += v
    @bottom += v
    @resize()

  min_self: (r) ->
    @left     = r.get_left()    if @left    > r.get_left()
    @top      = r.get_top()     if @top     > r.get_top()
    @right    = r.get_right()   if @right   < r.get_right()
    @bottom   = r.get_bottom()  if @bottom  < r.get_bottom()
    @resize()

  intersects: (r) ->
    # http://gamemath.com/2011/09/detecting-whether-two-boxes-overlap/
    return false  if @right   < r.get_left()
    return false  if @left    > r.get_right()
    return false  if @bottom  < r.get_top()
    return false  if @top     > r.get_bottom()
    true

  empty: ->
    @is_empty = true
    @left     = 0
    @top      = 0
    @right    = 0
    @bottom   = 0
    @resize()

  is_empty: ->
    @is_empty
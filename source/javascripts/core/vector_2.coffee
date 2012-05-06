# @author mr.doob / http://mrdoob.com/
# @author philogb / http://blog.thejit.org/
# @author egraether / http://egraether.com/
# @author zz85 / http://www.lab4games.net/zz85/blog
# @autor aladjev.andrew@gmail.com

class window.Three.Vector2 extends window.Three
  constructor: (x, y) ->
    @x = x || 0
    @y = y || 0
  
  set: (x, y) ->
    @x = x
    @y = y
    return @
    
  copy: (v) ->
    @x = v.x
    @y = v.y
    return @
    
  add: (a, b) ->
    @x = a.x + b.x
    @y = a.y + b.y
    return @
    
  add_self: (v) ->
    @x += v.x
    @y += v.y
    return @
    
  sub: (a, b) ->
    @x = a.x - b.x
    @y = a.y - b.y
    return @
    
  sub_self: (v) ->
    @x -= v.x
    @y -= v.y
    return @
    
  multiply_scalar: (s) ->
    @x *= s
    @y *= s
    return @

  divide_scalar: (s) ->
    if s
      @x /= s
      @y /= s
    else
      @set(0, 0)

    return @
    
  negate: ->
    @multiply_scalar -1

  dot: (v) ->
    @x * v.x + @y * v.y
     
  length_sq: ->
    @x * @x + @y + @y
     
  length: ->
    Math.sqrt @length_sq()

  normalize: ->
    @divide_scalar @length()

  distance_to: (v) ->
    Math.sqrt @distance_to_squared v
     
  distance_to_squared: (v) ->
    dx = @x - v.x
    dy = @y - v.y
    dx * dx + dy * dy
     
  set_length: (length) ->
    @normalize().multiply_scalar length

  lerp_self: (v, alpha) ->
    @x += (v.x - @x) * alpha
    @y += (v.y - @y) * alpha
    return @
    
  equals: (v) ->
    v.x is @x and v.y is @y

  is_zero: ->
    @length_sq() < 0.0001

  clone: ->
    new Three.Vector2 @x, @y
# @author supereggbert / http://www.paulbrunt.co.uk/
# @author philogb / http://blog.thejit.org/
# @author mikael emtinger / http://gomo.se/
# @author egraether / http://egraether.com/
# @autor aladjev.andrew@gmail.com

class window.Three::Vector4
  constructor: (x, y, z, w) ->
    @x = x or 0
    @y = y or 0
    @z = z or 0
    @w = w or 1
  
  set: (x, y, z, w) ->
    @x = x
    @y = y
    @z = z
    @w = w or 1
    this

  copy: (v) ->
    @x = v.x
    @y = v.y
    @z = v.z
    @w = v.w or 1
    this

  add: (a, b) ->
    @x = a.x + b.x
    @y = a.y + b.y
    @z = a.z + b.z
    @w = a.w + b.w
    this

  add_self: (v) ->
    @x += v.x
    @y += v.y
    @z += v.z
    @w += v.w
    this

  sub: (a, b) ->
    @x = a.x - b.x
    @y = a.y - b.y
    @z = a.z - b.z
    @w = a.w - b.w
    this

  sub_self: (v) ->
    @x -= v.x
    @y -= v.y
    @z -= v.z
    @w -= v.w
    this

  multiply_scalar: (s) ->
    @x *= s
    @y *= s
    @z *= s
    @w *= s
    this

  divide_scalar: (s) ->
    if s
      @x /= s
      @y /= s
      @z /= s
      @w /= s
    else
      @x = 0
      @y = 0
      @z = 0
      @w = 1
    this

  negate: ->
    @multiply_scalar -1

  dot: (v) ->
    @x * v.x + @y * v.y + @z * v.z + @w * v.w

  length_sq: ->
    @dot this

  length: ->
    Math.sqrt @length_sq()

  normalize: ->
    @divide_scalar @length()

  set_length: (l) ->
    @normalize().multiply_scalar l

  lerp_self: (v, alpha) ->
    @x += (v.x - @x) * alpha
    @y += (v.y - @y) * alpha
    @z += (v.z - @z) * alpha
    @w += (v.w - @w) * alpha
    this

  clone: ->
    new Three::Vector4(@x, @y, @z, @w)
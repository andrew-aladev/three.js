# @author supereggbert / http://www.paulbrunt.co.uk/
# @author philogb / http://blog.thejit.org/
# @author mikael emtinger / http://gomo.se/
# @author egraether / http://egraether.com/
# @author aladjev.andrew@gmail.com

class Vector4
  constructor: (x, y, z, w) ->
    @x = x or 0
    @y = y or 0
    @z = z or 0
    @w = (if (w isnt `undefined`) then w else 1)

  set: (x, y, z, w) ->
    @x = x
    @y = y
    @z = z
    @w = w
    this

  copy: (v) ->
    @x = v.x
    @y = v.y
    @z = v.z
    @w = (if (v.w isnt `undefined`) then v.w else 1)
    this

  add: (a, b) ->
    @x = a.x + b.x
    @y = a.y + b.y
    @z = a.z + b.z
    @w = a.w + b.w
    this

  addSelf: (v) ->
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

  subSelf: (v) ->
    @x -= v.x
    @y -= v.y
    @z -= v.z
    @w -= v.w
    this

  multiplyScalar: (s) ->
    @x *= s
    @y *= s
    @z *= s
    @w *= s
    this

  divideScalar: (s) ->
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
    @multiplyScalar -1

  dot: (v) ->
    @x * v.x + @y * v.y + @z * v.z + @w * v.w

  lengthSq: ->
    @dot this

  length: ->
    Math.sqrt @lengthSq()

  normalize: ->
    @divideScalar @length()

  setLength: (l) ->
    @normalize().multiplyScalar l

  lerpSelf: (v, alpha) ->
    @x += (v.x - @x) * alpha
    @y += (v.y - @y) * alpha
    @z += (v.z - @z) * alpha
    @w += (v.w - @w) * alpha
    this

  clone: ->
    new THREE.Vector4(@x, @y, @z, @w)
    
namespace "THREE", (exports) ->
  exports.Vector4 = Vector4
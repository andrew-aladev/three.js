# @author mr.doob / http://mrdoob.com/
# @author philogb / http://blog.thejit.org/
# @author egraether / http://egraether.com/
# @author zz85 / http://www.lab4games.net/zz85/blog
# @author aladjev.andrew@gmail.com

class Vector2
  constructor: (x, y) ->
    @x = x or 0
    @y = y or 0

  set: (x, y) ->
    @x = x
    @y = y
    this

  copy: (v) ->
    @x = v.x
    @y = v.y
    this

  add: (a, b) ->
    @x = a.x + b.x
    @y = a.y + b.y
    this

  addSelf: (v) ->
    @x += v.x
    @y += v.y
    this

  sub: (a, b) ->
    @x = a.x - b.x
    @y = a.y - b.y
    this

  subSelf: (v) ->
    @x -= v.x
    @y -= v.y
    this

  multiplyScalar: (s) ->
    @x *= s
    @y *= s
    this

  divideScalar: (s) ->
    if s
      @x /= s
      @y /= s
    else
      @set 0, 0
    this

  negate: ->
    @multiplyScalar -1

  dot: (v) ->
    @x * v.x + @y * v.y

  lengthSq: ->
    @x * @x + @y * @y

  length: ->
    Math.sqrt @lengthSq()

  normalize: ->
    @divideScalar @length()

  distanceTo: (v) ->
    Math.sqrt @distanceToSquared(v)

  distanceToSquared: (v) ->
    dx = @x - v.x
    dy = @y - v.y
    dx * dx + dy * dy

  setLength: (l) ->
    @normalize().multiplyScalar l

  lerpSelf: (v, alpha) ->
    @x += (v.x - @x) * alpha
    @y += (v.y - @y) * alpha
    this

  equals: (v) ->
    (v.x is @x) and (v.y is @y)

  isZero: ->
    @lengthSq() < 0.0001

  clone: ->
    new Vector2 @x, @y
    
namespace "THREE", (exports) ->
  exports.Vector2 = Vector2
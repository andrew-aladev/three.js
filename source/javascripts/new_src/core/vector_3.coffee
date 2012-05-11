# @author mr.doob / http://mrdoob.com/
# @author kile / http://kile.stravaganza.org/
# @author philogb / http://blog.thejit.org/
# @author mikael emtinger / http://gomo.se/
# @author egraether / http://egraether.com/
# @author aladjev.andrew@gmail.com

class Vector3
  constructor: (x, y, z) ->
    @x = x or 0
    @y = y or 0
    @z = z or 0

  set: (x, y, z) ->
    @x = x
    @y = y
    @z = z
    this

  setX: (x) ->
    @x = x
    this

  setY: (y) ->
    @y = y
    this

  setZ: (z) ->
    @z = z
    this

  copy: (v) ->
    @x = v.x
    @y = v.y
    @z = v.z
    this

  add: (a, b) ->
    @x = a.x + b.x
    @y = a.y + b.y
    @z = a.z + b.z
    this

  addSelf: (v) ->
    @x += v.x
    @y += v.y
    @z += v.z
    this

  addScalar: (s) ->
    @x += s
    @y += s
    @z += s
    this

  sub: (a, b) ->
    @x = a.x - b.x
    @y = a.y - b.y
    @z = a.z - b.z
    this

  subSelf: (v) ->
    @x -= v.x
    @y -= v.y
    @z -= v.z
    this

  multiply: (a, b) ->
    @x = a.x * b.x
    @y = a.y * b.y
    @z = a.z * b.z
    this

  multiplySelf: (v) ->
    @x *= v.x
    @y *= v.y
    @z *= v.z
    this

  multiplyScalar: (s) ->
    @x *= s
    @y *= s
    @z *= s
    this

  divideSelf: (v) ->
    @x /= v.x
    @y /= v.y
    @z /= v.z
    this

  divideScalar: (s) ->
    if s
      @x /= s
      @y /= s
      @z /= s
    else
      @x = 0
      @y = 0
      @z = 0
    this

  negate: ->
    @multiplyScalar -1

  dot: (v) ->
    @x * v.x + @y * v.y + @z * v.z

  lengthSq: ->
    @x * @x + @y * @y + @z * @z

  length: ->
    Math.sqrt @lengthSq()

  lengthManhattan: ->
    Math.abs(@x) + Math.abs(@y) + Math.abs(@z)

  normalize: ->
    @divideScalar @length()

  setLength: (l) ->
    @normalize().multiplyScalar l

  lerpSelf: (v, alpha) ->
    @x += (v.x - @x) * alpha
    @y += (v.y - @y) * alpha
    @z += (v.z - @z) * alpha
    this

  cross: (a, b) ->
    @x = a.y * b.z - a.z * b.y
    @y = a.z * b.x - a.x * b.z
    @z = a.x * b.y - a.y * b.x
    this

  crossSelf: (v) ->
    x = @x
    y = @y
    z = @z
    @x = y * v.z - z * v.y
    @y = z * v.x - x * v.z
    @z = x * v.y - y * v.x
    this

  distanceTo: (v) ->
    Math.sqrt @distanceToSquared(v)

  distanceToSquared: (v) ->
    new THREE.Vector3().sub(this, v).lengthSq()

  getPositionFromMatrix: (m) ->
    @x = m.elements[12]
    @y = m.elements[13]
    @z = m.elements[14]
    this

  getRotationFromMatrix: (m, scale) ->
    sx = (if scale then scale.x else 1)
    sy = (if scale then scale.y else 1)
    sz = (if scale then scale.z else 1)
    m11 = m.elements[0] / sx
    m12 = m.elements[4] / sy
    m13 = m.elements[8] / sz
    m21 = m.elements[1] / sx
    m22 = m.elements[5] / sy
    m23 = m.elements[9] / sz
    m33 = m.elements[10] / sz
    @y = Math.asin(m13)
    cosY = Math.cos(@y)
    if Math.abs(cosY) > 0.00001
      @x = Math.atan2(-m23 / cosY, m33 / cosY)
      @z = Math.atan2(-m12 / cosY, m11 / cosY)
    else
      @x = 0
      @z = Math.atan2(m21, m22)
    this

  getScaleFromMatrix: (m) ->
    sx = @set(m.elements[0], m.elements[1], m.elements[2]).length()
    sy = @set(m.elements[4], m.elements[5], m.elements[6]).length()
    sz = @set(m.elements[8], m.elements[9], m.elements[10]).length()
    @x = sx
    @y = sy
    @z = sz

  equals: (v) ->
    (v.x is @x) and (v.y is @y) and (v.z is @z)

  isZero: ->
    @lengthSq() < 0.0001 # almostZero

  clone: ->
    new THREE.Vector3(@x, @y, @z)
    
namespace "THREE", (exports) ->
  exports.Vector3 = Vector3
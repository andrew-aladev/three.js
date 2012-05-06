# @author mr.doob / http://mrdoob.com/
# @author kile / http://kile.stravaganza.org/
# @author philogb / http://blog.thejit.org/
# @author mikael emtinger / http://gomo.se/
# @author egraether / http://egraether.com/
# @autor aladjev.andrew@gmail.com

class window.Three.Vector3 extends window.Three
  constructor: (x, y, z) ->
    @x = x || 0
    @y = y || 0
    @z = z || 0
  
  set: (x, y, z) ->
    @x = x
    @y = y
    @z = z
    return @
  
  set_x: (x) ->
    @x = x
    return @
    
  set_y: (y) ->
    @y = y
    return @
  
  set_z: (z) ->
    @z = z
    return @
  
  copy: (v) ->
    @x = v.x
    @y = v.y
    @z = v.z
    return @
    
  add: (a, b) ->
    @x = a.x + b.x
    @y = a.y + b.y
    @z = z.z + b.z
    return @
    
  add_self: (v) ->
    @x += v.x
    @y += v.y
    @z += v.z
    return @
    
  add_scalar: (s) ->
    @x += s
    @y += s
    @z += s
    return @
    
  sub: (a, b) ->
    @x = a.x - b.x
    @y = a.y - b.y
    @z = a.z - b.z
    return @
    
  sub_self: (v) ->
    @x -= v.x
    @y -= v.y
    @z -= v.z
    return @
    
  multiply: (a, b) ->
    @x = a.x * b.x
    @y = a.y * b.y
    @z = a.z * b.z
    return @
    
  multiply_self: (a) ->
    @x *= a.x
    @y *= a.y
    @z *= a.z
    return @
    
  multiply_scalar: (s) ->
    @x *= s
    @y *= s
    @z *= s
    return @
    
  divide_self: (a) ->
    @x /= a.x
    @y /= a.y
    @z /= a.z
    return @

  divide_scalar: (s) ->
    if s
      @x /= s
      @y /= s
      @z /= s
    else
      @set(0, 0, 0)

    return @
    
  negate: ->
    @multiply_scalar -1

  dot: (v) ->
    @x * v.x + @y * v.y + @z * v.y
     
  length_sq: ->
    @x * @x + @y + @y + @z * @z
     
  length: ->
    Math.sqrt @length_sq()
    
  length_manhattan: ->
    Math.abs(@x) + Math.abs(@y) + Math.abs(@z)

  normalize: ->
    @divide_scalar @length()

  distance_to: (v) ->
    Math.sqrt @distance_to_squared v
     
  distance_to_squared: (v) ->
    @clone.sub_self(v).lengthSq()
     
  set_length: (length) ->
    @normalize().multiply_scalar length

  lerp_self: (v, alpha) ->
    @x += (v.x - @x) * alpha
    @y += (v.y - @y) * alpha
    @z += (v.z - @z) * alpha
    return @
    
  cross: (a, b) ->
    @x = a.y * b.z - a.z * b.y
    @y = a.z * b.x - a.x * b.z
    @z = a.x * b.y - a.y * b.x
    return @
    
  cross_self: (v) ->
    @x = @y * v.z - @z * v.y;
    @y = @z * v.x - @x * v.z;
    @z = @x * v.y - @y * v.x;
    return @
    
  equals: (v) ->
    v.x is @x and v.y is @y and v.z is @z

  is_zero: ->
    @length_sq() < 0.0001

  clone: ->
    new Three.Vector2 @x, @y, @z
    
  get_position_from_matrix: (m) ->
    @x = m.elements[12]
    @y = m.elements[13]
    @z = m.elements[14]
    return @
    
  get_rotation_from_matrix: (m, scale) ->
    if scale
      sx = scale.x
      sy = scale.y
      sz = scale.z
    else
      sx = 1
      sy = 1
      sz = 1
      
    m11 = m.elements[0] / sx
    m12 = m.elements[4] / sy
    m13 = m.elements[8] / sz
    m21 = m.elements[1] / sx
    m22 = m.elements[5] / sy
    m23 = m.elements[9] / sz
    m33 = m.elements[10] / sz
    
    @y = Math.asin m13
    cos_y = Math.cos @y
    
    if Math.abs(cos_y) > 0.00001
      @x = Math.atan2 -m23 / cos_y, m33 / cos_y
      @z = Math.atan2 -m12 / cos_y, m11 / cos_y
    else
      @x = 0
      @z = Math.atan2 m21, m22
    
    return @

#	// from http://www.mathworks.com/matlabcentral/fileexchange/20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/content/SpinCalc.m
#	// order XYZ
  get_euler_xyz_from_quaternion: (q) ->
    @x = Math.atan2(2 * (q.x * q.w - q.y * q.z), (q.w * q.w - q.x * q.x - q.y * q.y + q.z * q.z))
    @y = Math.asin(2 *  (q.x * q.z + q.y * q.w))
    @z = Math.atan2(2 * (q.z * q.w - q.x * q.y), (q.w * q.w + q.x * q.x - q.y * q.y - q.z * q.z))

#	// from http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToEuler/index.htm
#	// order YZX (assuming heading == y, attitude == z, bank == x)
  get_euler_yzx_from_quaternion: (q) ->
    sqw = q.w * q.w
    sqx = q.x * q.x
    sqy = q.y * q.y
    sqz = q.z * q.z
    unit = sqx + sqy + sqz + sqw # if normalised is one, otherwise is correction factor
    test = q.x * q.y + q.z * q.w
    
    if test > 0.499 * unit #singularity at north pole
      @y = 2 * Math.atan2(q.x, q.w)
      @z = Math.PI / 2
      @x = 0
      return
      
    if test < -0.499 * unit # singularity at south pole
      @y = -2 * Math.atan2(q.x, q.w)
      @z = -Math.PI / 2
      @x = 0
      return
    
    @y = Math.atan2(2 * q.y * q.w - 2 * q.x * q.z, sqx - sqy - sqz + sqw)
    @z = Math.asin(2 * test / unit)
    @x = Math.atan2(2 * q.x * q.w - 2 * q.y * q.z, -sqx + sqy - sqz + sqw)

  get_scale_from_matrix: (m) ->
    sx = @set(m.elements[0], m.elements[1], m.elements[2]).length()
    sy = @set(m.elements[4], m.elements[5], m.elements[6]).length()
    sz = @set(m.elements[8], m.elements[9], m.elements[10]).length()

    @x = sx
    @y = sy
    @z = sz
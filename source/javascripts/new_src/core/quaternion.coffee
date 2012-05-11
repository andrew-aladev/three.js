# @author mikael emtinger / http://gomo.se/
# @author alteredq / http://alteredqualia.com/


class Quaternion
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

  copy: (q) ->
    @x = q.x
    @y = q.y
    @z = q.z
    @w = q.w
    this

  setFromEuler: (vector) ->
    c = Math.PI / 360 # 0.5 * Math.PI / 360, // 0.5 is an optimization
    x = vector.x * c
    y = vector.y * c
    z = vector.z * c
    c1 = Math.cos(y)
    s1 = Math.sin(y)
    c2 = Math.cos(-z)
    s2 = Math.sin(-z)
    c3 = Math.cos(x)
    s3 = Math.sin(x)
    c1c2 = c1 * c2
    s1s2 = s1 * s2
    @w = c1c2 * c3 - s1s2 * s3
    @x = c1c2 * s3 + s1s2 * c3
    @y = s1 * c2 * c3 + c1 * s2 * s3
    @z = c1 * s2 * c3 - s1 * c2 * s3
    this

  setFromAxisAngle: (axis, angle) ->
    # from http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToQuaternion/index.htm
    # axis have to be normalized
   
    halfAngle = angle / 2
    s = Math.sin(halfAngle)
    @x = axis.x * s
    @y = axis.y * s
    @z = axis.z * s
    @w = Math.cos(halfAngle)
    this

  setFromRotationMatrix: (m) ->
    # Adapted from: http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
  
    copySign = (a, b) ->
      (if b < 0 then -Math.abs(a) else Math.abs(a))
    absQ = Math.pow(m.determinant(), 1.0 / 3.0)
    @w = Math.sqrt(Math.max(0, absQ + m.elements[0] + m.elements[5] + m.elements[10])) / 2
    @x = Math.sqrt(Math.max(0, absQ + m.elements[0] - m.elements[5] - m.elements[10])) / 2
    @y = Math.sqrt(Math.max(0, absQ - m.elements[0] + m.elements[5] - m.elements[10])) / 2
    @z = Math.sqrt(Math.max(0, absQ - m.elements[0] - m.elements[5] + m.elements[10])) / 2
    @x = copySign(@x, (m.elements[6] - m.elements[9]))
    @y = copySign(@y, (m.elements[8] - m.elements[2]))
    @z = copySign(@z, (m.elements[1] - m.elements[4]))
    @normalize()
    this

  calculateW: ->
    @w = -Math.sqrt(Math.abs(1.0 - @x * @x - @y * @y - @z * @z))
    this

  inverse: ->
    @x *= -1
    @y *= -1
    @z *= -1
    this

  length: ->
    Math.sqrt @x * @x + @y * @y + @z * @z + @w * @w

  normalize: ->
    l = Math.sqrt(@x * @x + @y * @y + @z * @z + @w * @w)
    if l is 0
      @x = 0
      @y = 0
      @z = 0
      @w = 0
    else
      l = 1 / l
      @x = @x * l
      @y = @y * l
      @z = @z * l
      @w = @w * l
    this

  multiply: (a, b) ->
    # from http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/code/index.htm
  
    @x = a.x * b.w + a.y * b.z - a.z * b.y + a.w * b.x
    @y = -a.x * b.z + a.y * b.w + a.z * b.x + a.w * b.y
    @z = a.x * b.y - a.y * b.x + a.z * b.w + a.w * b.z
    @w = -a.x * b.x - a.y * b.y - a.z * b.z + a.w * b.w
    this

  multiplySelf: (b) ->
    qax = @x
    qay = @y
    qaz = @z
    qaw = @w
    qbx = b.x
    qby = b.y
    qbz = b.z
    qbw = b.w
    @x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby
    @y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz
    @z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx
    @w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz
    this

  multiplyVector3: (vector, dest) ->
    dest = vector  unless dest
    x = vector.x
    y = vector.y
    z = vector.z
    qx = @x
    qy = @y
    qz = @z
    qw = @w
    
    # calculate quat * vector
    ix = qw * x + qy * z - qz * y
    iy = qw * y + qz * x - qx * z
    iz = qw * z + qx * y - qy * x
    iw = -qx * x - qy * y - qz * z
    
    # calculate result * inverse quat
    dest.x = ix * qw + iw * -qx + iy * -qz - iz * -qy
    dest.y = iy * qw + iw * -qy + iz * -qx - ix * -qz
    dest.z = iz * qw + iw * -qz + ix * -qy - iy * -qx
    dest

  clone: ->
    new THREE.Quaternion(@x, @y, @z, @w)

  @slerp = (qa, qb, qm, t) ->
    # http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/
    
    cosHalfTheta = qa.w * qb.w + qa.x * qb.x + qa.y * qb.y + qa.z * qb.z
    if cosHalfTheta < 0
      qm.w = -qb.w
      qm.x = -qb.x
      qm.y = -qb.y
      qm.z = -qb.z
      cosHalfTheta = -cosHalfTheta
    else
      qm.copy qb
    if Math.abs(cosHalfTheta) >= 1.0
      qm.w = qa.w
      qm.x = qa.x
      qm.y = qa.y
      qm.z = qa.z
      return qm
    halfTheta = Math.acos(cosHalfTheta)
    sinHalfTheta = Math.sqrt(1.0 - cosHalfTheta * cosHalfTheta)
    if Math.abs(sinHalfTheta) < 0.001
      qm.w = 0.5 * (qa.w + qb.w)
      qm.x = 0.5 * (qa.x + qb.x)
      qm.y = 0.5 * (qa.y + qb.y)
      qm.z = 0.5 * (qa.z + qb.z)
      return qm
    ratioA = Math.sin((1 - t) * halfTheta) / sinHalfTheta
    ratioB = Math.sin(t * halfTheta) / sinHalfTheta
    qm.w = (qa.w * ratioA + qm.w * ratioB)
    qm.x = (qa.x * ratioA + qm.x * ratioB)
    qm.y = (qa.y * ratioA + qm.y * ratioB)
    qm.z = (qa.z * ratioA + qm.z * ratioB)
    qm
    
namespace "THREE", (exports) ->
  exports.Quaternion = Quaternion
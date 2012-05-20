# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class Matrix3
  constructor: ->
    @elements = new Float32Array(9)

  getInverse: (matrix) ->
    # input: THREE.Matrix4
    # based on http://code.google.com/p/webgl-mjs/
  
    me  = matrix.elements
    a11 = me[10] * me[5] - me[6] * me[9]
    a21 = -me[10] * me[1] + me[2] * me[9]
    a31 = me[6] * me[1] - me[2] * me[5]
    a12 = -me[10] * me[4] + me[6] * me[8]
    a22 = me[10] * me[0] - me[2] * me[8]
    a32 = -me[6] * me[0] + me[2] * me[4]
    a13 = me[9] * me[4] - me[5] * me[8]
    a23 = -me[9] * me[0] + me[1] * me[8]
    a33 = me[5] * me[0] - me[1] * me[4]
    det = me[0] * a11 + me[1] * a12 + me[2] * a13
    console.warn "Matrix3.getInverse(): determinant == 0" if det is 0
    idet = 1.0 / det
    
    m     = @elements
    m[0]  = idet * a11
    m[1]  = idet * a21
    m[2]  = idet * a31
    m[3]  = idet * a12
    m[4]  = idet * a22
    m[5]  = idet * a32
    m[6]  = idet * a13
    m[7]  = idet * a23
    m[8]  = idet * a33
    this

  transpose: ->
    tmp   = undefined
    m     = @elements
    tmp   = m[1]
    m[1]  = m[3]
    m[3]  = tmp
    tmp   = m[2]
    m[2]  = m[6]
    m[6]  = tmp
    tmp   = m[5]
    m[5]  = m[7]
    m[7]  = tmp
    this

  transposeIntoArray: (r) ->
    m     = @m
    r[0]  = m[0]
    r[1]  = m[3]
    r[2]  = m[6]
    r[3]  = m[1]
    r[4]  = m[4]
    r[5]  = m[7]
    r[6]  = m[2]
    r[7]  = m[5]
    r[8]  = m[8]
    this
    
namespace "THREE", (exports) ->
  exports.Matrix3 = Matrix3
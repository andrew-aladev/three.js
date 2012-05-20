# @author mr.doob / http://mrdoob.com/
# @author mikael emtinger / http://gomo.se/
# @author aladjev.andrew@gmail.com

#= require new_src/core/object_3d
#= require new_src/core/matrix_4

class Camera extends THREE.Object3D
  constructor: ->
    super()
    @matrixWorldInverse       = new THREE.Matrix4()
    @projectionMatrix         = new THREE.Matrix4()
    @projectionMatrixInverse  = new THREE.Matrix4()

  lookAt: (vector) ->
    @matrix.lookAt @position, vector, @up
    @rotation.getRotationFromMatrix @matrix if @rotationAutoUpdate
    
namespace "THREE", (exports) ->
  exports.Camera = Camera
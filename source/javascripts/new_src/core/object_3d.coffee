# @author mr.doob / http://mrdoob.com/
# @author mikael emtinger / http://gomo.se/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class Object3D
  constructor: ->
    @id           = THREE.Object3DCount++
    @name         = ""
    @parent       = `undefined`
    @children     = []
    @up           = new THREE.Vector3(0, 1, 0)
    @position     = new THREE.Vector3()
    @rotation     = new THREE.Vector3()
    @eulerOrder   = "XYZ"
    @scale        = new THREE.Vector3(1, 1, 1)
    @doubleSided  = false
    @flipSided    = false
    @renderDepth  = null
    @rotationAutoUpdate = true
    
    @matrix                 = new THREE.Matrix4()
    @matrixWorld            = new THREE.Matrix4()
    @matrixRotationWorld    = new THREE.Matrix4()
    @matrixAutoUpdate       = true
    @matrixWorldNeedsUpdate = true
    @quaternion         = new THREE.Quaternion()
    @useQuaternion      = false
    @boundRadius        = 0.0
    @boundRadiusScale   = 1.0
    @visible            = true
    @castShadow         = false
    @receiveShadow      = false
    @frustumCulled      = true
    @_vector            = new THREE.Vector3()

  applyMatrix: (matrix) ->
    @matrix.multiply matrix, @matrix
    @scale.getScaleFromMatrix @matrix
    @rotation.getRotationFromMatrix @matrix, @scale
    @position.getPositionFromMatrix @matrix

  translate: (distance, axis) ->
    @matrix.rotateAxis axis
    @position.addSelf axis.multiplyScalar(distance)

  translateX: (distance) ->
    @translate distance, @_vector.set(1, 0, 0)

  translateY: (distance) ->
    @translate distance, @_vector.set(0, 1, 0)

  translateZ: (distance) ->
    @translate distance, @_vector.set(0, 0, 1)

  lookAt: (vector) ->
    # TODO: Add hierarchy support
    @matrix.lookAt vector, @position, @up
    @rotation.getRotationFromMatrix @matrix  if @rotationAutoUpdate

  add: (object) ->
    if object is this
      console.warn "THREE.Object3D.add: An object can't be added as a child of itself."
      return
    if object instanceof THREE.Object3D
      object.parent.remove object  if object.parent isnt `undefined`
      object.parent = this
      @children.push object
      
      # add to scene
      scene = this
      scene = scene.parent  while scene.parent isnt `undefined`
      scene.__addObject object  if scene isnt `undefined` and scene instanceof THREE.Scene

  remove: (object) ->
    index = @children.indexOf(object)
    if index isnt -1
      object.parent = `undefined`
      @children.splice index, 1
      
      # remove from scene
      scene = this
      scene = scene.parent  while scene.parent isnt `undefined`
      scene.__removeObject object  if scene isnt `undefined` and scene instanceof THREE.Scene

  getChildByName: (name, recursive) ->
    c = undefined
    cl = undefined
    child = undefined
    c = 0
    cl = @children.length

    while c < cl
      child = @children[c]
      return child  if child.name is name
      if recursive
        child = child.getChildByName(name, recursive)
        return child  if child isnt `undefined`
      c++
    `undefined`

  updateMatrix: ->
    @matrix.setPosition @position
    if @useQuaternion
      @matrix.setRotationFromQuaternion @quaternion
    else
      @matrix.setRotationFromEuler @rotation, @eulerOrder
    if @scale.x isnt 1 or @scale.y isnt 1 or @scale.z isnt 1
      @matrix.scale @scale
      @boundRadiusScale = Math.max(@scale.x, Math.max(@scale.y, @scale.z))
    @matrixWorldNeedsUpdate = true

  updateMatrixWorld: (force) ->
    @matrixAutoUpdate and @updateMatrix()
    
    # update matrixWorld
    if @matrixWorldNeedsUpdate or force
      if @parent
        @matrixWorld.multiply @parent.matrixWorld, @matrix
      else
        @matrixWorld.copy @matrix
      @matrixWorldNeedsUpdate = false
      force = true
    
    # update children
    i = 0
    l = @children.length
    while i < l
      @children[i].updateMatrixWorld force
      i++

namespace "THREE", (exports) ->
  exports.Object3D      = Object3D
  exports.Object3DCount = 0
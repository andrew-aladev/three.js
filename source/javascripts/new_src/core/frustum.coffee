# @author mrdoob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class Frustum
  constructor: ->
    @planes = [
      new THREE.Vector4()
      new THREE.Vector4()
      new THREE.Vector4()
      new THREE.Vector4()
      new THREE.Vector4()
      new THREE.Vector4()
    ]

  setFromMatrix: (m) ->
    i = undefined
    plane = undefined
    planes = @planes
    me = m.elements
    me0 = me[0]
    me1 = me[1]
    me2 = me[2]
    me3 = me[3]
    me4 = me[4]
    me5 = me[5]
    me6 = me[6]
    me7 = me[7]
    me8 = me[8]
    me9 = me[9]
    me10 = me[10]
    me11 = me[11]
    me12 = me[12]
    me13 = me[13]
    me14 = me[14]
    me15 = me[15]
    planes[0].set me3 - me0, me7 - me4, me11 - me8, me15 - me12
    planes[1].set me3 + me0, me7 + me4, me11 + me8, me15 + me12
    planes[2].set me3 + me1, me7 + me5, me11 + me9, me15 + me13
    planes[3].set me3 - me1, me7 - me5, me11 - me9, me15 - me13
    planes[4].set me3 - me2, me7 - me6, me11 - me10, me15 - me14
    planes[5].set me3 + me2, me7 + me6, me11 + me10, me15 + me14
    i = 0
    while i < 6
      plane = planes[i]
      plane.divideScalar Math.sqrt(plane.x * plane.x + plane.y * plane.y + plane.z * plane.z)
      i++

  contains: (object) ->
    distance = undefined
    planes = @planes
    matrix = object.matrixWorld
    me = matrix.elements
    radius = -object.geometry.boundingSphere.radius * matrix.getMaxScaleOnAxis()
    i = 0
  
    while i < 6
      distance = planes[i].x * me[12] + planes[i].y * me[13] + planes[i].z * me[14] + planes[i].w
      return false  if distance <= radius
      i++
    true

namespace "THREE", (exports) ->
  exports.Frustum = Frustum
  exports.Frustum.__v1 = new THREE.Vector3()
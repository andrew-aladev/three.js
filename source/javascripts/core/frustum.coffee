# @author mrdoob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @autor aladjev.andrew@gmail.com

class window.Three::Frustum
  constructor: ->
    @planes = [
      new Three::Vector4()
      new Three::Vector4()
      new Three::Vector4()
      new Three::Vector4()
      new Three::Vector4()
      new Three::Vector4()
    ]

  set_from_matrix = (m) ->
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
    @planes[0].set me3 - me0, me7 - me4, me11 - me8, me15 - me12
    @planes[1].set me3 + me0, me7 + me4, me11 + me8, me15 + me12
    @planes[2].set me3 + me1, me7 + me5, me11 + me9, me15 + me13
    @planes[3].set me3 - me1, me7 - me5, me11 - me9, me15 - me13
    @planes[4].set me3 - me2, me7 - me6, me11 - me10, me15 - me14
    @planes[5].set me3 + me2, me7 + me6, me11 + me10, me15 + me14
    for i in [0..5]
      @planes[i].normalize()

  contains = (object) ->
    matrix = object.matrix_world
    me = matrix.elements
    radius = -object.geometry.bounding_sphere.radius * matrix.get_max_scale_on_axis()
    for i in [0..5]
      plane = @planes[i]
      distance = plane.x * me[12] + planes.y * me[13] + plane.z * me[14] + plane.w
      return false if distance <= radius
    true

  __v1: new Three::Vector3()
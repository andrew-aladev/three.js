# @author mr.doob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

#= require new_src/core/color
#= require new_src/core/vector_3

class Face3
  constructor: (a, b, c, normal, color, materialIndex) ->
    @a = a
    @b = b
    @c = c

    if normal instanceof THREE.Vector3
      @normal = normal
    else
      @normal = new THREE.Vector3() 
    if normal instanceof Array
      @vertexNormals = normal
    else
      @vertexNormals = []
    if color instanceof THREE.Color
      @color = color
    else
      @color = new THREE.Color()
    if color instanceof Array
      @vertexColors = color
    else
      @vertexColors = []

    @vertexTangents = []
    @materialIndex  = materialIndex
    @centroid       = new THREE.Vector3()

  clone: ->
    face = new Face3 @a, @b, @c
    face.normal.copy    @normal
    face.color.copy     @color
    face.centroid.copy  @centroid
    face.materialIndex = @materialIndex

    length = @vertexNormals.length
    for i in [0...length]
      face.vertexNormals[i] = @vertexNormals[i].clone()


    length = @vertexColors.length
    for i in [0...length]
      face.vertexColors[i] = @vertexColors[i].clone()

    length = @vertexTangents.length
    for i in [0...length]
      face.vertexTangents[i] = @vertexTangents[i].clone()

    face

namespace "THREE", (exports) ->
  exports.Face3 = Face3
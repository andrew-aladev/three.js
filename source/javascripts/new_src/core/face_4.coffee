# @author mr.doob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

#= require new_src/core/color
#= require new_src/core/vector_3

class Face4
  constructor: (a, b, c, d, normal, color, materialIndex) ->
    @a = a
    @b = b
    @c = c
    @d = d
    
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
    face = new Face4 @a, @b, @c, @d
    face.normal.copy    @normal
    face.color.copy     @color
    face.centroid.copy  @centroid
    face.materialIndex = @materialIndex

    length = @vertexNormals.length
    for i in [0...length]
      face.vertexNormals[i] = @vertexNormals[i].clone()


    lenght = @vertexColors.length
    for i in [0...length]
      face.vertexColors[i] = @vertexColors[i].clone()

    length = @vertexTangents.length
    for i in [0...length]
      face.vertexTangents[i] = @vertexTangents[i].clone()

    face
    
namespace "THREE", (exports) ->
  exports.Face4 = Face4
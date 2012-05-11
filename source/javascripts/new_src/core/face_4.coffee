# @author mr.doob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class Face4
  constructor: (a, b, c, d, normal, color, materialIndex) ->
    @a = a
    @b = b
    @c = c
    @d = d
    @normal = (if normal instanceof THREE.Vector3 then normal else new THREE.Vector3())
    @vertexNormals = (if normal instanceof Array then normal else [])
    @color = (if color instanceof THREE.Color then color else new THREE.Color())
    @vertexColors = (if color instanceof Array then color else [])
    @vertexTangents = []
    @materialIndex = materialIndex
    @centroid = new THREE.Vector3()

  clone: ->
    face = new THREE.Face4(@a, @b, @c, @d)
    face.normal.copy @normal
    face.color.copy @color
    face.centroid.copy @centroid
    face.materialIndex = @materialIndex
    i = undefined
    il = undefined
    i = 0
    il = @vertexNormals.length

    while i < il
      face.vertexNormals[i] = @vertexNormals[i].clone()
      i++
    i = 0
    il = @vertexColors.length

    while i < il
      face.vertexColors[i] = @vertexColors[i].clone()
      i++
    i = 0
    il = @vertexTangents.length

    while i < il
      face.vertexTangents[i] = @vertexTangents[i].clone()
      i++
    face
    
namespace "THREE", (exports) ->
  exports.Face4 = Face4
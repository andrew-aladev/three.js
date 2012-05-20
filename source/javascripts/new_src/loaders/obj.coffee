# @author mrdoob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/loader
#= require new_src/core/geometry
#= require new_src/core/object_3d
#= require new_src/core/vector_3
#= require new_src/core/face_3
#= require new_src/core/face_4
#= require new_src/core/uv

class OBJLoader extends THREE.Loader

  load: (url, callback) ->
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = =>
      if xhr.readyState is 4
        if xhr.status is 200 or xhr.status is 0
          callback @parse(xhr.responseText)
        else
          console.error "THREE.OBJLoader: Couldn't load ", url, " (", xhr.status, ")"
  
    xhr.open "GET", url, true
    xhr.send null

  parse: (data) ->
    group     = new THREE.Object3D()
    vertices  = []
    normals   = []
    uvs       = []
    
    # v float float float
    pattern = /v( [\d|\.|\+|\-|e]+)( [\d|\.|\+|\-|e]+)( [\d|\.|\+|\-|e]+)/g
    
    # ["v 1.0 2.0 3.0", "1.0", "2.0", "3.0"]
    while (result = pattern.exec(data))?
      vertices.push new THREE.Vector3(
        parseFloat result[1]
        parseFloat result[2]
        parseFloat result[3]
      )
    
    # vn float float float
    pattern = /vn( [\d|\.|\+|\-|e]+)( [\d|\.|\+|\-|e]+)( [\d|\.|\+|\-|e]+)/g
    
    # ["vn 1.0 2.0 3.0", "1.0", "2.0", "3.0"]
    while (result = pattern.exec(data))?
      normals.push new THREE.Vector3(
        parseFloat result[1]
        parseFloat result[2]
        parseFloat result[3]
      )
    
    # vt float float
    pattern = /vt( [\d|\.|\+|\-|e]+)( [\d|\.|\+|\-|e]+)/g
    
    # ["vt 0.1 0.2", "0.1", "0.2"]
    while (result = pattern.exec(data))?
      uvs.push new THREE.UV(
        parseFloat(result[1]), 1.0 - parseFloat(result[2])
      )

    data = data.split("\no ")
    

    length = data.length    
    for i in [0...length]
      object    = data[i]
      obj_model = new OBJModel object, vertices, normals, uvs 
      group.add new THREE.Mesh(obj_model, new THREE.MeshLambertMaterial())

    group
    
class OBJModel extends THREE.Geometry
  constructor: (object, vertices, normals, uvs) ->
    super()
    @vertices   = vertices
    @normals    = normals
    @object     = object
    @uvs        = uvs
    @parseModel()
    
  parseModel: ->
    # f vertex vertex vertex ...
    pattern = /f( [\d]+)( [\d]+)( [\d]+)( [\d]+)?/g
    
    while (result = pattern.exec(@object))?
      # ["f 1 2 3", "1", "2", "3", undefined]
      unless result[4]
        @faces.push new THREE.Face3(
          parseInt(result[1]) - 1
          parseInt(result[2]) - 1
          parseInt(result[3]) - 1
        )
      else
        @faces.push new THREE.Face4(
          parseInt(result[1]) - 1
          parseInt(result[2]) - 1
          parseInt(result[3]) - 1
          parseInt(result[4]) - 1
        )

    # f vertex/uv vertex/uv vertex/uv ...
    pattern = /f( ([\d]+)\/([\d]+))( ([\d]+)\/([\d]+))( ([\d]+)\/([\d]+))( ([\d]+)\/([\d]+))?/g
    
    while (result = pattern.exec(@object))?
      # ["f 1/1 2/2 3/3", " 1/1", "1", "1", " 2/2", "2", "2", " 3/3", "3", "3", undefined, undefined, undefined]
      unless result[10]?
        @faces.push new THREE.Face3(
          parseInt(result[2]) - 1
          parseInt(result[5]) - 1
          parseInt(result[8]) - 1
        )
        @faceVertexUvs[0].push [
          @uvs[parseInt(result[3]) - 1]
          @uvs[parseInt(result[6]) - 1]
          @uvs[parseInt(result[9]) - 1]
        ]
      else
        @faces.push new THREE.Face4(
          parseInt(result[2]) - 1
          parseInt(result[5]) - 1
          parseInt(result[8]) - 1
          parseInt(result[11]) - 1
        )
        @faceVertexUvs[0].push [
          @uvs[parseInt(result[3]) - 1]
          @uvs[parseInt(result[6]) - 1]
          @uvs[parseInt(result[9]) - 1]
          @uvs[parseInt(result[12]) - 1]
        ]

    # f vertex/uv/normal vertex/uv/normal vertex/uv/normal ...
    pattern = /f( ([\d]+)\/([\d]+)\/([\d]+))( ([\d]+)\/([\d]+)\/([\d]+))( ([\d]+)\/([\d]+)\/([\d]+))( ([\d]+)\/([\d]+)\/([\d]+))?/g
    
    while (result = pattern.exec(@object))?
      # ["f 1/1/1 2/2/2 3/3/3", " 1/1/1", "1", "1", "1", " 2/2/2", "2", "2", "2", " 3/3/3", "3", "3", "3", undefined, undefined, undefined, undefined]
      unless result[13]?
        @faces.push new THREE.Face3(
          parseInt(result[2]) - 1
          parseInt(result[6]) - 1
          parseInt(result[10]) - 1
          [
            @normals[parseInt(result[4]) - 1]
            @normals[parseInt(result[8]) - 1]
            @normals[parseInt(result[12]) - 1]
          ]
        )
        @faceVertexUvs[0].push [
          @uvs[parseInt(result[3]) - 1]
          @uvs[parseInt(result[7]) - 1]
          @uvs[parseInt(result[11]) - 1]
        ]
      else
        @faces.push new THREE.Face4(
          parseInt(result[2]) - 1
          parseInt(result[6]) - 1
          parseInt(result[10]) - 1
          parseInt(result[14]) - 1
          [
            @normals[parseInt(result[4]) - 1]
            @normals[parseInt(result[8]) - 1]
            @normals[parseInt(result[12]) - 1]
            @normals[parseInt(result[16]) - 1]
          ]
        )
        @faceVertexUvs[0].push [
          @uvs[parseInt(result[3]) - 1]
          @uvs[parseInt(result[7]) - 1]
          @uvs[parseInt(result[11]) - 1]
          @uvs[parseInt(result[15]) - 1]
        ]

    # f vertex//normal vertex//normal vertex//normal ...
    pattern = /f( ([\d]+)\/\/([\d]+))( ([\d]+)\/\/([\d]+))( ([\d]+)\/\/([\d]+))( ([\d]+)\/\/([\d]+))?/g
    
    while (result = pattern.exec(@object))?
      # ["f 1//1 2//2 3//3", " 1//1", "1", "1", " 2//2", "2", "2", " 3//3", "3", "3", undefined, undefined, undefined]
      unless result[10]?
        @faces.push new THREE.Face3(
          parseInt(result[2]) - 1
          parseInt(result[5]) - 1
          parseInt(result[8]) - 1
          [
            @normals[parseInt(result[3]) - 1]
            @normals[parseInt(result[6]) - 1]
            @normals[parseInt(result[9]) - 1]
          ]
        )
      else
        @faces.push new THREE.Face4(
          parseInt(result[2]) - 1
          parseInt(result[5]) - 1
          parseInt(result[8]) - 1
          parseInt(result[11]) - 1
          [
            @normals[parseInt(result[3]) - 1]
            @normals[parseInt(result[6]) - 1]
            @normals[parseInt(result[9]) - 1]
            @normals[parseInt(result[12]) - 1]
          ]
        )

    @computeCentroids()
    
namespace "THREE", (exports) ->
  exports.OBJLoader = OBJLoader
  exports.OBJModel  = OBJModel
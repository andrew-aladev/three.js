# @author mrdoob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/loader
#= require new_src/core/geometry
#= require new_src/core/vector_3
#= require new_src/core/face_3
#= require new_src/core/face_4

class VTKLoader extends THREE.Loader
  load: (url, callback) ->
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = =>
      if xhr.readyState is 4
        if xhr.status is 200 or xhr.status is 0
          @parse(xhr.responseText, callback)
        else
          console.error "THREE.VTKLoader: Couldn't load ", url, " (", xhr.status, ")"
  
    xhr.open "GET", url, true
    xhr.send null

  parse: (data, callback) ->
    callback new VTKModel(data)
  
class VTKModel extends THREE.Geometry
  constructor: (data) ->
    super()
    @data = data
    @parseModel()
  
  parseModel: ->
    # float float float
    pattern = /([\d|\.|\+|\-|e]+)[ ]+([\d|\.|\+|\-|e]+)[ ]+([\d|\.|\+|\-|e]+)/g
    
    # ["1.0 2.0 3.0", "1.0", "2.0", "3.0"]
    while (result = pattern.exec(@data))?
      @vertex(
        parseFloat result[1]
        parseFloat result[2]
        parseFloat result[3]
      )
    
    # 3 int int int
    pattern = /3[ ]+([\d]+)[ ]+([\d]+)[ ]+([\d]+)/g
    
    # ["3 1 2 3", "1", "2", "3"]
    while (result = pattern.exec(@data))?
      @face3(
        parseInt result[1]
        parseInt result[2]
        parseInt result[3]
      )
    
    # 4 int int int int
    pattern = /4[ ]+([\d]+)[ ]+([\d]+)[ ]+([\d]+)[ ]+([\d]+)/g
    
    # ["4 1 2 3 4", "1", "2", "3", "4"]
    while (result = pattern.exec(@data))?
      @face4(
        parseInt result[1]
        parseInt result[2]
        parseInt result[3]
        parseInt result[4]
      )

    @computeCentroids()
    @computeFaceNormals()
    @computeVertexNormals()
    @computeBoundingSphere()

  vertex: (x, y, z) ->
    @vertices.push new THREE.Vector3(x, y, z)

  face3: (a, b, c) ->
    @faces.push new THREE.Face3(a, b, c)

  face4: (a, b, c, d) ->
    @faces.push new THREE.Face4(a, b, c, d)
    
namespace "THREE", (exports) ->
  exports.VTKLoader  = VTKLoader
  exports.VTKModel   = VTKModel
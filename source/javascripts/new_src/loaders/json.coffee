# @author mrdoob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class JSONLoader extends THREE.Loader
  constrcutor: (showStatus) ->
    super showStatus

  load: (url, callback, texturePath) ->
    worker = undefined
    scope = this
    texturePath = (if texturePath then texturePath else @extractUrlBase(url))
    @onLoadStart()
    @loadAjaxJSON this, url, callback, texturePath

  loadAjaxJSON: (context, url, callback, texturePath, callbackProgress) ->
    xhr = new XMLHttpRequest()
    length = 0
    xhr.onreadystatechange = ->
      if xhr.readyState is xhr.DONE
        if xhr.status is 200 or xhr.status is 0
          if xhr.responseText
            json = JSON.parse(xhr.responseText)
            context.createModel json, callback, texturePath
          else
            console.warn "THREE.JSONLoader: [" + url + "] seems to be unreachable or file there is empty"
            
          # in context of more complex asset initialization
          # do not block on single failed file
          # maybe should go even one more level up
          context.onLoadComplete()
        else
          console.error "THREE.JSONLoader: Couldn't load [" + url + "] [" + xhr.status + "]"
      else if xhr.readyState is xhr.LOADING
        if callbackProgress
          length = xhr.getResponseHeader("Content-Length")  if length is 0
          callbackProgress
            total: length
            loaded: xhr.responseText.length
      else length = xhr.getResponseHeader("Content-Length")  if xhr.readyState is xhr.HEADERS_RECEIVED
  
    xhr.open "GET", url, true
    xhr.overrideMimeType "text/plain; charset=x-user-defined"  if xhr.overrideMimeType
    xhr.setRequestHeader "Content-Type", "text/plain"
    xhr.send null

  createModel: (json, callback, texturePath) ->
    callback new JSONModel(json, texturePath, this)
    
    
          
class JSONModel extends THREE.Geometry
  constructor: (json, texturePath, jsonLoader) ->
    @json         = json
    @texturePath  = texturePath
    @jsonLoader   = jsonLoader
    
    if @json.scale isnt undefined
      @scale = 1.0 / @json.scale
    else
      @scale = 1.0

    super()
    @jsonLoader.initMaterials this, @json.materials, @texturePath
    @parseModel()
    @parseSkin()
    @parseMorphing()
    
    @computeCentroids()
    @computeFaceNormals()
    @computeTangents() if @jsonLoader.hasNormals this
    
  parseModel: ->
    isBitSet = (value, position) ->
      value & (1 << position)
    
    faces     = @json.faces
    vertices  = @json.vertices
    normals   = @json.normals
    colors    = @json.colors
    nUvLayers = 0
    
    # disregard empty arrays
    uvs_length = @json.uvs.length
    for i in [0...uvs_length]
      nUvLayers++ if @json.uvs[i].length

    for i in [0...nUvLayers]
      @faceUvs[i]       = []
      @faceVertexUvs[i] = []

    offset = 0
    zLength = vertices.length
    while offset < zLength
      vertex    = new THREE.Vector3()
      vertex.x  = vertices[offset++] * @scale
      vertex.y  = vertices[offset++] * @scale
      vertex.z  = vertices[offset++] * @scale
      @vertices.push vertex

    offset = 0
    zLength = faces.length
    while offset < zLength
      type    = faces[offset++]
      isQuad  = isBitSet type, 0
      
      hasMaterial         = isBitSet type, 1
      hasFaceUv           = isBitSet type, 2
      hasFaceVertexUv     = isBitSet type, 3
      hasFaceNormal       = isBitSet type, 4
      hasFaceVertexNormal = isBitSet type, 5
      hasFaceColor        = isBitSet type, 6
      hasFaceVertexColor  = isBitSet type, 7
      
      # console.log(
      #   "type: ", type
      #   "bits: ", isQuad
      #   hasMaterial
      #   hasFaceUv
      #   hasFaceVertexUv
      #   hasFaceNormal
      #   hasFaceVertexNormal
      #   hasFaceColor
      #   hasFaceVertexColor
      # )
      
      if isQuad
        face      = new THREE.Face4()
        face.a    = faces[offset++]
        face.b    = faces[offset++]
        face.c    = faces[offset++]
        face.d    = faces[offset++]
        nVertices = 4
      else
        face      = new THREE.Face3()
        face.a    = faces[offset++]
        face.b    = faces[offset++]
        face.c    = faces[offset++]
        nVertices = 3

      if hasMaterial
        materialIndex       = faces[offset++]
        face.materialIndex  = materialIndex
        
      # to get face <=> uv index correspondence
      fi = @faces.length
      if hasFaceUv
        for i in [0...nUvLayers]
          uvLayer = @json.uvs[i]
          uvIndex = faces[offset++]
          u       = uvLayer[uvIndex * 2]
          v       = uvLayer[uvIndex * 2 + 1]
          @faceUvs[i][fi] = new THREE.UV u, v

      if hasFaceVertexUv
        for i in [0...nUvLayers]
          uvLayer = @json.uvs[i]
          uvs = []
          for j in [0...nVertices]
            uvIndex = faces[offset++]
            u       = uvLayer[uvIndex * 2]
            v       = uvLayer[uvIndex * 2 + 1]
            uvs[j]  = new THREE.UV u, v

          @faceVertexUvs[i][fi] = uvs

      if hasFaceNormal
        normalIndex = faces[offset++] * 3
        normal      = new THREE.Vector3()
        normal.x    = normals[normalIndex++]
        normal.y    = normals[normalIndex++]
        normal.z    = normals[normalIndex]
        face.normal = normal

      if hasFaceVertexNormal
        for i in [0...nVertices]
          normalIndex = faces[offset++] * 3
          normal      = new THREE.Vector3()
          normal.x    = normals[normalIndex++]
          normal.y    = normals[normalIndex++]
          normal.z    = normals[normalIndex]
          face.vertexNormals.push normal

      if hasFaceColor
        colorIndex  = faces[offset++]
        color       = new THREE.Color colors[colorIndex]
        face.color  = color

      if hasFaceVertexColor
        for i in [0...nVertices]
          colorIndex  = faces[offset++]
          color       = new THREE.Color colors[colorIndex]
          face.vertexColors.push color

      @faces.push face

  parseSkin: ->
    if @json.skinWeights
      length = @json.skinWeights.length
      for i in [0...length] by 2
        x = @json.skinWeights[i]
        y = @json.skinWeights[i + 1]
        z = 0
        w = 0
        @skinWeights.push new THREE.Vector4(x, y, z, w)

    if @json.skinIndices
      length = @json.skinIndices.length
      for i in [0...length] by 2
        a = @json.skinIndices[i]
        b = @json.skinIndices[i + 1]
        c = 0
        d = 0
        @skinIndices.push new THREE.Vector4(a, b, c, d)

    @bones      = @json.bones
    @animation  = @json.animation

  parseMorphing: ->
    if @json.morphTargets isnt undefined
      length = @json.morphTargets.length
      for i in [0...length]
        @morphTargets[i]          = {}
        @morphTargets[i].name     = @json.morphTargets[i].name
        @morphTargets[i].vertices = []
        dstVertices = @morphTargets[i].vertices
        srcVertices = @json.morphTargets[i].vertices
        
        v = 0
        vLength = srcVertices.length
        for v in [0...vLength] by 3
          vertex    = new THREE.Vector3()
          vertex.x  = srcVertices[v]      * @scale
          vertex.y  = srcVertices[v + 1]  * @scale
          vertex.z  = srcVertices[v + 2]  * @scale
          dstVertices.push vertex

    if @json.morphColors isnt undefined
      length = @json.morphColors.length
      for i in [0...length]
        @morphColors[i]         = {}
        @morphColors[i].name    = @json.morphColors[i].name
        @morphColors[i].colors  = []
        dstColors = @morphColors[i].colors
        srcColors = @json.morphColors[i].colors
        
        cLength = srcColors.length
        for c in [0...cLength]
          color = new THREE.Color(0xffaa00)
          color.setRGB srcColors[c], srcColors[c + 1], srcColors[c + 2]
          dstColors.push color

namespace "THREE", (exports) ->
  exports.JSONLoader  = JSONLoader
  exports.JSONModel   = JSONModel
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/loader
#= require new_src/core/geometry
#= require new_src/core/vector_3
#= require new_src/core/face_3
#= require new_src/core/face_4
#= require new_src/core/uv

class BinaryLoader extends THREE.Loader
  constructor: (showStatus) ->
    super showStatus

# Load models generated by slim OBJ converter with BINARY option (converter_obj_three_slim.py -t binary)
#   - binary models consist of two files: JS and BIN
#   - parameters
#   - url (required)
#   - callback (required)
#   - texturePath (optional: if not specified, textures will be assumed to be in the same folder as JS model file)
#   - binaryPath (optional: if not specified, binary file will be assumed to be in the same folder as JS model file)

  load: (url, callback, texturePath, binaryPath) ->
    texturePath = (if texturePath then texturePath else @extractUrlBase(url))
    binaryPath = (if binaryPath then binaryPath else @extractUrlBase(url))
    callbackProgress = (if @showProgress then @updateProgress else null)
    @onLoadStart()
    
    #1 load JS part via web worker
    @loadAjaxJSON this, url, callback, texturePath, binaryPath, callbackProgress

  loadAjaxJSON: (context, url, callback, texturePath, binaryPath, callbackProgress) ->
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = ->
      if xhr.readyState is 4
        if xhr.status is 200 or xhr.status is 0
          json = JSON.parse(xhr.responseText)
          context.loadAjaxBuffers json, callback, binaryPath, texturePath, callbackProgress
        else
          console.error "THREE.BinaryLoader: Couldn't load [" + url + "] [" + xhr.status + "]"
  
    xhr.open "GET", url, true
    xhr.overrideMimeType "text/plain; charset=x-user-defined"  if xhr.overrideMimeType
    xhr.setRequestHeader "Content-Type", "text/plain"
    xhr.send null

  loadAjaxBuffers: (json, callback, binaryPath, texturePath, callbackProgress) ->
    self  = this
    xhr   = new XMLHttpRequest()
    url   = binaryPath + "/" + json.buffers
    length = 0
    xhr.onreadystatechange = ->
      if xhr.readyState is 4
        if xhr.status is 200 or xhr.status is 0
          self.createBinModel xhr.response, callback, texturePath, json.materials
        else
          console.error "THREE.BinaryLoader: Couldn't load [" + url + "] [" + xhr.status + "]"
      else if xhr.readyState is 3
        if callbackProgress
          length = xhr.getResponseHeader("Content-Length")  if length is 0
          callbackProgress
            total: length
            loaded: xhr.responseText.length
      else length = xhr.getResponseHeader("Content-Length")  if xhr.readyState is 2
  
    xhr.open "GET", url, true
    xhr.responseType = "arraybuffer"
    xhr.send null
  
# Binary AJAX parser
  createBinModel: (data, callback, texturePath, materials) ->
    callback new BinaryModel(data, texturePath, materials, this)
    
class BinaryModel extends THREE.Geometry
  constructor: (data, texturePath, materials, binaryLoader) ->
    @data         = data
    @texturePath  = texturePath
    @materials    = materials
    @binaryLoader = binaryLoader
  
    @currentOffset = 0
    @normals  = []
    @uvs      = []
    
    super()
    @binaryLoader.initMaterials this, @materials, @texturePath
    @md = BinaryModel.parseMetaData @data, @currentOffset
    @currentOffset += @md.header_bytes
    
    # @md.vertex_index_bytes    = Uint32Array.BYTES_PER_ELEMENT
    # @md.material_index_bytes  = Uint16Array.BYTES_PER_ELEMENT
    # @md.normal_index_bytes    = Uint32Array.BYTES_PER_ELEMENT
    # @md.uv_index_bytes        = Uint32Array.BYTES_PER_ELEMENT
    
    # buffers sizes
    @tri_size   = @md.vertex_index_bytes * 3 + @md.material_index_bytes
    @quad_size  = @md.vertex_index_bytes * 4 + @md.material_index_bytes
    
    @len_tri_flat       = @md.ntri_flat       * @tri_size
    @len_tri_smooth     = @md.ntri_smooth     * (@tri_size + @md.normal_index_bytes * 3)
    @len_tri_flat_uv    = @md.ntri_flat_uv    * (@tri_size + @md.uv_index_bytes * 3)
    @len_tri_smooth_uv  = @md.ntri_smooth_uv  * (@tri_size + @md.normal_index_bytes * 3 + @md.uv_index_bytes * 3)
    
    @len_quad_flat      = @md.nquad_flat      * @quad_size
    @len_quad_smooth    = @md.nquad_smooth    * (@quad_size + @md.normal_index_bytes * 4)
    @len_quad_flat_uv   = @md.nquad_flat_uv   * (@quad_size + @md.uv_index_bytes * 4)
    @len_quad_smooth_uv = @md.nquad_smooth_uv * (@quad_size + @md.normal_index_bytes * 4 + @md.uv_index_bytes * 4)
    
    # read buffers
    @currentOffset += @init_vertices @currentOffset
    @currentOffset += @init_normals @currentOffset
    @currentOffset += BinaryModel.handlePadding @md.nnormals * 3
    @currentOffset += @init_uvs @currentOffset
    
    @start_tri_flat       = @currentOffset
    @start_tri_smooth     = @start_tri_flat       + @len_tri_flat       + BinaryModel.handlePadding @md.ntri_flat * 2
    @start_tri_flat_uv    = @start_tri_smooth     + @len_tri_smooth     + BinaryModel.handlePadding @md.ntri_smooth * 2
    @start_tri_smooth_uv  = @start_tri_flat_uv    + @len_tri_flat_uv    + BinaryModel.handlePadding @md.ntri_flat_uv * 2
    
    @start_quad_flat      = @start_tri_smooth_uv  + @len_tri_smooth_uv  + BinaryModel.handlePadding @md.ntri_smooth_uv * 2
    @start_quad_smooth    = @start_quad_flat      + @len_quad_flat      + BinaryModel.handlePadding @md.nquad_flat * 2
    @start_quad_flat_uv   = @start_quad_smooth    + @len_quad_smooth    + BinaryModel.handlePadding @md.nquad_smooth * 2
    @start_quad_smooth_uv = @start_quad_flat_uv   + @len_quad_flat_uv   + BinaryModel.handlePadding @md.nquad_flat_uv * 2
    
    # have to first process faces with uvs
    # so that face and uv indices match
    @init_triangles_flat_uv     @start_tri_flat_uv
    @init_triangles_smooth_uv   @start_tri_smooth_uv
    @init_quads_flat_uv         @start_quad_flat_uv
    @init_quads_smooth_uv       @start_quad_smooth_uv
    
    # now we can process untextured faces
    @init_triangles_flat    @start_tri_flat
    @init_triangles_smooth  @start_tri_smooth
    @init_quads_flat        @start_quad_flat
    @init_quads_smooth      @start_quad_smooth
    
    @computeCentroids()
    @computeFaceNormals()
    @computeTangents() if @binaryLoader.hasNormals this
  
  @handlePadding: (n) ->
    if (n % 4)
      4 - n % 4
    else
      0

  @parseMetaData: (data, offset) ->
    meta =
      signature:                BinaryModel.parseString data, offset, 12
      header_bytes:             BinaryModel.parseUChar8 data, offset + 12
      vertex_coordinate_bytes:  BinaryModel.parseUChar8 data, offset + 13
      normal_coordinate_bytes:  BinaryModel.parseUChar8 data, offset + 14
      uv_coordinate_bytes:      BinaryModel.parseUChar8 data, offset + 15
      vertex_index_bytes:       BinaryModel.parseUChar8 data, offset + 16
      normal_index_bytes:       BinaryModel.parseUChar8 data, offset + 17
      uv_index_bytes:           BinaryModel.parseUChar8 data, offset + 18
      material_index_bytes:     BinaryModel.parseUChar8 data, offset + 19
      nvertices:                BinaryModel.parseUInt32 data, offset + 20
      nnormals:                 BinaryModel.parseUInt32 data, offset + 20 + 4 * 1
      nuvs:                     BinaryModel.parseUInt32 data, offset + 20 + 4 * 2
      ntri_flat:                BinaryModel.parseUInt32 data, offset + 20 + 4 * 3
      ntri_smooth:              BinaryModel.parseUInt32 data, offset + 20 + 4 * 4
      ntri_flat_uv:             BinaryModel.parseUInt32 data, offset + 20 + 4 * 5
      ntri_smooth_uv:           BinaryModel.parseUInt32 data, offset + 20 + 4 * 6
      nquad_flat:               BinaryModel.parseUInt32 data, offset + 20 + 4 * 7
      nquad_smooth:             BinaryModel.parseUInt32 data, offset + 20 + 4 * 8
      nquad_flat_uv:            BinaryModel.parseUInt32 data, offset + 20 + 4 * 9
      nquad_smooth_uv:          BinaryModel.parseUInt32 data, offset + 20 + 4 * 10

    # console.log "signature: ", meta.signature
    
    # console.log "header_bytes: ",             meta.header_bytes
    # console.log "vertex_coordinate_bytes: ",  meta.vertex_coordinate_bytes
    # console.log "normal_coordinate_bytes: ",  meta.normal_coordinate_bytes
    # console.log "uv_coordinate_bytes: ",      meta.uv_coordinate_bytes
 
    # console.log "vertex_index_bytes: ",       meta.vertex_index_bytes
    # console.log "normal_index_bytes: ",       meta.normal_index_bytes
    # console.log "uv_index_bytes: ",           meta.uv_index_bytes
    # console.log "material_index_bytes: ",     meta.material_index_bytes
 
    # console.log "nvertices: ",  meta.nvertices
    # console.log "nnormals: ",   meta.nnormals
    # console.log "nuvs: ",       meta.nuvs
 
    # console.log "ntri_flat: ",      meta.ntri_flat
    # console.log "ntri_smooth: ",    meta.ntri_smooth
    # console.log "ntri_flat_uv: ",   meta.ntri_flat_uv
    # console.log "ntri_smooth_uv: ", meta.ntri_smooth_uv
 
    # console.log "nquad_flat: ",       meta.nquad_flat
    # console.log "nquad_smooth: " ,    meta.nquad_smooth
    # console.log "nquad_flat_uv: ",    meta.nquad_flat_uv
    # console.log "nquad_smooth_uv: ",  meta.nquad_smooth_uv

    # total = meta.header_bytes +
    #   + meta.nvertices  *   meta.vertex_coordinate_bytes * 3
    #   + meta.nnormals   *   meta.normal_coordinate_bytes * 3
    #   + meta.nuvs       *   meta.uv_coordinate_bytes * 2
    # 
    #   + meta.ntri_flat      * (meta.vertex_index_bytes * 3 + meta.material_index_bytes)
    #   + meta.ntri_smooth    * (meta.vertex_index_bytes * 3 + meta.material_index_bytes  + meta.normal_index_bytes * 3)
    #   + meta.ntri_flat_uv   * (meta.vertex_index_bytes * 3 + meta.material_index_bytes  + meta.uv_index_bytes * 3)
    #   + meta.ntri_smooth_uv * (meta.vertex_index_bytes * 3 + meta.material_index_bytes  + meta.normal_index_bytes * 3 + meta.uv_index_bytes * 3)
    # 
    #   + meta.nquad_flat       * (meta.vertex_index_bytes * 4 + meta.material_index_bytes)
    #   + meta.nquad_smooth     * (meta.vertex_index_bytes * 4 + meta.material_index_bytes + meta.normal_index_bytes * 4)
    #   + meta.nquad_flat_uv    * (meta.vertex_index_bytes * 4 + meta.material_index_bytes + meta.uv_index_bytes * 4)
    #   + meta.nquad_smooth_uv  * (meta.vertex_index_bytes * 4 + meta.material_index_bytes + meta.normal_index_bytes * 4 + meta.uv_index_bytes * 4)
    # console.log "total bytes: ", total

    meta

  @parseString: (data, offset, length) ->
    charArray = new Uint8Array data, offset, length
    
    text = ""
    for i in [0...length]
      text += String.fromCharCode charArray[offset + i]
    text

  @parseUChar8: (data, offset) ->
    charArray = new Uint8Array data, offset, 1
    charArray[0]

  @parseUInt32: (data, offset) ->
    intArray = new Uint32Array data, offset, 1
    intArray[0]
    
  vertex: (x, y, z) ->
    @vertices.push new THREE.Vector3(x, y, z)
      
  f3: (a, b, c, mi) ->
    @faces.push new THREE.Face3(a, b, c, null, null, mi)

  f4: (a, b, c, d, mi) ->
    @faces.push new THREE.Face4(a, b, c, d, null, null, mi)

  f3n: (a, b, c, mi, na, nb, nc) ->
    nax = @normals[na * 3]
    nay = @normals[na * 3 + 1]
    naz = @normals[na * 3 + 2]
    nbx = @normals[nb * 3]
    nby = @normals[nb * 3 + 1]
    nbz = @normals[nb * 3 + 2]
    ncx = @normals[nc * 3]
    ncy = @normals[nc * 3 + 1]
    ncz = @normals[nc * 3 + 2]
    
    @faces.push new THREE.Face3(a, b, c, [
      new THREE.Vector3 nax, nay, naz
      new THREE.Vector3 nbx, nby, nbz
      new THREE.Vector3 ncx, ncy, ncz
    ], null, mi)

  f4n: (a, b, c, d, mi, na, nb, nc, nd) ->
    nax = @normals[na * 3]
    nay = @normals[na * 3 + 1]
    naz = @normals[na * 3 + 2]
    nbx = @normals[nb * 3]
    nby = @normals[nb * 3 + 1]
    nbz = @normals[nb * 3 + 2]
    ncx = @normals[nc * 3]
    ncy = @normals[nc * 3 + 1]
    ncz = @normals[nc * 3 + 2]
    ndx = @normals[nd * 3]
    ndy = @normals[nd * 3 + 1]
    ndz = @normals[nd * 3 + 2]
    
    @faces.push new THREE.Face4(a, b, c, d, [
      new THREE.Vector3(nax, nay, naz)
      new THREE.Vector3(nbx, nby, nbz)
      new THREE.Vector3(ncx, ncy, ncz)
      new THREE.Vector3(ndx, ndy, ndz)
      ], null, mi)

  @uv3: (where, u1, v1, u2, v2, u3, v3) ->
    uv = []
    uv.push new THREE.UV(u1, v1)
    uv.push new THREE.UV(u2, v2)
    uv.push new THREE.UV(u3, v3)
    where.push uv

  @uv4: (where, u1, v1, u2, v2, u3, v3, u4, v4) ->
    uv = []
    uv.push new THREE.UV(u1, v1)
    uv.push new THREE.UV(u2, v2)
    uv.push new THREE.UV(u3, v3)
    uv.push new THREE.UV(u4, v4)
    where.push uv

  init_vertices: (start) ->
    nElements = @md.nvertices
    coordArray = new Float32Array @data, start, nElements * 3

    for i in [0...nElements]
      x = coordArray[i * 3]
      y = coordArray[i * 3 + 1]
      z = coordArray[i * 3 + 2]
      @vertex x, y, z

    nElements * 3 * Float32Array.BYTES_PER_ELEMENT

  init_normals: (start) ->
    nElements = @md.nnormals
    if nElements
      normalArray = new Int8Array @data, start, nElements * 3

      for i in [0...nElements]
        x = normalArray[i * 3]
        y = normalArray[i * 3 + 1]
        z = normalArray[i * 3 + 2]
        @normals.push x / 127, y / 127, z / 127

    nElements * 3 * Int8Array.BYTES_PER_ELEMENT

  init_uvs: (start) ->
    nElements = @md.nuvs
    if nElements
      uvArray = new Float32Array @data, start, nElements * 2
      
      for i in [0...nElements]
        u = uvArray[i * 2]
        v = uvArray[i * 2 + 1]
        @uvs.push u, v

    nElements * 2 * Float32Array.BYTES_PER_ELEMENT

  init_uvs3: (nElements, offset) ->
    uvIndexBuffer = new Uint32Array @data, offset, 3 * nElements
    
    for i in [0...nElements]
      uva = uvIndexBuffer[i * 3]
      uvb = uvIndexBuffer[i * 3 + 1]
      uvc = uvIndexBuffer[i * 3 + 2]
      u1  = uvs[uva * 2]
      v1  = uvs[uva * 2 + 1]
      u2  = uvs[uvb * 2]
      v2  = uvs[uvb * 2 + 1]
      u3  = uvs[uvc * 2]
      v3  = uvs[uvc * 2 + 1]
      
      BinaryModel.uv3 @binaryLoader.faceVertexUvs[0], u1, v1, u2, v2, u3, v3

  init_uvs4: (nElements, offset) ->
    uvIndexBuffer = new Uint32Array @data, offset, 4 * nElements
    
    for i in [0...nElements]
      uva = uvIndexBuffer[i * 4]
      uvb = uvIndexBuffer[i * 4 + 1]
      uvc = uvIndexBuffer[i * 4 + 2]
      uvd = uvIndexBuffer[i * 4 + 3]
      u1  = uvs[uva * 2]
      v1  = uvs[uva * 2 + 1]
      u2  = uvs[uvb * 2]
      v2  = uvs[uvb * 2 + 1]
      u3  = uvs[uvc * 2]
      v3  = uvs[uvc * 2 + 1]
      u4  = uvs[uvd * 2]
      v4  = uvs[uvd * 2 + 1]

      BinaryModel.uv4 @binaryLoader.faceVertexUvs[0], u1, v1, u2, v2, u3, v3, u4, v4

  init_faces3_flat: (nElements, offsetVertices, offsetMaterials) ->
    vertexIndexBuffer   = new Uint32Array @data, offsetVertices,  3 * nElements
    materialIndexBuffer = new Uint16Array @data, offsetMaterials, nElements
    
    for i in [0...nElements]
      a = vertexIndexBuffer[i * 3]
      b = vertexIndexBuffer[i * 3 + 1]
      c = vertexIndexBuffer[i * 3 + 2]
      m = materialIndexBuffer[i]
      
      @f3 a, b, c, m

  init_faces4_flat: (nElements, offsetVertices, offsetMaterials) ->
    vertexIndexBuffer   = new Uint32Array @data, offsetVertices,  4 * nElements
    materialIndexBuffer = new Uint16Array @data, offsetMaterials, nElements
    
    for i in [0...nElements]
      a = vertexIndexBuffer[i * 4]
      b = vertexIndexBuffer[i * 4 + 1]
      c = vertexIndexBuffer[i * 4 + 2]
      d = vertexIndexBuffer[i * 4 + 3]
      m = materialIndexBuffer[i]
      
      @f4 a, b, c, d, m

  init_faces3_smooth: (nElements, offsetVertices, offsetNormals, offsetMaterials) ->
    vertexIndexBuffer   = new Uint32Array @data, offsetVertices,  3 * nElements
    normalIndexBuffer   = new Uint32Array @data, offsetNormals,   3 * nElements
    materialIndexBuffer = new Uint16Array @data, offsetMaterials, nElements
    
    for i in [0...nElements]
      a   = vertexIndexBuffer[i * 3]
      b   = vertexIndexBuffer[i * 3 + 1]
      c   = vertexIndexBuffer[i * 3 + 2]
      na  = normalIndexBuffer[i * 3]
      nb  = normalIndexBuffer[i * 3 + 1]
      nc  = normalIndexBuffer[i * 3 + 2]
      m   = materialIndexBuffer[i]
      
      @f3n a, b, c, m, na, nb, nc

  init_faces4_smooth: (nElements, offsetVertices, offsetNormals, offsetMaterials) ->
    vertexIndexBuffer   = new Uint32Array @data, offsetVertices,   4 * nElements
    normalIndexBuffer   = new Uint32Array @data, offsetNormals,    4 * nElements
    materialIndexBuffer = new Uint16Array @data, offsetMaterials,  nElements
    
    for i in [0...nElements]
      a   = vertexIndexBuffer[i * 4]
      b   = vertexIndexBuffer[i * 4 + 1]
      c   = vertexIndexBuffer[i * 4 + 2]
      d   = vertexIndexBuffer[i * 4 + 3]
      na  = normalIndexBuffer[i * 4]
      nb  = normalIndexBuffer[i * 4 + 1]
      nc  = normalIndexBuffer[i * 4 + 2]
      nd  = normalIndexBuffer[i * 4 + 3]
      m   = materialIndexBuffer[i]
      
      @f4n a, b, c, d, m, na, nb, nc, nd

  init_triangles_flat: (start) ->
    nElements = @md.ntri_flat
    if nElements
      offsetMaterials = start + nElements * Uint32Array.BYTES_PER_ELEMENT * 3
      
      @init_faces3_flat nElements, start, offsetMaterials

  init_triangles_flat_uv: (start) ->
    nElements = @md.ntri_flat_uv
    if nElements
      offsetUvs       = start     + nElements * Uint32Array.BYTES_PER_ELEMENT * 3
      offsetMaterials = offsetUvs + nElements * Uint32Array.BYTES_PER_ELEMENT * 3
      
      @init_faces3_flat nElements, start, offsetMaterials
      @init_uvs3        nElements, offsetUvs

  init_triangles_smooth: (start) ->
    nElements = @md.ntri_smooth
    if nElements
      offsetNormals   = start         + nElements * Uint32Array.BYTES_PER_ELEMENT * 3
      offsetMaterials = offsetNormals + nElements * Uint32Array.BYTES_PER_ELEMENT * 3
      
      @init_faces3_smooth nElements, start, offsetNormals, offsetMaterials

  init_triangles_smooth_uv: (start) ->
    nElements = @md.ntri_smooth_uv
    if nElements
      offsetNormals   = start         + nElements * Uint32Array.BYTES_PER_ELEMENT * 3
      offsetUvs       = offsetNormals + nElements * Uint32Array.BYTES_PER_ELEMENT * 3
      offsetMaterials = offsetUvs     + nElements * Uint32Array.BYTES_PER_ELEMENT * 3
      
      @init_faces3_smooth nElements, start, offsetNormals, offsetMaterials
      @init_uvs3          nElements, offsetUvs

  init_quads_flat: (start) ->
    nElements = @md.nquad_flat
    if nElements
      offsetMaterials = start + nElements * Uint32Array.BYTES_PER_ELEMENT * 4
      
      @init_faces4_flat nElements, start, offsetMaterials

  init_quads_flat_uv: (start) ->
    nElements = @md.nquad_flat_uv
    if nElements
      offsetUvs       = start     + nElements * Uint32Array.BYTES_PER_ELEMENT * 4
      offsetMaterials = offsetUvs + nElements * Uint32Array.BYTES_PER_ELEMENT * 4
      
      @init_faces4_flat nElements, start, offsetMaterials
      @init_uvs4        nElements, offsetUvs

  init_quads_smooth: (start) ->
    nElements = @md.nquad_smooth
    if nElements
      offsetNormals   = start         + nElements * Uint32Array.BYTES_PER_ELEMENT * 4
      offsetMaterials = offsetNormals + nElements * Uint32Array.BYTES_PER_ELEMENT * 4
      
      @init_faces4_smooth nElements, start, offsetNormals, offsetMaterials

  init_quads_smooth_uv: (start) ->
    nElements = @md.nquad_smooth_uv
    if nElements
      offsetNormals   = start         + nElements * Uint32Array.BYTES_PER_ELEMENT * 4
      offsetUvs       = offsetNormals + nElements * Uint32Array.BYTES_PER_ELEMENT * 4
      offsetMaterials = offsetUvs     + nElements * Uint32Array.BYTES_PER_ELEMENT * 4
      
      @init_faces4_smooth nElements, start, offsetNormals, offsetMaterials
      @init_uvs4          nElements, offsetUvs
      
namespace "THREE", (exports) ->
  exports.BinaryLoader  = BinaryLoader
  exports.BinaryModel   = BinaryModel
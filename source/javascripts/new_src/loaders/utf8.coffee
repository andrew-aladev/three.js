# Loader for UTF8 encoded models generated by:
#	http://code.google.com/p/webgl-loader/
#
# Limitations:
#  - number of vertices < 65536 (this is after optimizations in compressor, input OBJ may have even less)
#	- models must have normals and texture coordinates
#  - texture coordinates must be only from <0,1>
#  - no materials support yet
#  - models are scaled and offset (copy numbers from compressor and use them as parameters in UTF8Loader.load() )
#
# @author alteredq / http://alteredqualia.com/
# @author won3d / http://twitter.com/won3d
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/loader
#= require new_src/core/geometry
#= require new_src/core/vector_3
#= require new_src/core/face_3
#= require new_src/core/uv

class UTF8Loader extends THREE.Loader
  load: (url, callback, metadata) ->
    xhr = new XMLHttpRequest()
    callbackProgress = null

    if metadata.scale?
      scale = metadata.scale
    else
      scale = 1
    if metadata.offsetX?
      offsetX = metadata.offsetX
    else
      offsetX = 0
    if metadata.offsetY?
      offsetY = metadata.offsetY
    else
      offsetY = 0
    if metadata.offsetZ?
      offsetZ = metadata.offsetZ
    else
      offsetZ = 0

    length = 0
    xhr.onreadystatechange = =>
      if xhr.readyState is 4
        if xhr.status is 200 or xhr.status is 0
          @createModel xhr.responseText, callback, scale, offsetX, offsetY, offsetZ
        else
          console.error "THREE.UTF8Loader: Couldn't load [", url, "] [", xhr.status, "]"
      else if xhr.readyState is 3
        if callbackProgress
          length = xhr.getResponseHeader("Content-Length") if length is 0
          callbackProgress
            total:  length
            loaded: xhr.responseText.length
      else
        length = xhr.getResponseHeader("Content-Length") if xhr.readyState is 2
  
    xhr.open "GET", url, true
    xhr.send null

# UTF-8 decoder from webgl-loader
# http://code.google.com/p/webgl-loader/
# 
# Copyright 2011 Google Inc. All Rights Reserved.
# 
# Licensed under the Apache License, Version 2.0 (the "License"); you
# may not use this file except in compliance with the License. You
# may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing
# permissions and limitations under the License.

  decompressMesh: (str) ->
    num_verts = str.charCodeAt(0)
    num_verts -= 0x0800 if num_verts >= 0xE000
    num_verts++
    attribs_out = new Float32Array 8 * num_verts
    offset = 1
  
    for i in [0...8]
      prev_attrib = 0
  
      for j in [0...num_verts]
        code        = str.charCodeAt j + offset
        prev_attrib += (code >> 1) ^ (-(code & 1))
        attribs_out[8 * j + i] = prev_attrib
      offset += num_verts

    num_indices = str.length - offset
    indices_out = new Uint16Array num_indices
    index_high_water_mark = 0
  
    for i in [0...num_indices]
      code = str.charCodeAt(i + offset)
      indices_out[i] = index_high_water_mark - code
      index_high_water_mark++ if code is 0

    [attribs_out, indices_out]

  createModel: (data, callback, scale, offsetX, offsetY, offsetZ) ->
    buffers = @decompressMesh data
    callback new UTF8Model(buffers, scale, offsetX, offsetY, offsetZ)

class UTF8Model extends THREE.Geometry  
  constructor: (buffers, scale, offsetX, offsetY, offsetZ) ->
    @materials = []
    @scale     = scale
    @offsetX   = offsetX
    @offsetY   = offsetY
    @offsetZ   = offsetZ
    super()
    
    @normals   = []
    @uvs       = []
    
    @init_vertices  buffers[0], 8, 0
    @init_uvs       buffers[0], 8, 3
    @init_normals   buffers[0], 8, 5
    @init_faces     buffers[1]
    
    @computeCentroids()
    @computeFaceNormals()
    # @computeTangents()
  
  vertex: (x, y, z) ->
    @vertices.push new THREE.Vector3(x, y, z)
  
  f3n: (a, b, c, mi, nai, nbi, nci) ->
    nax = @normals[nai * 3]
    nay = @normals[nai * 3 + 1]
    naz = @normals[nai * 3 + 2]
    nbx = @normals[nbi * 3]
    nby = @normals[nbi * 3 + 1]
    nbz = @normals[nbi * 3 + 2]
    ncx = @normals[nci * 3]
    ncy = @normals[nci * 3 + 1]
    ncz = @normals[nci * 3 + 2]
    na  = new THREE.Vector3(nax, nay, naz)
    nb  = new THREE.Vector3(nbx, nby, nbz)
    nc  = new THREE.Vector3(ncx, ncy, ncz)

    @faces.push new THREE.Face3(a, b, c, [ na, nb, nc ], null, mi)

  uv3: (u1, v1, u2, v2, u3, v3) ->
    uv = []
    uv.push new THREE.UV(u1, v1)
    uv.push new THREE.UV(u2, v2)
    uv.push new THREE.UV(u3, v3)
    @faceVertexUvs[0].push uv

  init_vertices: (data, stride, offset) ->
    length = data.length
    for i in [offset...length] by stride
      x = data[i]
      y = data[i + 1]
      z = data[i + 2]
      
      # fix scale and offsets
      x = (x / 16383) * @scale
      y = (y / 16383) * @scale
      z = (z / 16383) * @scale
      x += @offsetX
      y += @offsetY
      z += @offsetZ
      @vertex x, y, z

  init_normals: (data, stride, offset) ->
    length = data.length
    for i in [offset...length] by stride
      x = data[i]
      y = data[i + 1]
      z = data[i + 2]
      
      # normalize to <-1,1>
      x = (x - 512) / 511
      y = (y - 512) / 511
      z = (z - 512) / 511
      @normals.push x, y, z

  init_uvs: (data, stride, offset) ->
    length = data.length
    for i in [offset...length] by stride
      u = data[i]
      v = data[i + 1]
      
      # normalize to <0,1>
      u /= 1023
      v /= 1023
      @uvs.push u, 1 - v

  init_faces: (indices) ->
    length = indices.length
    m = 0 # all faces defaulting to material 0
    for i in [0...length] by 3
      a = indices[i]
      b = indices[i + 1]
      c = indices[i + 2]
      @f3n a, b, c, m, a, b, c
      
      u1 = @uvs[a * 2]
      v1 = @uvs[a * 2 + 1]
      u2 = @uvs[b * 2]
      v2 = @uvs[b * 2 + 1]
      u3 = @uvs[c * 2]
      v3 = @uvs[c * 2 + 1]
      @uv3 u1, v1, u2, v2, u3, v3

namespace "THREE", (exports) ->
  exports.UTF8Loader  = UTF8Loader
  exports.UTF8Model   = UTF8Model
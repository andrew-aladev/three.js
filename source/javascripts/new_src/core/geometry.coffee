# @author mr.doob / http://mrdoob.com/
# @author kile / http://kile.stravaganza.org/
# @author alteredq / http://alteredqualia.com/
# @author mikael emtinger / http://gomo.se/
# @author zz85 / http://www.lab4games.net/zz85/blog
# @author aladjev.andrew@gmail.com

#= require new_src/core/matrix_4
#= require new_src/core/face_3
#= require new_src/core/face_4
#= require new_src/core/vector_3
#= require new_src/core/vector_4

class Geometry
  constructor: ->
    @id         = THREE.GeometryCount++
    @vertices   = []
    @colors     = [] # one-to-one vertex colors, used in ParticleSystem, Line and Ribbon
    @materials  = []
    @faces      = []
    @faceUvs    = [[]]

    @faceVertexUvs  = [[]]
    @morphTargets   = []
    @morphColors    = []
    @morphNormals   = []
    @skinWeights    = []
    @skinIndices    = []
    @boundingBox    = null
    @boundingSphere = null
    @hasTangents    = false
    @dynamic        = false # unless set to true the *Arrays will be deleted once sent to a buffer.

  applyMatrix: (matrix) ->
    matrixRotation = new THREE.Matrix4()
    matrixRotation.extractRotation matrix
    i = 0
    il = @vertices.length

    while i < il
      vertex = @vertices[i]
      matrix.multiplyVector3 vertex
      i++
    i = 0
    il = @faces.length

    while i < il
      face = @faces[i]
      matrixRotation.multiplyVector3 face.normal
      j = 0
      jl = face.vertexNormals.length

      while j < jl
        matrixRotation.multiplyVector3 face.vertexNormals[j]
        j++
      matrix.multiplyVector3 face.centroid
      i++

  computeCentroids: ->
    f = undefined
    fl = undefined
    face = undefined
    f = 0
    fl = @faces.length

    while f < fl
      face = @faces[f]
      face.centroid.set 0, 0, 0
      if face instanceof THREE.Face3
        face.centroid.addSelf @vertices[face.a]
        face.centroid.addSelf @vertices[face.b]
        face.centroid.addSelf @vertices[face.c]
        face.centroid.divideScalar 3
      else if face instanceof THREE.Face4
        face.centroid.addSelf @vertices[face.a]
        face.centroid.addSelf @vertices[face.b]
        face.centroid.addSelf @vertices[face.c]
        face.centroid.addSelf @vertices[face.d]
        face.centroid.divideScalar 4
      f++

  computeFaceNormals: ->
    n = undefined
    nl = undefined
    v = undefined
    vl = undefined
    vertex = undefined
    f = undefined
    fl = undefined
    face = undefined
    vA = undefined
    vB = undefined
    vC = undefined
    cb = new THREE.Vector3()
    ab = new THREE.Vector3()
    f = 0
    fl = @faces.length

    while f < fl
      face = @faces[f]
      vA = @vertices[face.a]
      vB = @vertices[face.b]
      vC = @vertices[face.c]
      cb.sub vC, vB
      ab.sub vA, vB
      cb.crossSelf ab
      cb.normalize()  unless cb.isZero()
      face.normal.copy cb
      f++

  computeVertexNormals: ->
    # create internal buffers for reuse when calling this method repeatedly
    # (otherwise memory allocation / deallocation every frame is big resource hog)
    
    v = undefined
    vl = undefined
    f = undefined
    fl = undefined
    face = undefined
    vertices = undefined
    if @__tmpVertices is undefined
      @__tmpVertices = new Array(@vertices.length)
      vertices = @__tmpVertices
      v = 0
      vl = @vertices.length

      while v < vl
        vertices[v] = new THREE.Vector3()
        v++
      f = 0
      fl = @faces.length

      while f < fl
        face = @faces[f]
        if face instanceof THREE.Face3
          face.vertexNormals = [ new THREE.Vector3(), new THREE.Vector3(), new THREE.Vector3() ]
        else face.vertexNormals = [ new THREE.Vector3(), new THREE.Vector3(), new THREE.Vector3(), new THREE.Vector3() ]  if face instanceof THREE.Face4
        f++
    else
      vertices = @__tmpVertices
      v = 0
      vl = @vertices.length

      while v < vl
        vertices[v].set 0, 0, 0
        v++
    f = 0
    fl = @faces.length

    while f < fl
      face = @faces[f]
      if face instanceof THREE.Face3
        vertices[face.a].addSelf face.normal
        vertices[face.b].addSelf face.normal
        vertices[face.c].addSelf face.normal
      else if face instanceof THREE.Face4
        vertices[face.a].addSelf face.normal
        vertices[face.b].addSelf face.normal
        vertices[face.c].addSelf face.normal
        vertices[face.d].addSelf face.normal
      f++
    v = 0
    vl = @vertices.length

    while v < vl
      vertices[v].normalize()
      v++
    f = 0
    fl = @faces.length

    while f < fl
      face = @faces[f]
      if face instanceof THREE.Face3
        face.vertexNormals[0].copy vertices[face.a]
        face.vertexNormals[1].copy vertices[face.b]
        face.vertexNormals[2].copy vertices[face.c]
      else if face instanceof THREE.Face4
        face.vertexNormals[0].copy vertices[face.a]
        face.vertexNormals[1].copy vertices[face.b]
        face.vertexNormals[2].copy vertices[face.c]
        face.vertexNormals[3].copy vertices[face.d]
      f++

  computeMorphNormals: ->
    # save original normals
    # - create temp variables on first access
    #   otherwise just copy (for faster repeated calls)
    
    i = undefined
    il = undefined
    f = undefined
    fl = undefined
    face = undefined
    f = 0
    fl = @faces.length

    while f < fl
      face = @faces[f]
      unless face.__originalFaceNormal
        face.__originalFaceNormal = face.normal.clone()
      else
        face.__originalFaceNormal.copy face.normal
      face.__originalVertexNormals = []  unless face.__originalVertexNormals
      i = 0
      il = face.vertexNormals.length

      while i < il
        unless face.__originalVertexNormals[i]
          face.__originalVertexNormals[i] = face.vertexNormals[i].clone()
        else
          face.__originalVertexNormals[i].copy face.vertexNormals[i]
        i++
      f++
      
    # use temp geometry to compute face and vertex normals for each morph
    tmpGeo = new Geometry()
    tmpGeo.faces = @faces
    i = 0
    il = @morphTargets.length

    while i < il
      # create on first access
    
      unless @morphNormals[i]
        @morphNormals[i] = {}
        @morphNormals[i].faceNormals = []
        @morphNormals[i].vertexNormals = []
        dstNormalsFace = @morphNormals[i].faceNormals
        dstNormalsVertex = @morphNormals[i].vertexNormals
        faceNormal = undefined
        vertexNormals = undefined
        f = 0
        fl = @faces.length

        while f < fl
          face = @faces[f]
          faceNormal = new THREE.Vector3()
          if face instanceof THREE.Face3
            vertexNormals =
              a: new THREE.Vector3()
              b: new THREE.Vector3()
              c: new THREE.Vector3()
          else
            vertexNormals =
              a: new THREE.Vector3()
              b: new THREE.Vector3()
              c: new THREE.Vector3()
              d: new THREE.Vector3()
          dstNormalsFace.push faceNormal
          dstNormalsVertex.push vertexNormals
          f++
      morphNormals = @morphNormals[i]
      
      # set vertices to morph target
      tmpGeo.vertices = @morphTargets[i].vertices
      
      # compute morph normals
      tmpGeo.computeFaceNormals()
      tmpGeo.computeVertexNormals()
      
      # store morph normals
      faceNormal = undefined
      vertexNormals = undefined
      f = 0
      fl = @faces.length

      # restore original normals
      while f < fl
        face = @faces[f]
        faceNormal = morphNormals.faceNormals[f]
        vertexNormals = morphNormals.vertexNormals[f]
        faceNormal.copy face.normal
        if face instanceof THREE.Face3
          vertexNormals.a.copy face.vertexNormals[0]
          vertexNormals.b.copy face.vertexNormals[1]
          vertexNormals.c.copy face.vertexNormals[2]
        else
          vertexNormals.a.copy face.vertexNormals[0]
          vertexNormals.b.copy face.vertexNormals[1]
          vertexNormals.c.copy face.vertexNormals[2]
          vertexNormals.d.copy face.vertexNormals[3]
        f++
      i++
    f = 0
    fl = @faces.length

    while f < fl
      face = @faces[f]
      face.normal = face.__originalFaceNormal
      face.vertexNormals = face.__originalVertexNormals
      f++

  computeTangents: ->
    # based on http://www.terathon.com/code/tangent.html
    # tangents go to vertices
    
    handleTriangle = (context, a, b, c, ua, ub, uc) ->
      vA = context.vertices[a]
      vB = context.vertices[b]
      vC = context.vertices[c]
      uvA = uv[ua]
      uvB = uv[ub]
      uvC = uv[uc]
      x1 = vB.x - vA.x
      x2 = vC.x - vA.x
      y1 = vB.y - vA.y
      y2 = vC.y - vA.y
      z1 = vB.z - vA.z
      z2 = vC.z - vA.z
      s1 = uvB.u - uvA.u
      s2 = uvC.u - uvA.u
      t1 = uvB.v - uvA.v
      t2 = uvC.v - uvA.v
      r = 1.0 / (s1 * t2 - s2 * t1)
      sdir.set (t2 * x1 - t1 * x2) * r, (t2 * y1 - t1 * y2) * r, (t2 * z1 - t1 * z2) * r
      tdir.set (s1 * x2 - s2 * x1) * r, (s1 * y2 - s2 * y1) * r, (s1 * z2 - s2 * z1) * r
      tan1[a].addSelf sdir
      tan1[b].addSelf sdir
      tan1[c].addSelf sdir
      tan2[a].addSelf tdir
      tan2[b].addSelf tdir
      tan2[c].addSelf tdir
    f = undefined
    fl = undefined
    v = undefined
    vl = undefined
    i = undefined
    il = undefined
    vertexIndex = undefined
    face = undefined
    uv = undefined
    vA = undefined
    vB = undefined
    vC = undefined
    uvA = undefined
    uvB = undefined
    uvC = undefined
    x1 = undefined
    x2 = undefined
    y1 = undefined
    y2 = undefined
    z1 = undefined
    z2 = undefined
    s1 = undefined
    s2 = undefined
    t1 = undefined
    t2 = undefined
    r = undefined
    t = undefined
    test = undefined
    tan1 = []
    tan2 = []
    sdir = new THREE.Vector3()
    tdir = new THREE.Vector3()
    tmp = new THREE.Vector3()
    tmp2 = new THREE.Vector3()
    n = new THREE.Vector3()
    w = undefined
    v = 0
    vl = @vertices.length

    while v < vl
      tan1[v] = new THREE.Vector3()
      tan2[v] = new THREE.Vector3()
      v++
    f = 0
    fl = @faces.length

    while f < fl
      face = @faces[f]
      uv = @faceVertexUvs[0][f] # use UV layer 0 for tangents
      if face instanceof THREE.Face3
        handleTriangle this, face.a, face.b, face.c, 0, 1, 2
      else if face instanceof THREE.Face4
        handleTriangle this, face.a, face.b, face.d, 0, 1, 3
        handleTriangle this, face.b, face.c, face.d, 1, 2, 3
      f++
    faceIndex = [ "a", "b", "c", "d" ]
    f = 0
    fl = @faces.length

    while f < fl
      face = @faces[f]
      i = 0
      while i < face.vertexNormals.length
        n.copy face.vertexNormals[i]
        vertexIndex = face[faceIndex[i]]
        t = tan1[vertexIndex]
        
        # Gram-Schmidt orthogonalize
        tmp.copy t
        tmp.subSelf(n.multiplyScalar(n.dot(t))).normalize()
        
        # Calculate handedness
        tmp2.cross face.vertexNormals[i], t
        test = tmp2.dot(tan2[vertexIndex])
        w = (if (test < 0.0) then -1.0 else 1.0)
        face.vertexTangents[i] = new THREE.Vector4(tmp.x, tmp.y, tmp.z, w)
        i++
      f++
    @hasTangents = true

  computeBoundingBox: ->
    unless @boundingBox
      @boundingBox =
        min: new THREE.Vector3()
        max: new THREE.Vector3()
    if @vertices.length > 0
      position = undefined
      firstPosition = @vertices[0]
      @boundingBox.min.copy firstPosition
      @boundingBox.max.copy firstPosition
      min = @boundingBox.min
      max = @boundingBox.max
      v = 1
      vl = @vertices.length

      while v < vl
        position = @vertices[v]
        if position.x < min.x
          min.x = position.x
        else max.x = position.x  if position.x > max.x
        if position.y < min.y
          min.y = position.y
        else max.y = position.y  if position.y > max.y
        if position.z < min.z
          min.z = position.z
        else max.z = position.z  if position.z > max.z
        v++
    else
      @boundingBox.min.set 0, 0, 0
      @boundingBox.max.set 0, 0, 0

  computeBoundingSphere: ->
    @boundingSphere = radius: 0  unless @boundingSphere
    radius = undefined
    maxRadius = 0
    v = 0
    vl = @vertices.length

    while v < vl
      radius = @vertices[v].length()
      maxRadius = radius  if radius > maxRadius
      v++
    @boundingSphere.radius = maxRadius

   # Checks for duplicate vertices with hashmap.
   # Duplicated vertices are removed
   # and faces' vertices are updated.

  mergeVertices: ->
    verticesMap = {} # Hashmap for looking up vertice by position coordinates (and making sure they are unique)
    unique = []
    changes = []
    v = undefined
    key = undefined
    precisionPoints = 4 # number of decimal points, eg. 4 for epsilon of 0.0001
    precision = Math.pow(10, precisionPoints)
    i = undefined
    il = undefined
    face = undefined
    abcd = "abcd"
    o = undefined
    k = undefined
    j = undefined
    jl = undefined
    u = undefined
    i = 0
    il = @vertices.length

    while i < il
      v = @vertices[i]
      key = [ Math.round(v.x * precision), Math.round(v.y * precision), Math.round(v.z * precision) ].join("_")
      if verticesMap[key] is undefined
        verticesMap[key] = i
        unique.push @vertices[i]
        changes[i] = unique.length - 1
      else
        # console.log('Duplicate vertex found. ', i, ' could be using ', verticesMap[key]);
        changes[i] = changes[verticesMap[key]]
      i++
    i = 0
    il = @faces.length

    # Start to patch face indices
    while i < il
      face = @faces[i]
      if face instanceof THREE.Face3
        face.a = changes[face.a]
        face.b = changes[face.b]
        face.c = changes[face.c]
      else if face instanceof THREE.Face4
        face.a = changes[face.a]
        face.b = changes[face.b]
        face.c = changes[face.c]
        face.d = changes[face.d]
        
        # check dups in (a, b, c, d) and convert to -> face3
        o = [ face.a, face.b, face.c, face.d ]
        k = 3
        while k > 0
          unless o.indexOf(face[abcd[k]]) is k
          
            # console.log('faces', face.a, face.b, face.c, face.d, 'dup at', k);
            o.splice k, 1
            @faces[i] = new THREE.Face3(o[0], o[1], o[2])
            j = 0
            jl = @faceVertexUvs.length

            while j < jl
              u = @faceVertexUvs[j][i]
              u.splice k, 1  if u
              j++
            break
          k--
      i++
      
    # Use unique set of vertices
    diff = @vertices.length - unique.length
    @vertices = unique
    diff

namespace "THREE", (exports) ->
  exports.Geometry      = Geometry
  exports.GeometryCount = 0

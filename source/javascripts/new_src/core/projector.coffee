# @author mr.doob / http://mrdoob.com/
# @author supereggbert / http://www.paulbrunt.co.uk/
# @author julianwa / https://github.com/julianwa
# @author aladjev.andrew@gmail.com

#= require new_src/core/matrix_4
#= require new_src/core/vector_3
#= require new_src/core/vector_4
#= require new_src/core/frustum
#= require new_src/core/ray

class Projector
  constructor: ->
    @_object         = undefined
    @_objectCount    = undefined
    @_objectPool     = []
    @_vertex         = undefined
    @_vertexCount    = undefined
    @_vertexPool     = []
    @_face           = undefined
    @_face3Count     = undefined
    @_face3Pool      = []
    @_face4Count     = undefined
    @_face4Pool      = []
    @_line           = undefined
    @_lineCount      = undefined
    @_linePool       = []
    @_particle       = undefined
    @_particleCount  = undefined
    @_particlePool   = []
    @_renderData =
      objects:  []
      sprites:  []
      lights:   []
      elements: []
  
    @_vector3 = new THREE.Vector3()
    @_vector4 = new THREE.Vector4()
    @_projScreenMatrix            = new THREE.Matrix4()
    @_projScreenobjectMatrixWorld = new THREE.Matrix4()
    @_frustum = new THREE.Frustum()
    @_clippedVertex1PositionScreen = new THREE.Vector4()
    @_clippedVertex2PositionScreen = new THREE.Vector4()
    @_face3VertexNormals = undefined

  getNextObjectInPool: ->
    object = @_objectPool[@_objectCount] = @_objectPool[@_objectCount] or new THREE.RenderableObject()
    @_objectCount++
    object

  getNextVertexInPool: ->
    vertex = @_vertexPool[@_vertexCount] = @_vertexPool[@_vertexCount] or new THREE.RenderableVertex()
    @_vertexCount++
    vertex

  getNextFace3InPool: ->
    face = @_face3Pool[@_face3Count] = @_face3Pool[@_face3Count] or new THREE.RenderableFace3()
    @_face3Count++
    face

  getNextFace4InPool: ->
    face = @_face4Pool[@_face4Count] = @_face4Pool[@_face4Count] or new THREE.RenderableFace4()
    @_face4Count++
    face

  getNextLineInPool: ->
    line = @_linePool[@_lineCount] = @_linePool[@_lineCount] or new THREE.RenderableLine()
    @_lineCount++
    line

  getNextParticleInPool: ->
    particle = @_particlePool[@_particleCount] = @_particlePool[@_particleCount] or new THREE.RenderableParticle()
    @_particleCount++
    particle

  @painterSort: (a, b) ->
    b.z - a.z

  clipLine: (s1, s2) ->
    # Calculate the boundary coordinate of each vertex for the near and far clip planes,
    # Z = -1 and Z = +1, respectively.
  
    alpha1  = 0
    alpha2  = 1
    bc1near = s1.z + s1.w
    bc2near = s2.z + s2.w
    bc1far  = -s1.z + s1.w
    bc2far  = -s2.z + s2.w
    if bc1near >= 0 and bc2near >= 0 and bc1far >= 0 and bc2far >= 0
      # Both vertices lie entirely within all clip planes.
      true
    else if (bc1near < 0 and bc2near < 0) or (bc1far < 0 and bc2far < 0)
      # Both vertices lie entirely outside one of the clip planes.
      false
    else
    
      # The line segment spans at least one clip plane.
      if bc1near < 0
      
        # v1 lies outside the near plane, v2 inside
        alpha1 = Math.max(alpha1, bc1near / (bc1near - bc2near))
      else if bc2near < 0
        
        # v2 lies outside the near plane, v1 inside
        alpha2 = Math.min(alpha2, bc1near / (bc1near - bc2near))
      if bc1far < 0
      
        # v1 lies outside the far plane, v2 inside
        alpha1 = Math.max(alpha1, bc1far / (bc1far - bc2far))
      else if bc2far < 0
        
        # v2 lies outside the far plane, v2 inside
        alpha2 = Math.min(alpha2, bc1far / (bc1far - bc2far))
      if alpha2 < alpha1
      
        # The line segment spans two boundaries, but is outside both of them.
        # (This can't happen when we're only clipping against just near/far but good
        #  to leave the check here for future usage if other clip planes are added.)
        false
      else
      
        # Update the s1 and s2 vertices to match the clipped line segment.
        s1.lerpSelf s2, alpha1
        s2.lerpSelf s1, 1 - alpha2
        true

  
  projectVector: (vector, camera) ->
    camera.matrixWorldInverse.getInverse camera.matrixWorld
    @_projScreenMatrix.multiply camera.projectionMatrix, camera.matrixWorldInverse
    @_projScreenMatrix.multiplyVector3 vector
    vector

  unprojectVector: (vector, camera) ->
    camera.projectionMatrixInverse.getInverse camera.projectionMatrix
    @_projScreenMatrix.multiply camera.matrixWorld, camera.projectionMatrixInverse
    @_projScreenMatrix.multiplyVector3 vector
    vector

  pickingRay: (vector, camera) ->
    # set two vectors with opposing z values
    end = undefined
    ray = undefined
    t = undefined
    vector.z = -1.0
    end = new THREE.Vector3(vector.x, vector.y, 1.0)
    @unprojectVector vector, camera
    @unprojectVector end, camera
    
    # find direction from vector to end
    end.subSelf(vector).normalize()
    new THREE.Ray(vector, end)

  projectGraph: (root, sort) ->
    @_objectCount = 0
    @_renderData.objects.length = 0
    @_renderData.sprites.length = 0
    @_renderData.lights.length = 0
    projectObject = (object) ->
      return  if object.visible is false
      if (object instanceof THREE.Mesh or object instanceof THREE.Line) and (object.frustumCulled is false or @_frustum.contains(object))
        @_vector3.copy object.matrixWorld.getPosition()
        @_projScreenMatrix.multiplyVector3 @_vector3
        @_object = getNextObjectInPool()
        @_object.object = object
        @_object.z = @_vector3.z
        @_renderData.objects.push @_object
      else if object instanceof THREE.Sprite or object instanceof THREE.Particle
        @_vector3.copy object.matrixWorld.getPosition()
        @_projScreenMatrix.multiplyVector3 @_vector3
        @_object = getNextObjectInPool()
        @_object.object = object
        @_object.z = @_vector3.z
        @_renderData.sprites.push @_object
      else @_renderData.lights.push object  if object instanceof THREE.Light
      c = 0
      cl = object.children.length

      while c < cl
        projectObject object.children[c]
        c++

    projectObject root
    sort and @_renderData.objects.sort(@painterSort)
    @_renderData

  projectScene: (scene, camera, sort) ->
    near = camera.near
    far = camera.far
    visible = false
    o = undefined
    ol = undefined
    v = undefined
    vl = undefined
    f = undefined
    fl = undefined
    n = undefined
    nl = undefined
    c = undefined
    cl = undefined
    u = undefined
    ul = undefined
    object = undefined
    objectMatrixWorld = undefined
    objectMatrixWorldRotation = undefined
    geometry = undefined
    geometryMaterials = undefined
    vertices = undefined
    vertex = undefined
    vertexPositionScreen = undefined
    faces = undefined
    face = undefined
    faceVertexNormals = undefined
    normal = undefined
    faceVertexUvs = undefined
    uvs = undefined
    v1 = undefined
    v2 = undefined
    v3 = undefined
    v4 = undefined
    @_face3Count = 0
    @_face4Count = 0
    @_lineCount = 0
    @_particleCount = 0
    @_renderData.elements.length = 0
    if camera.parent is undefined
      console.warn "DEPRECATED: Camera hasn't been added to a Scene. Adding it..."
      scene.add camera
    scene.updateMatrixWorld()
    camera.matrixWorldInverse.getInverse camera.matrixWorld
    @_projScreenMatrix.multiply camera.projectionMatrix, camera.matrixWorldInverse
    @_frustum.setFromMatrix @_projScreenMatrix
    @_renderData = @projectGraph(scene, false)
    o = 0
    ol = @_renderData.objects.length

    while o < ol
      object = @_renderData.objects[o].object
      objectMatrixWorld = object.matrixWorld
      @_vertexCount = 0
      if object instanceof THREE.Mesh
        geometry = object.geometry
        geometryMaterials = object.geometry.materials
        vertices = geometry.vertices
        faces = geometry.faces
        faceVertexUvs = geometry.faceVertexUvs
        objectMatrixWorldRotation = object.matrixRotationWorld.extractRotation(objectMatrixWorld)
        v = 0
        vl = vertices.length

        while v < vl
          @_vertex = getNextVertexInPool()
          @_vertex.positionWorld.copy vertices[v]
          objectMatrixWorld.multiplyVector3 @_vertex.positionWorld
          @_vertex.positionScreen.copy @_vertex.positionWorld
          @_projScreenMatrix.multiplyVector4 @_vertex.positionScreen
          @_vertex.positionScreen.x /= @_vertex.positionScreen.w
          @_vertex.positionScreen.y /= @_vertex.positionScreen.w
          @_vertex.visible = @_vertex.positionScreen.z > near and @_vertex.positionScreen.z < far
          v++
        f = 0
        fl = faces.length

        while f < fl
          face = faces[f]
          if face instanceof THREE.Face3
            v1 = @_vertexPool[face.a]
            v2 = @_vertexPool[face.b]
            v3 = @_vertexPool[face.c]
            if v1.visible and v2.visible and v3.visible
              visible = (v3.positionScreen.x - v1.positionScreen.x) * (v2.positionScreen.y - v1.positionScreen.y) - (v3.positionScreen.y - v1.positionScreen.y) * (v2.positionScreen.x - v1.positionScreen.x) < 0
              if object.doubleSided or visible isnt object.flipSided
                @_face = getNextFace3InPool()
                @_face.v1.copy v1
                @_face.v2.copy v2
                @_face.v3.copy v3
              else
                continue
            else
              continue
          else if face instanceof THREE.Face4
            v1 = @_vertexPool[face.a]
            v2 = @_vertexPool[face.b]
            v3 = @_vertexPool[face.c]
            v4 = @_vertexPool[face.d]
            if v1.visible and v2.visible and v3.visible and v4.visible
              visible = (v4.positionScreen.x - v1.positionScreen.x) * (v2.positionScreen.y - v1.positionScreen.y) - (v4.positionScreen.y - v1.positionScreen.y) * (v2.positionScreen.x - v1.positionScreen.x) < 0 or (v2.positionScreen.x - v3.positionScreen.x) * (v4.positionScreen.y - v3.positionScreen.y) - (v2.positionScreen.y - v3.positionScreen.y) * (v4.positionScreen.x - v3.positionScreen.x) < 0
              if object.doubleSided or visible isnt object.flipSided
                @_face = getNextFace4InPool()
                @_face.v1.copy v1
                @_face.v2.copy v2
                @_face.v3.copy v3
                @_face.v4.copy v4
              else
                continue
            else
              continue
          @_face.normalWorld.copy face.normal
          @_face.normalWorld.negate()  if not visible and (object.flipSided or object.doubleSided)
          objectMatrixWorldRotation.multiplyVector3 @_face.normalWorld
          @_face.centroidWorld.copy face.centroid
          objectMatrixWorld.multiplyVector3 @_face.centroidWorld
          @_face.centroidScreen.copy @_face.centroidWorld
          @_projScreenMatrix.multiplyVector3 @_face.centroidScreen
          faceVertexNormals = face.vertexNormals
          n = 0
          nl = faceVertexNormals.length

          while n < nl
            normal = @_face.vertexNormalsWorld[n]
            normal.copy faceVertexNormals[n]
            normal.negate()  if not visible and (object.flipSided or object.doubleSided)
            objectMatrixWorldRotation.multiplyVector3 normal
            n++
          c = 0
          cl = faceVertexUvs.length

          while c < cl
            uvs = faceVertexUvs[c][f]
            continue  unless uvs
            u = 0
            ul = uvs.length

            while u < ul
              @_face.uvs[c][u] = uvs[u]
              u++
            c++
          @_face.material = object.material
          @_face.faceMaterial = (if face.materialIndex isnt null then geometryMaterials[face.materialIndex] else null)
          @_face.z = @_face.centroidScreen.z
          @_renderData.elements.push @_face
          f++
      else if object instanceof THREE.Line
        @_projScreenobjectMatrixWorld.multiply @_projScreenMatrix, objectMatrixWorld
        vertices = object.geometry.vertices
        v1 = getNextVertexInPool()
        v1.positionScreen.copy vertices[0]
        @_projScreenobjectMatrixWorld.multiplyVector4 v1.positionScreen
        
        # Handle LineStrip and LinePieces
        step = (if object.type is THREE.LinePieces then 2 else 1)
        v = 1
        vl = vertices.length

        while v < vl
          v1 = getNextVertexInPool()
          v1.positionScreen.copy vertices[v]
          @_projScreenobjectMatrixWorld.multiplyVector4 v1.positionScreen
          continue  if (v + 1) % step > 0
          v2 = @_vertexPool[@_vertexCount - 2]
          @_clippedVertex1PositionScreen.copy v1.positionScreen
          @_clippedVertex2PositionScreen.copy v2.positionScreen
          if clipLine(@_clippedVertex1PositionScreen, @_clippedVertex2PositionScreen)
          
            # Perform the perspective divide
            @_clippedVertex1PositionScreen.multiplyScalar 1 / @_clippedVertex1PositionScreen.w
            @_clippedVertex2PositionScreen.multiplyScalar 1 / @_clippedVertex2PositionScreen.w
            @_line = getNextLineInPool()
            @_line.v1.positionScreen.copy @_clippedVertex1PositionScreen
            @_line.v2.positionScreen.copy @_clippedVertex2PositionScreen
            @_line.z = Math.max(@_clippedVertex1PositionScreen.z, @_clippedVertex2PositionScreen.z)
            @_line.material = object.material
            @_renderData.elements.push @_line
          v++
      o++
    o = 0
    ol = @_renderData.sprites.length

    while o < ol
      object = @_renderData.sprites[o].object
      objectMatrixWorld = object.matrixWorld
      if object instanceof THREE.Particle
        @_vector4.set objectMatrixWorld.elements[12], objectMatrixWorld.elements[13], objectMatrixWorld.elements[14], 1
        @_projScreenMatrix.multiplyVector4 @_vector4
        @_vector4.z /= @_vector4.w
        if @_vector4.z > 0 and @_vector4.z < 1
          @_particle = getNextParticleInPool()
          @_particle.x = @_vector4.x / @_vector4.w
          @_particle.y = @_vector4.y / @_vector4.w
          @_particle.z = @_vector4.z
          @_particle.rotation = object.rotation.z
          @_particle.scale.x = object.scale.x * Math.abs(@_particle.x - (@_vector4.x + camera.projectionMatrix.elements[0]) / (@_vector4.w + camera.projectionMatrix.elements[12]))
          @_particle.scale.y = object.scale.y * Math.abs(@_particle.y - (@_vector4.y + camera.projectionMatrix.elements[5]) / (@_vector4.w + camera.projectionMatrix.elements[13]))
          @_particle.material = object.material
          @_renderData.elements.push @_particle
      o++
    sort and @_renderData.elements.sort(@painterSort)
    @_renderData
    
namespace "THREE", (exports) ->
  exports.Projector = Projector
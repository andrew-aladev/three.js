# @author mr.doob / http://mrdoob.com/
# @author supereggbert / http://www.paulbrunt.co.uk/
# @author julianwa / https://github.com/julianwa

class window.Three::Projector
  constructor: ->
    @_object          = undefined
    @_object_count    = undefined
    @_object_pool     = []
    @_vertex          = undefined
    @_vertex_count    = undefined
    @_vertex_pool     = []
    @_face            = undefined
    @_face_3_count    = undefined
    @_face_3_pool     = []
    @_face_4_count    = undefined
    @_face_4_pool     = []
    @_line            = undefined
    @_line_count      = undefined
    @_line_pool       = []
    @_particle        = undefined
    @_particle_count  = undefined
    @_particle_pool   = []
    @_render_data =
      objects:  []
      sprites:  []
      lights:   []
      elements: []
  
    @_vector_3  = new Three::Vector3()
    @_vector_4  = new Three::Vector4()
    @_proj_screen_matrix              = new Three::Matrix4()
    @_proj_screenobject_matrix_world  = new Three::Matrix4()
    
    @_frustum = new Three::Frustum()
    @_clipped_vertex_1_position_screen  = new Three::Vector4()
    @_clipped_vertex_2_position_screen  = new Three::Vector4()
    @_face_3_vertex_normals             = undefined

  get_next_object_in_pool: ->
    object = @_object_pool[@_object_count] = @_object_pool[@_object_count] or new Three::RenderableObject()
    @_object_count++
    object

  get_next_vertex_in_pool: ->
    vertex = @_vertex_pool[@_vertex_count] = @_vertex_pool[@_vertex_count] or new Three::RenderableVertex()
    @_vertexCount++
    vertex

  get_next_face_3_in_pool: ->
    face = @_face_3_pool[@_face_3_count] = @_face_3_pool[@_face_3_count] or new Three::RenderableFace3()
    @_face_3_count++
    face

  get_next_face_4_in_pool: ->
    face = @_face_4_pool[@_face_4_count] = @_face_4_pool[@_face_4_count] or new Three::RenderableFace4()
    @_face_4_count++
    face

  get_next_line_in_pool: ->
    line = @_line_pool[@_line_count] = @_line_pool[@_line_count] or new Three::RenderableLine()
    @_lineCount++
    line

  get_next_particle_in_pool: ->
    particle = @_particle_pool[@_particle_count] = @_particle_pool[@_particle_count] or new Three::RenderableParticle()
    @_particleCount++
    particle

  clip_line: (s1, s2) ->
    alpha1  = 0
    alpha2  = 1
    bc1near = s1.z + s1.w
    bc2near = s2.z + s2.w
    bc1far  = -s1.z + s1.w
    bc2far  = -s2.z + s2.w
    if bc1near >= 0 and bc2near >= 0 and bc1far >= 0 and bc2far >= 0
      true
    else if (bc1near < 0 and bc2near < 0) or (bc1far < 0 and bc2far < 0)
      false
    else
      if bc1near < 0
        alpha1 = Math.max(alpha1, bc1near / (bc1near - bc2near))
      else alpha2 = Math.min(alpha2, bc1near / (bc1near - bc2near)) if bc2near < 0
      if bc1far < 0
        alpha1 = Math.max(alpha1, bc1far / (bc1far - bc2far))
      else alpha2 = Math.min(alpha2, bc1far / (bc1far - bc2far)) if bc2far < 0
      if alpha2 < alpha1
        false
      else
        s1.lerp_self s2, alpha1
        s2.lerp_self s1, 1 - alpha2
        true

  
  project_vector: (vector, camera) ->
    camera.matrix_world_inverse.get_inverse camera.matrix_world
    @_proj_screen_matrix.multiply camera.projection_matrix, camera.matrix_world_inverse
    @_proj_screen_matrix.multiply_vector_3 vector
    vector

  unproject_vector: (vector, camera) ->
    camera.projection_matrix_inverse.get_inverse camera.projection_matrix
    @_proj_screen_matrix.multiply camera.matrix_world, camera.projection_matrix_inverse
    @_proj_screen_matrix.multiply_vector_3 vector
    vector

  picking_ray: (vector, camera) ->
    end       = undefined
    ray       = undefined
    t         = undefined
    vector.z  = -1.0
    end       = new Three::Vector3 vector.x, vector.y, 1.0
    @unproject_vector vector, camera
    @unproject_vector end, camera
    end.sub_self(vector).normalize()
    new Three::Ray vector, end

  project_graph: (root, sort) ->
    @_objectCount = 0
    @_render_data.objects.length  = 0
    @_render_data.sprites.length  = 0
    @_render_data.lights.length   = 0
    
    @project_object root
    sort and @_render_data.objects.sort (a, b) ->
      b.z - a.z
    @_render_data
    
  project_object: (object) ->
    return if object.visible is false
    if (object instanceof Three::Mesh or object instanceof THREE.Line) and (object.frustumCulled is false or _frustum.contains(object))
      _vector3.copy object.matrixWorld.getPosition()
      _projScreenMatrix.multiplyVector3 _vector3
      _object = getNextObjectInPool()
      _object.object = object
      _object.z = _vector3.z
      _renderData.objects.push _object
    else if object instanceof THREE.Sprite or object instanceof THREE.Particle
      _vector3.copy object.matrixWorld.getPosition()
      _projScreenMatrix.multiplyVector3 _vector3
      _object = getNextObjectInPool()
      _object.object = object
      _object.z = _vector3.z
      _renderData.sprites.push _object
    else _renderData.lights.push object  if object instanceof THREE.Light
    c = 0
    cl = object.children.length

    while c < cl
      projectObject object.children[c]
      c++

  @projectScene = (scene, camera, sort) ->
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
    _face3Count = 0
    _face4Count = 0
    _lineCount = 0
    _particleCount = 0
    _renderData.elements.length = 0
    if camera.parent is `undefined`
      console.warn "DEPRECATED: Camera hasn't been added to a Scene. Adding it..."
      scene.add camera
    scene.updateMatrixWorld()
    camera.matrixWorldInverse.getInverse camera.matrixWorld
    _projScreenMatrix.multiply camera.projectionMatrix, camera.matrixWorldInverse
    _frustum.setFromMatrix _projScreenMatrix
    _renderData = @projectGraph(scene, false)
    o = 0
    ol = _renderData.objects.length

    while o < ol
      object = _renderData.objects[o].object
      objectMatrixWorld = object.matrixWorld
      _vertexCount = 0
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
          _vertex = getNextVertexInPool()
          _vertex.positionWorld.copy vertices[v]
          objectMatrixWorld.multiplyVector3 _vertex.positionWorld
          _vertex.positionScreen.copy _vertex.positionWorld
          _projScreenMatrix.multiplyVector4 _vertex.positionScreen
          _vertex.positionScreen.x /= _vertex.positionScreen.w
          _vertex.positionScreen.y /= _vertex.positionScreen.w
          _vertex.visible = _vertex.positionScreen.z > near and _vertex.positionScreen.z < far
          v++
        f = 0
        fl = faces.length

        while f < fl
          face = faces[f]
          if face instanceof THREE.Face3
            v1 = _vertexPool[face.a]
            v2 = _vertexPool[face.b]
            v3 = _vertexPool[face.c]
            if v1.visible and v2.visible and v3.visible
              visible = (v3.positionScreen.x - v1.positionScreen.x) * (v2.positionScreen.y - v1.positionScreen.y) - (v3.positionScreen.y - v1.positionScreen.y) * (v2.positionScreen.x - v1.positionScreen.x) < 0
              if object.doubleSided or visible isnt object.flipSided
                _face = getNextFace3InPool()
                _face.v1.copy v1
                _face.v2.copy v2
                _face.v3.copy v3
              else
                continue
            else
              continue
          else if face instanceof THREE.Face4
            v1 = _vertexPool[face.a]
            v2 = _vertexPool[face.b]
            v3 = _vertexPool[face.c]
            v4 = _vertexPool[face.d]
            if v1.visible and v2.visible and v3.visible and v4.visible
              visible = (v4.positionScreen.x - v1.positionScreen.x) * (v2.positionScreen.y - v1.positionScreen.y) - (v4.positionScreen.y - v1.positionScreen.y) * (v2.positionScreen.x - v1.positionScreen.x) < 0 or (v2.positionScreen.x - v3.positionScreen.x) * (v4.positionScreen.y - v3.positionScreen.y) - (v2.positionScreen.y - v3.positionScreen.y) * (v4.positionScreen.x - v3.positionScreen.x) < 0
              if object.doubleSided or visible isnt object.flipSided
                _face = getNextFace4InPool()
                _face.v1.copy v1
                _face.v2.copy v2
                _face.v3.copy v3
                _face.v4.copy v4
              else
                continue
            else
              continue
          _face.normalWorld.copy face.normal
          _face.normalWorld.negate()  if not visible and (object.flipSided or object.doubleSided)
          objectMatrixWorldRotation.multiplyVector3 _face.normalWorld
          _face.centroidWorld.copy face.centroid
          objectMatrixWorld.multiplyVector3 _face.centroidWorld
          _face.centroidScreen.copy _face.centroidWorld
          _projScreenMatrix.multiplyVector3 _face.centroidScreen
          faceVertexNormals = face.vertexNormals
          n = 0
          nl = faceVertexNormals.length

          while n < nl
            normal = _face.vertexNormalsWorld[n]
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
              _face.uvs[c][u] = uvs[u]
              u++
            c++
          _face.material = object.material
          _face.faceMaterial = (if face.materialIndex isnt null then geometryMaterials[face.materialIndex] else null)
          _face.z = _face.centroidScreen.z
          _renderData.elements.push _face
          f++
      else if object instanceof THREE.Line
        _projScreenobjectMatrixWorld.multiply _projScreenMatrix, objectMatrixWorld
        vertices = object.geometry.vertices
        v1 = getNextVertexInPool()
        v1.positionScreen.copy vertices[0]
        _projScreenobjectMatrixWorld.multiplyVector4 v1.positionScreen
        step = (if object.type is THREE.LinePieces then 2 else 1)
        v = 1
        vl = vertices.length

        while v < vl
          v1 = getNextVertexInPool()
          v1.positionScreen.copy vertices[v]
          _projScreenobjectMatrixWorld.multiplyVector4 v1.positionScreen
          continue  if (v + 1) % step > 0
          v2 = _vertexPool[_vertexCount - 2]
          _clippedVertex1PositionScreen.copy v1.positionScreen
          _clippedVertex2PositionScreen.copy v2.positionScreen
          if clipLine(_clippedVertex1PositionScreen, _clippedVertex2PositionScreen)
            _clippedVertex1PositionScreen.multiplyScalar 1 / _clippedVertex1PositionScreen.w
            _clippedVertex2PositionScreen.multiplyScalar 1 / _clippedVertex2PositionScreen.w
            _line = getNextLineInPool()
            _line.v1.positionScreen.copy _clippedVertex1PositionScreen
            _line.v2.positionScreen.copy _clippedVertex2PositionScreen
            _line.z = Math.max(_clippedVertex1PositionScreen.z, _clippedVertex2PositionScreen.z)
            _line.material = object.material
            _renderData.elements.push _line
          v++
      o++
    o = 0
    ol = _renderData.sprites.length

    while o < ol
      object = _renderData.sprites[o].object
      objectMatrixWorld = object.matrixWorld
      if object instanceof THREE.Particle
        _vector4.set objectMatrixWorld.elements[12], objectMatrixWorld.elements[13], objectMatrixWorld.elements[14], 1
        _projScreenMatrix.multiplyVector4 _vector4
        _vector4.z /= _vector4.w
        if _vector4.z > 0 and _vector4.z < 1
          _particle = getNextParticleInPool()
          _particle.x = _vector4.x / _vector4.w
          _particle.y = _vector4.y / _vector4.w
          _particle.z = _vector4.z
          _particle.rotation = object.rotation.z
          _particle.scale.x = object.scale.x * Math.abs(_particle.x - (_vector4.x + camera.projectionMatrix.elements[0]) / (_vector4.w + camera.projectionMatrix.elements[12]))
          _particle.scale.y = object.scale.y * Math.abs(_particle.y - (_vector4.y + camera.projectionMatrix.elements[5]) / (_vector4.w + camera.projectionMatrix.elements[13]))
          _particle.material = object.material
          _renderData.elements.push _particle
      o++
    sort and _renderData.elements.sort(painterSort)
    _renderData

# THREE.Projector = function() {
# 
	# var _object, _objectCount, _objectPool = [],
	# _vertex, _vertexCount, _vertexPool = [],
	# _face, _face3Count, _face3Pool = [], _face4Count, _face4Pool = [],
	# _line, _lineCount, _linePool = [],
	# _particle, _particleCount, _particlePool = [],
# 
	# _renderData = { objects: [], sprites: [], lights: [], elements: [] },
# 
	# _vector3 = new THREE.Vector3(),
	# _vector4 = new THREE.Vector4(),
# 
	# _projScreenMatrix = new THREE.Matrix4(),
	# _projScreenobjectMatrixWorld = new THREE.Matrix4(),
# 
	# _frustum = new THREE.Frustum(),
# 
	# _clippedVertex1PositionScreen = new THREE.Vector4(),
	# _clippedVertex2PositionScreen = new THREE.Vector4(),
# 
	# _face3VertexNormals;
# 
	# this.projectVector = function ( vector, camera ) {
# 
		# camera.matrixWorldInverse.getInverse( camera.matrixWorld );
# 
		# _projScreenMatrix.multiply( camera.projectionMatrix, camera.matrixWorldInverse );
		# _projScreenMatrix.multiplyVector3( vector );
# 
		# return vector;
# 
	# };
# 
	# this.unprojectVector = function ( vector, camera ) {
# 
		# camera.projectionMatrixInverse.getInverse( camera.projectionMatrix );
# 
		# _projScreenMatrix.multiply( camera.matrixWorld, camera.projectionMatrixInverse );
		# _projScreenMatrix.multiplyVector3( vector );
# 
		# return vector;
# 
	# };
# 
	# this.pickingRay = function ( vector, camera ) {
# 
		# var end, ray, t;
# 
		# // set two vectors with opposing z values
		# vector.z = -1.0;
		# end = new THREE.Vector3( vector.x, vector.y, 1.0 );
# 
		# this.unprojectVector( vector, camera );
		# this.unprojectVector( end, camera );
# 
		# // find direction from vector to end
		# end.subSelf( vector ).normalize();
# 
		# return new THREE.Ray( vector, end );
# 
	# };
# 
	# this.projectGraph = function ( root, sort ) {
# 
		# _objectCount = 0;
# 
		# _renderData.objects.length = 0;
		# _renderData.sprites.length = 0;
		# _renderData.lights.length = 0;
# 
		# var projectObject = function ( object ) {
# 
			# if ( object.visible === false ) return;
# 
			# if ( ( object instanceof THREE.Mesh || object instanceof THREE.Line ) &&
			# ( object.frustumCulled === false || _frustum.contains( object ) ) ) {
# 
				# _vector3.copy( object.matrixWorld.getPosition() );
				# _projScreenMatrix.multiplyVector3( _vector3 );
# 
				# _object = getNextObjectInPool();
				# _object.object = object;
				# _object.z = _vector3.z;
# 
				# _renderData.objects.push( _object );
# 
			# } else if ( object instanceof THREE.Sprite || object instanceof THREE.Particle ) {
# 
				# _vector3.copy( object.matrixWorld.getPosition() );
				# _projScreenMatrix.multiplyVector3( _vector3 );
# 
				# _object = getNextObjectInPool();
				# _object.object = object;
				# _object.z = _vector3.z;
# 
				# _renderData.sprites.push( _object );
# 
			# } else if ( object instanceof THREE.Light ) {
# 
				# _renderData.lights.push( object );
# 
			# }
# 
			# for ( var c = 0, cl = object.children.length; c < cl; c ++ ) {
# 
				# projectObject( object.children[ c ] );
# 
			# }
# 
		# };
# 
		# projectObject( root );
# 
		# sort && _renderData.objects.sort( painterSort );
# 
		# return _renderData;
# 
	# };
# 
	# this.projectScene = function ( scene, camera, sort ) {
# 
		# var near = camera.near, far = camera.far, visible = false,
		# o, ol, v, vl, f, fl, n, nl, c, cl, u, ul, object,
		# objectMatrixWorld, objectMatrixWorldRotation,
		# geometry, geometryMaterials, vertices, vertex, vertexPositionScreen,
		# faces, face, faceVertexNormals, normal, faceVertexUvs, uvs,
		# v1, v2, v3, v4;
# 
		# _face3Count = 0;
		# _face4Count = 0;
		# _lineCount = 0;
		# _particleCount = 0;
# 
		# _renderData.elements.length = 0;
# 
		# if ( camera.parent === undefined ) {
# 
			# console.warn( 'DEPRECATED: Camera hasn\'t been added to a Scene. Adding it...' );
			# scene.add( camera );
# 
		# }
# 
		# scene.updateMatrixWorld();
# 
		# camera.matrixWorldInverse.getInverse( camera.matrixWorld );
# 
		# _projScreenMatrix.multiply( camera.projectionMatrix, camera.matrixWorldInverse );
# 
		# _frustum.setFromMatrix( _projScreenMatrix );
# 
		# _renderData = this.projectGraph( scene, false );
# 
		# for ( o = 0, ol = _renderData.objects.length; o < ol; o++ ) {
# 
			# object = _renderData.objects[ o ].object;
# 
			# objectMatrixWorld = object.matrixWorld;
# 
			# _vertexCount = 0;
# 
			# if ( object instanceof THREE.Mesh ) {
# 
				# geometry = object.geometry;
				# geometryMaterials = object.geometry.materials;
				# vertices = geometry.vertices;
				# faces = geometry.faces;
				# faceVertexUvs = geometry.faceVertexUvs;
# 
				# objectMatrixWorldRotation = object.matrixRotationWorld.extractRotation( objectMatrixWorld );
# 
				# for ( v = 0, vl = vertices.length; v < vl; v ++ ) {
# 
					# _vertex = getNextVertexInPool();
					# _vertex.positionWorld.copy( vertices[ v ] );
# 
					# objectMatrixWorld.multiplyVector3( _vertex.positionWorld );
# 
					# _vertex.positionScreen.copy( _vertex.positionWorld );
					# _projScreenMatrix.multiplyVector4( _vertex.positionScreen );
# 
					# _vertex.positionScreen.x /= _vertex.positionScreen.w;
					# _vertex.positionScreen.y /= _vertex.positionScreen.w;
# 
					# _vertex.visible = _vertex.positionScreen.z > near && _vertex.positionScreen.z < far;
# 
				# }
# 
				# for ( f = 0, fl = faces.length; f < fl; f ++ ) {
# 
					# face = faces[ f ];
# 
					# if ( face instanceof THREE.Face3 ) {
# 
						# v1 = _vertexPool[ face.a ];
						# v2 = _vertexPool[ face.b ];
						# v3 = _vertexPool[ face.c ];
# 
						# if ( v1.visible && v2.visible && v3.visible ) {
# 
							# visible = ( ( v3.positionScreen.x - v1.positionScreen.x ) * ( v2.positionScreen.y - v1.positionScreen.y ) -
								# ( v3.positionScreen.y - v1.positionScreen.y ) * ( v2.positionScreen.x - v1.positionScreen.x ) ) < 0;
# 
							# if ( object.doubleSided || visible != object.flipSided ) {
# 
								# _face = getNextFace3InPool();
# 
								# _face.v1.copy( v1 );
								# _face.v2.copy( v2 );
								# _face.v3.copy( v3 );
# 
							# } else {
# 
								# continue;
# 
							# }
# 
						# } else {
# 
							# continue;
# 
						# }
# 
					# } else if ( face instanceof THREE.Face4 ) {
# 
						# v1 = _vertexPool[ face.a ];
						# v2 = _vertexPool[ face.b ];
						# v3 = _vertexPool[ face.c ];
						# v4 = _vertexPool[ face.d ];
# 
						# if ( v1.visible && v2.visible && v3.visible && v4.visible ) {
# 
							# visible = ( v4.positionScreen.x - v1.positionScreen.x ) * ( v2.positionScreen.y - v1.positionScreen.y ) -
								# ( v4.positionScreen.y - v1.positionScreen.y ) * ( v2.positionScreen.x - v1.positionScreen.x ) < 0 ||
								# ( v2.positionScreen.x - v3.positionScreen.x ) * ( v4.positionScreen.y - v3.positionScreen.y ) -
								# ( v2.positionScreen.y - v3.positionScreen.y ) * ( v4.positionScreen.x - v3.positionScreen.x ) < 0;
# 
# 
							# if ( object.doubleSided || visible != object.flipSided ) {
# 
								# _face = getNextFace4InPool();
# 
								# _face.v1.copy( v1 );
								# _face.v2.copy( v2 );
								# _face.v3.copy( v3 );
								# _face.v4.copy( v4 );
# 
							# } else {
# 
								# continue;
# 
							# }
# 
						# } else {
# 
							# continue;
# 
						# }
# 
					# }
# 
					# _face.normalWorld.copy( face.normal );
					# if ( !visible && ( object.flipSided || object.doubleSided ) ) _face.normalWorld.negate();
					# objectMatrixWorldRotation.multiplyVector3( _face.normalWorld );
# 
					# _face.centroidWorld.copy( face.centroid );
					# objectMatrixWorld.multiplyVector3( _face.centroidWorld );
# 
					# _face.centroidScreen.copy( _face.centroidWorld );
					# _projScreenMatrix.multiplyVector3( _face.centroidScreen );
# 
					# faceVertexNormals = face.vertexNormals;
# 
					# for ( n = 0, nl = faceVertexNormals.length; n < nl; n ++ ) {
# 
						# normal = _face.vertexNormalsWorld[ n ];
						# normal.copy( faceVertexNormals[ n ] );
						# if ( !visible && ( object.flipSided || object.doubleSided ) ) normal.negate();
						# objectMatrixWorldRotation.multiplyVector3( normal );
# 
					# }
# 
					# for ( c = 0, cl = faceVertexUvs.length; c < cl; c ++ ) {
# 
						# uvs = faceVertexUvs[ c ][ f ];
# 
						# if ( !uvs ) continue;
# 
						# for ( u = 0, ul = uvs.length; u < ul; u ++ ) {
# 
							# _face.uvs[ c ][ u ] = uvs[ u ];
# 
						# }
# 
					# }
# 
					# _face.material = object.material;
					# _face.faceMaterial = face.materialIndex !== null ? geometryMaterials[ face.materialIndex ] : null;
# 
					# _face.z = _face.centroidScreen.z;
# 
					# _renderData.elements.push( _face );
# 
				# }
# 
			# } else if ( object instanceof THREE.Line ) {
# 
				# _projScreenobjectMatrixWorld.multiply( _projScreenMatrix, objectMatrixWorld );
# 
				# vertices = object.geometry.vertices;
# 				
				# v1 = getNextVertexInPool();
				# v1.positionScreen.copy( vertices[ 0 ] );
				# _projScreenobjectMatrixWorld.multiplyVector4( v1.positionScreen );
# 
				# // Handle LineStrip and LinePieces
				# var step = object.type === THREE.LinePieces ? 2 : 1;
# 
				# for ( v = 1, vl = vertices.length; v < vl; v ++ ) {
# 
					# v1 = getNextVertexInPool();
					# v1.positionScreen.copy( vertices[ v ] );
					# _projScreenobjectMatrixWorld.multiplyVector4( v1.positionScreen );
# 
					# if ( ( v + 1 ) % step > 0 ) continue;
# 
					# v2 = _vertexPool[ _vertexCount - 2 ];
# 
					# _clippedVertex1PositionScreen.copy( v1.positionScreen );
					# _clippedVertex2PositionScreen.copy( v2.positionScreen );
# 
					# if ( clipLine( _clippedVertex1PositionScreen, _clippedVertex2PositionScreen ) ) {
# 
						# // Perform the perspective divide
						# _clippedVertex1PositionScreen.multiplyScalar( 1 / _clippedVertex1PositionScreen.w );
						# _clippedVertex2PositionScreen.multiplyScalar( 1 / _clippedVertex2PositionScreen.w );
# 
						# _line = getNextLineInPool();
						# _line.v1.positionScreen.copy( _clippedVertex1PositionScreen );
						# _line.v2.positionScreen.copy( _clippedVertex2PositionScreen );
# 
						# _line.z = Math.max( _clippedVertex1PositionScreen.z, _clippedVertex2PositionScreen.z );
# 
						# _line.material = object.material;
# 
						# _renderData.elements.push( _line );
# 
					# }
# 
				# }
# 
			# }
# 
		# }
# 
		# for ( o = 0, ol = _renderData.sprites.length; o < ol; o++ ) {
# 
			# object = _renderData.sprites[ o ].object;
# 
			# objectMatrixWorld = object.matrixWorld;
# 
			# if ( object instanceof THREE.Particle ) {
# 
				# _vector4.set( objectMatrixWorld.elements[12], objectMatrixWorld.elements[13], objectMatrixWorld.elements[14], 1 );
				# _projScreenMatrix.multiplyVector4( _vector4 );
# 
				# _vector4.z /= _vector4.w;
# 
				# if ( _vector4.z > 0 && _vector4.z < 1 ) {
# 
					# _particle = getNextParticleInPool();
					# _particle.x = _vector4.x / _vector4.w;
					# _particle.y = _vector4.y / _vector4.w;
					# _particle.z = _vector4.z;
# 
					# _particle.rotation = object.rotation.z;
# 
					# _particle.scale.x = object.scale.x * Math.abs( _particle.x - ( _vector4.x + camera.projectionMatrix.elements[0] ) / ( _vector4.w + camera.projectionMatrix.elements[12] ) );
					# _particle.scale.y = object.scale.y * Math.abs( _particle.y - ( _vector4.y + camera.projectionMatrix.elements[5] ) / ( _vector4.w + camera.projectionMatrix.elements[13] ) );
# 
					# _particle.material = object.material;
# 
					# _renderData.elements.push( _particle );
# 
				# }
# 
			# }
# 
		# }
# 
		# sort && _renderData.elements.sort( painterSort );
# 
		# return _renderData;
# 
	# };
# 
	# // Pools
# 
	# function getNextObjectInPool() {
# 
		# var object = _objectPool[ _objectCount ] = _objectPool[ _objectCount ] || new THREE.RenderableObject();
# 
		# _objectCount ++;
# 
		# return object;
# 
	# }
# 
	# function getNextVertexInPool() {
# 
		# var vertex = _vertexPool[ _vertexCount ] = _vertexPool[ _vertexCount ] || new THREE.RenderableVertex();
# 
		# _vertexCount ++;
# 
		# return vertex;
# 
	# }
# 
	# function getNextFace3InPool() {
# 
		# var face = _face3Pool[ _face3Count ] = _face3Pool[ _face3Count ] || new THREE.RenderableFace3();
# 
		# _face3Count ++;
# 
		# return face;
# 
	# }
# 
	# function getNextFace4InPool() {
# 
		# var face = _face4Pool[ _face4Count ] = _face4Pool[ _face4Count ] || new THREE.RenderableFace4();
# 
		# _face4Count ++;
# 
		# return face;
# 
	# }
# 
	# function getNextLineInPool() {
# 
		# var line = _linePool[ _lineCount ] = _linePool[ _lineCount ] || new THREE.RenderableLine();
# 
		# _lineCount ++;
# 
		# return line;
# 
	# }
# 
	# function getNextParticleInPool() {
# 
		# var particle = _particlePool[ _particleCount ] = _particlePool[ _particleCount ] || new THREE.RenderableParticle();
		# _particleCount ++;
		# return particle;
# 
	# }
# 
	# //
# 
	# function painterSort( a, b ) {
# 
		# return b.z - a.z;
# 
	# }
# 
	# function clipLine( s1, s2 ) {
# 
		# var alpha1 = 0, alpha2 = 1,
# 
		# // Calculate the boundary coordinate of each vertex for the near and far clip planes,
		# // Z = -1 and Z = +1, respectively.
		# bc1near =  s1.z + s1.w,
		# bc2near =  s2.z + s2.w,
		# bc1far =  - s1.z + s1.w,
		# bc2far =  - s2.z + s2.w;
# 
		# if ( bc1near >= 0 && bc2near >= 0 && bc1far >= 0 && bc2far >= 0 ) {
# 
			# // Both vertices lie entirely within all clip planes.
			# return true;
# 
		# } else if ( ( bc1near < 0 && bc2near < 0) || (bc1far < 0 && bc2far < 0 ) ) {
# 
			# // Both vertices lie entirely outside one of the clip planes.
			# return false;
# 
		# } else {
# 
			# // The line segment spans at least one clip plane.
# 
			# if ( bc1near < 0 ) {
# 
				# // v1 lies outside the near plane, v2 inside
				# alpha1 = Math.max( alpha1, bc1near / ( bc1near - bc2near ) );
# 
			# } else if ( bc2near < 0 ) {
# 
				# // v2 lies outside the near plane, v1 inside
				# alpha2 = Math.min( alpha2, bc1near / ( bc1near - bc2near ) );
# 
			# }
# 
			# if ( bc1far < 0 ) {
# 
				# // v1 lies outside the far plane, v2 inside
				# alpha1 = Math.max( alpha1, bc1far / ( bc1far - bc2far ) );
# 
			# } else if ( bc2far < 0 ) {
# 
				# // v2 lies outside the far plane, v2 inside
				# alpha2 = Math.min( alpha2, bc1far / ( bc1far - bc2far ) );
# 
			# }
# 
			# if ( alpha2 < alpha1 ) {
# 
				# // The line segment spans two boundaries, but is outside both of them.
				# // (This can't happen when we're only clipping against just near/far but good
				# //  to leave the check here for future usage if other clip planes are added.)
				# return false;
# 
			# } else {
# 
				# // Update the s1 and s2 vertices to match the clipped line segment.
				# s1.lerpSelf( s2, alpha1 );
				# s2.lerpSelf( s1, 1 - alpha2 );
# 
				# return true;
# 
			# }
# 
		# }
# 
	# }
# 
# };

# @author mr.doob / http://mrdoob.com/
# @autor aladjev.andrew@gmail.com

class window.Three::Ray
  constructor: (origin, direction) ->
    @v0                 = new Three::Vector3()
    @v1                 = new Three::Vector3()
    @v2                 = new Three::Vector3()
    @a                  = new Three::Vector3()
    @b                  = new Three::Vector3()
    @c                  = new Three::Vector3()
    @d                  = new Three::Vector3()
    @origin             = origin or new Three::Vector3()
    @origin_copy        = new Three::Vector3()
    @direction_copy     = new Three::Vector3()
    @vector             = new Three::Vector3()
    @normal             = new Three::Vector3()
    @intersect_point    = new Three::Vector3()
    @direction          = direction or new Three::Vector3()
    @precision          = 0.0001
  
  distance_from_intersection = (position) ->
    @v0.sub position, @origin
    dot = @v0.dot @direction
    intersect = @v1.add @origin, @v2.copy(@direction).multiply_scalar(dot)
    distance = position.distance_to intersect
  
  # http://www.blackpawn.com/texts/pointinpoly/default.html
  
  point_in_face_3 = (p, a, b, c) ->
    @v0.sub c, a
    @v1.sub b, a
    @v2.sub p, a
    dot00 = @v0.dot @v0
    dot01 = @v0.dot @v1
    dot02 = @v0.dot @v2
    dot11 = @v1.dot @v1
    dot12 = @v1.dot @v2
    inv_denom = 1 / (dot00 * dot11 - dot01 * dot01)
    u = (dot11 * dot02 - dot01 * dot12) * inv_denom
    v = (dot00 * dot12 - dot01 * dot02) * inv_denom
    (u >= 0) and (v >= 0) and (u + v < 1)
    
  set_precision = (value) ->
    @precision = value

  intersect_object = (object) ->
    intersects = []
    if object instanceof Three::Particle
      distance = @distance_from_intersection object.matrix_world.get_position()
      return [] if distance > object.scale.x
      intersect =
        distance: distance
        point:    object.position
        face:     null
        object:   object
      intersects.push intersect
    else if object instanceof Three::Mesh
      # Checking bounding_sphere
    
      distance = @distance_from_intersection object.matrix_world.get_position()
      scale = Three::Frustum.__v1.set(
        object.matrix_world.get_column_x().length()
        object.matrix_world.get_column_y().length()
        object.matrix_world.get_column_z().length()
      )
      if distance > object.geometry.bounding_sphere.radius * Math.max(scale.x, Math.max(scale.y, scale.z))
        return intersects
      
      # Checking faces
      
      geometry = object.geometry
      vertices = geometry.vertices
      object.matrix_rotation_world.extract_rotation object.matrix_world
      
      f = 0
      fl = geometry.faces.length
      while f < fl
        face = geometry.faces[f]
        @origin_copy.copy @origin
        @direction_copy.copy @direction
        obj_matrix = object.matrix_world
        
        # determine if ray intersects the plane of the face
				# note: this works regardless of the direction of the face normal
        
        @vector = obj_matrix.multiply_vector_3(@vector.copy(face.centroid)).sub_self @origin_copy
        @normal = object.matrix_rotation_world.multiply_vector3(@normal.copy(face.normal))
        dot = @direction_copy.dot normal
        
        # bail if ray and plane are parallel
        
        if Math.abs(dot) < precision
          continue
          
        # calc distance to plane
        
        scalar = @normal.dot(@vector) / dot
        
        # if negative distance, then plane is behind ray
        
        if scalar < 0
          continue
        
        if object.double_sided or (object.flip_sided and dot > 0) or (!object.flip_sided and dot < 0)
          @intersect_point.add @origin_copy, @direction_copy.multiply_scalar(scalar)
          if face instanceof Three::Face3
            @a = obj_matrix.multiply_vector_3 @a.copy(vertices[face.a])
            @b = obj_matrix.multiply_vector_3 @b.copy(vertices[face.b])
            @c = obj_matrix.multiply_vector_3 @c.copy(vertices[face.c])
            if @point_in_face_3(@intersect_point, @a, @b, @c)
              intersect =
                distance: @origin_copy.distance_to(@intersect_point)
                point:    @intersect_point.clone()
                face:     face
                object:   object

              intersects.push intersect
          else if face instanceof Three::Face4
            @a = obj_matrix.multiply_vector_3(@a.copy(vertices[face.a]))
            @b = obj_matrix.multiply_vector_3(@b.copy(vertices[face.b]))
            @c = obj_matrix.multiply_vector_3(@c.copy(vertices[face.c]))
            @d = obj_matrix.multiply_vector_3(@d.copy(vertices[face.d]))
            if @point_in_face_3(@intersect_point, @a, @b, @d) or @point_in_face_3(@intersect_point, @b, @c, @d)
              intersect =
                distance: @origin_copy.distanceTo @intersect_point
                point:    @intersect_point.clone()
                face:     face
                object:   object

              intersects.push intersect
        f++
    intersects

  intersect_objects = (objects) ->
    intersects = []
    length = objects.length
    for i in [0...length]
      Array::push.apply intersects, @intersect_object(objects[i])

    intersects.sort (a, b) ->
      a.distance - b.distance

    intersects
# @author mr.doob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

THREE.Ray = (origin, direction) ->
  self = this

  this.origin = origin || new THREE.Vector3()
  this.direction = direction || new THREE.Vector3()

  precision = 0.0001;

  this.setPrecision = (value) ->
    precision = value

  a = new THREE.Vector3()
  b = new THREE.Vector3()
  c = new THREE.Vector3()
  d = new THREE.Vector3()

  originCopy = new THREE.Vector3()
  directionCopy = new THREE.Vector3()

  vector = new THREE.Vector3();
  normal = new THREE.Vector3();
  intersectPoint = new THREE.Vector3()

  _intersectObject = (object) ->

    intersects = []

    if object instanceof THREE.Particle

      distance = distanceFromIntersection this.origin, this.direction, object.matrixWorld.getPosition()

      if distance > object.scale.x
        return []

      intersect =
        distance: distance,
        point: object.position,
        face: null,
        object: object

      intersects.push intersect

    else if object instanceof THREE.Mesh

      # Checking boundingSphere

      distance = distanceFromIntersection this.origin, this.direction, object.matrixWorld.getPosition()
      scale = THREE.Frustum.__v1.set object.matrixWorld.getColumnX().length(), object.matrixWorld.getColumnY().length(), object.matrixWorld.getColumnZ().length()

      if distance > object.geometry.boundingSphere.radius * Math.max( scale.x, Math.max( scale.y, scale.z ) )
        return intersects

      # Checking faces

      geometry = object.geometry
      vertices = geometry.vertices

      object.matrixRotationWorld.extractRotation object.matrixWorld
      f = 0
      fl = geometry.faces.length

      while (f < fl)
        face = geometry.faces[f]
        f++

        originCopy.copy this.origin
        directionCopy.copy this.direction

        objMatrix = object.matrixWorld;

        # determine if ray intersects the plane of the face
        # note: this works regardless of the direction of the face normal

        vector = objMatrix.multiplyVector3(vector.copy(face.centroid)).subSelf originCopy
        normal = object.matrixRotationWorld.multiplyVector3(normal.copy(face.normal))
        dot = directionCopy.dot normal

        # bail if ray and plane are parallel

        if Math.abs(dot) < precision
          continue

        # calc distance to plane

        scalar = normal.dot(vector) / dot

        # if negative distance, then plane is behind ray

        if scalar < 0
          continue

        if object.doubleSided || (object.flipSided ? dot > 0 : dot < 0)

          intersectPoint.add originCopy, directionCopy.multiplyScalar(scalar)

          if face instanceof THREE.Face3
            a = objMatrix.multiplyVector3 a.copy( vertices[ face.a ] )
            b = objMatrix.multiplyVector3 b.copy( vertices[ face.b ] )
            c = objMatrix.multiplyVector3 c.copy( vertices[ face.c ] )

            if pointInFace3(intersectPoint, a, b, c)

              intersect = 
                distance: originCopy.distanceTo(intersectPoint)
                point: intersectPoint.clone()
                face: face
                object: object

              intersects.push(intersect)

          else if face instanceof THREE.Face4

            a = objMatrix.multiplyVector3( a.copy( vertices[ face.a ] ) );
            b = objMatrix.multiplyVector3( b.copy( vertices[ face.b ] ) );
            c = objMatrix.multiplyVector3( c.copy( vertices[ face.c ] ) );
            d = objMatrix.multiplyVector3( d.copy( vertices[ face.d ] ) );

            if pointInFace3(intersectPoint, a, b, d) || pointInFace3(intersectPoint, b, c, d)
              intersect =
                distance: originCopy.distanceTo(intersectPoint)
                point: intersectPoint.clone()
                face: face
                object: object

              intersects.push(intersect)

    return intersects;

  this.intersectObjects = (objects) ->

    intersects = []
    i = 0
    l = objects.length
    while (i < l)
      Array.prototype.push.apply intersects, _intersectObject.call(self, objects[i])
      i++

    intersects.sort (a, b) ->
      a.distance - b.distance

    intersects

  v0 = new THREE.Vector3()
  v1 = new THREE.Vector3()
  v2 = new THREE.Vector3()

  distanceFromIntersection = (origin, direction, position) ->

    v0.sub position, origin
    dot = v0.dot direction

    intersect = v1.add origin, v2.copy(direction).multiplyScalar(dot)
    distance = position.distanceTo intersect

  # http://www.blackpawn.com/texts/pointinpoly/default.html

  pointInFace3 = ( p, a, b, c ) ->

    v0.sub c, a
    v1.sub b, a
    v2.sub p, a

    dot00 = v0.dot v0
    dot01 = v0.dot v1
    dot02 = v0.dot v2
    dot11 = v1.dot v1
    dot12 = v1.dot v2

    invDenom = 1 / ( dot00 * dot11 - dot01 * dot01 )
    u = ( dot11 * dot02 - dot01 * dot12 ) * invDenom
    v = ( dot00 * dot12 - dot01 * dot02 ) * invDenom

    (u >= 0) && (v >= 0) && (u + v < 1)
    
  this
    
# namespace "THREE", (exports) ->
  # exports.Ray = Ray
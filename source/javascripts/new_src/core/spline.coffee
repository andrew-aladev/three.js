# Spline from Tween.js, slightly optimized (and trashed)
# http://sole.github.com/tween.js/examples/05_spline.html
#
# @author mrdoob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

#= require new_src/core/vector_3

class Spline
  contructor: (points) ->
    @points = points
    @c = []
    @v3 =
      x: 0
      y: 0
      z: 0

  # Catmull-Rom
  interpolate = (p0, p1, p2, p3, t, t2, t3) ->
    v0 = (p2 - p0) * 0.5
    v1 = (p3 - p1) * 0.5
    (2 * (p1 - p2) + v0 + v1) * t3 + (-3 * (p1 - p2) - 2 * v0 - v1) * t2 + v0 * t + p1
  
  
  initFromArray: (a) ->
    @points = []
    i = 0

    while i < a.length
      @points[i] =
        x: a[i][0]
        y: a[i][1]
        z: a[i][2]
      i++

  getPoint: (k) ->
    point = (@points.length - 1) * k
    intPoint = Math.floor(point)
    weight = point - intPoint
    @c[0] = (if intPoint is 0 then intPoint else intPoint - 1)
    @c[1] = intPoint
    @c[2] = (if intPoint > @points.length - 2 then @points.length - 1 else intPoint + 1)
    @c[3] = (if intPoint > @points.length - 3 then @points.length - 1 else intPoint + 2)
    @pa = @points[@c[0]]
    @pb = @points[@c[1]]
    @pc = @points[@c[2]]
    @pd = @points[@c[3]]
    @w2 = weight * weight
    @w3 = weight * @w2
    @v3.x = interpolate(@pa.x, @pb.x, @pc.x, @pd.x, weight, @w2, @w3)
    @v3.y = interpolate(@pa.y, @pb.y, @pc.y, @pd.y, weight, @w2, @w3)
    @v3.z = interpolate(@pa.z, @pb.z, @pc.z, @pd.z, weight, @w2, @w3)
    @v3

  getControlPointsArray: ->
    i = undefined
    p = undefined
    l = @points.length
    coords = []
    i = 0
    while i < l
      p = @points[i]
      coords[i] = [ p.x, p.y, p.z ]
      i++
    coords


  # approximate length by summing linear segments
  getLength: (nSubDivisions) ->
    i = undefined
    index = undefined
    nSamples = undefined
    position = undefined
    point = 0
    intPoint = 0
    oldIntPoint = 0
    oldPosition = new THREE.Vector3()
    tmpVec = new THREE.Vector3()
    chunkLengths = []
    totalLength = 0
    
    # first point has 0 length
    chunkLengths[0] = 0
    nSubDivisions = 100  unless nSubDivisions
    nSamples = @points.length * nSubDivisions
    oldPosition.copy @points[0]
    i = 1
    while i < nSamples
      index = i / nSamples
      position = @getPoint(index)
      tmpVec.copy position
      totalLength += tmpVec.distanceTo(oldPosition)
      oldPosition.copy position
      point = (@points.length - 1) * index
      intPoint = Math.floor(point)
      unless intPoint is oldIntPoint
        chunkLengths[intPoint] = totalLength
        oldIntPoint = intPoint
      i++
      
    # last point ends with total length
    chunkLengths[chunkLengths.length] = totalLength
    chunks: chunkLengths
    total: totalLength

  reparametrizeByArcLength: (samplingCoef) ->
    i = undefined
    j = undefined
    index = undefined
    indexCurrent = undefined
    indexNext = undefined
    linearDistance = undefined
    realDistance = undefined
    sampling = undefined
    position = undefined
    newpoints = []
    tmpVec = new THREE.Vector3()
    sl = @getLength()
    newpoints.push tmpVec.copy(@points[0]).clone()
    i = 1
    while i < @points.length
    
      # tmpVec.copy( this.points[ i - 1 ] );
      # linearDistance = tmpVec.distanceTo( this.points[ i ] );
      realDistance = sl.chunks[i] - sl.chunks[i - 1]
      sampling = Math.ceil(samplingCoef * realDistance / sl.total)
      indexCurrent = (i - 1) / (@points.length - 1)
      indexNext = i / (@points.length - 1)
      j = 1
      while j < sampling - 1
        index = indexCurrent + j * (1 / sampling) * (indexNext - indexCurrent)
        position = @getPoint(index)
        newpoints.push tmpVec.copy(position).clone()
        j++
      newpoints.push tmpVec.copy(@points[i]).clone()
      i++
    @points = newpoints

namespace "THREE", (exports) ->
  exports.Spline = Spline
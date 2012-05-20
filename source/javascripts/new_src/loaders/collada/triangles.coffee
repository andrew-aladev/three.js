class Triangles extends THREE.Collada.Polygons
  constructor: ->
    super()
    @vcount = 3

namespace "THREE.Collada", (exports) ->
  exports.Triangles = Triangles
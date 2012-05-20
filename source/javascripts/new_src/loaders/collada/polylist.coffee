class Polylist extends THREE.Collada.Polygons
  constructor: ->
    super()
    @vcount = []

namespace "THREE.Collada", (exports) ->
  exports.Polylist = Polylist
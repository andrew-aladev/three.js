# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/polygons

class Triangles extends THREE.Collada.Polygons
  constructor: ->
    super()
    @vcount = 3

namespace "THREE.Collada", (exports) ->
  exports.Triangles = Triangles
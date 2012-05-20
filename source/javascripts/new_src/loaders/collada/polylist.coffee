# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/polygons

class Polylist extends THREE.Collada.Polygons
  constructor: ->
    super()
    @vcount = []

namespace "THREE.Collada", (exports) ->
  exports.Polylist = Polylist
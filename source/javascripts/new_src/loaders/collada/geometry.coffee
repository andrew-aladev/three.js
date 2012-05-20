# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/mesh

class Geometry
  constructor: (loader) ->
    @id     = ""
    @mesh   = null
    @loader = loader
    
  parse: (element) ->
    @id = element.getAttribute("id")

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "mesh"
          @mesh = new THREE.Collada.Mesh(loader, this).parse child
    this

namespace "THREE.Collada", (exports) ->
  exports.Geometry = Geometry
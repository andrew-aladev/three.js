# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/instance_material

class InstanceGeometry
  constructor: (loader) ->
    @url                = ""
    @instance_material  = []
    @loader             = loader
  
  parse: (element) ->
    @url                = element.getAttribute("url").replace /^#/, ""
    @instance_material  = []

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      if child.nodeName is "bind_material"
        instances = @loader.COLLADA.evaluate ".//dae:instance_material", child, THREE.ColladaLoader._nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null
        if instances
          instance = instances.iterateNext()
          while instance
            @instance_material.push new THREE.Collada.InstanceMaterial().parse(instance)
            instance = instances.iterateNext()
        break
    this
  
namespace "THREE.Collada", (exports) ->
  exports.InstanceGeometry = InstanceGeometry
class InstanceGeometry
  constructor: ->
    @url                = ""
    @instance_material  = []
  
  parse: (element) ->
    @url                = element.getAttribute("url").replace /^#/, ""
    @instance_material  = []

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      if child.nodeName is "bind_material"
        instances = COLLADA.evaluate ".//dae:instance_material", child, _nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null
        if instances
          instance = instances.iterateNext()
          while instance
            @instance_material.push new InstanceMaterial().parse(instance)
            instance = instances.iterateNext()
        break
    this
  
namespace "THREE.Collada", (exports) ->
  exports.InstanceGeometry = InstanceGeometry
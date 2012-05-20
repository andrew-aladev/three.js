class InstanceController
  constructor: ->
    @url                = ""
    @skeleton           = []
    @instance_material  = []
    
  parse: (element) ->
    @url                = element.getAttribute("url").replace /^#/, ""
    @skeleton           = []
    @instance_material  = []

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "skeleton"
          @skeleton.push child.textContent.replace(/^#/, "")
        when "bind_material"
          instances = COLLADA.evaluate ".//dae:instance_material", child, _nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null
          if instances
            instance = instances.iterateNext()
            while instance
              @instance_material.push new InstanceMaterial().parse(instance)
              instance = instances.iterateNext()
    this
    
namespace "THREE.Collada", (exports) ->
  exports.InstanceController = InstanceController
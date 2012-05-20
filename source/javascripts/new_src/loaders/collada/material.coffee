class Material
  constructor: ->
    @id               = ""
    @name             = ""
    @instance_effect  = null
    
  parse: (element) ->
    @id   = element.getAttribute "id"
    @name = element.getAttribute "name"

    length = element.childNodes.length
    for i in [0...length]
      if element.childNodes[i].nodeName is "instance_effect"
        @instance_effect = new InstanceEffect().parse element.childNodes[i]
        break
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Material = Material
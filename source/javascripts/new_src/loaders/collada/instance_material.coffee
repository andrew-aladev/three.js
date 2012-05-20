class InstanceMaterial
  constructor: ->
    @symbol = ""
    @target = ""
    
  parse: (element) ->
    @symbol = element.getAttribute "symbol"
    @target = element.getAttribute("target").replace /^#/, ""
    this
    
namespace "THREE.Collada", (exports) ->
  exports.InstanceMaterial = InstanceMaterial
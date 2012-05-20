# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

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
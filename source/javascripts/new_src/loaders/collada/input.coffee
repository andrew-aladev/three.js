# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class Input
  constructor: ->
    @semantic = ""
    @offset   = 0
    @source   = ""
    @set      = 0
    
  parse: (element) ->
    @semantic = element.getAttribute "semantic"
    @source   = element.getAttribute("source").replace /^#/, ""
    @set      = THREE.ColladaLoader._attr_as_int element, "set", -1
    @offset   = THREE.ColladaLoader._attr_as_int element, "offset", 0
    if @semantic is "TEXCOORD" and @set < 0
      @set      = 0
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Input = Input
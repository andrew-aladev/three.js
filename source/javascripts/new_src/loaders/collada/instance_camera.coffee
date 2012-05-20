# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class InstanceCamera
  constructor: ->
    @url = ""
    
  parse: (element) ->
    @url = element.getAttribute("url").replace /^#/, ""
    this
    
namespace "THREE.Collada", (exports) ->
  exports.InstanceCamera = InstanceCamera
# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class InstanceEffect
  constructor: ->
    @url = ""
    
  parse: (element) ->
    @url = element.getAttribute("url").replace /^#/, ""
    this

namespace "THREE.Collada", (exports) ->
  exports.InstanceEffect = InstanceEffect
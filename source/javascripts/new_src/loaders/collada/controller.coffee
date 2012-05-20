# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/skin
#= require new_src/loaders/collada/morph

class Controller
  constructor: (loader) ->
    @id     = ""
    @name   = ""
    @type   = ""
    @skin   = null
    @morph  = null
    @loader = loader
    
  parse: (element) ->
    @id   = element.getAttribute("id")
    @name = element.getAttribute("name")
    @type = "none"
    
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "skin"
          @skin = new THREE.Collada.Skin(@loader).parse child
          @type = child.nodeName
        when "morph"
          @morph  = new THREE.Collada.Morph(@loader).parse child
          @type   = child.nodeName
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Controller = Controller
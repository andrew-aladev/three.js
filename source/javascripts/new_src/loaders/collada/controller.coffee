class Controller
  constructor: ->
    @id     = ""
    @name   = ""
    @type   = ""
    @skin   = null
    @morph  = null
    
  parse: (element) ->
    @id   = element.getAttribute("id")
    @name = element.getAttribute("name")
    @type = "none"
    
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "skin"
          @skin = new Skin().parse child
          @type = child.nodeName
        when "morph"
          @morph  = new Morph().parse child
          @type   = child.nodeName
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Controller = Controller
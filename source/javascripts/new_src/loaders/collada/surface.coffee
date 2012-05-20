# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class Surface
  constructor: (effect) ->
    @effect     = effect
    @init_from  = null
    @format     = null
    
  parse: (element) ->
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "init_from"
          @init_from  = child.textContent
        when "format"
          @format     = child.textContent
        else
          console.warn "unhandled Surface prop: ", child.nodeName
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Surface = Surface
# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class Sampler2D
  constructor: (effect) ->
    @effect     = effect
    @source     = null
    @wrap_s     = null
    @wrap_t     = null
    @minfilter  = null
    @magfilter  = null
    @mipfilter  = null
    
  parse: (element) ->
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "source"
          @source     = child.textContent
        when "minfilter"
          @minfilter  = child.textContent
        when "magfilter"
          @magfilter  = child.textContent
        when "mipfilter"
          @mipfilter  = child.textContent
        when "wrap_s"
          @wrap_s     = child.textContent
        when "wrap_t"
          @wrap_t     = child.textContent
        else
          console.warn "unhandled Sampler2D prop: ", child.nodeName
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Sampler2D = Sampler2D
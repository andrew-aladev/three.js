# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class Image
  constructor: ->
    @id         = ""
    @init_from  = ""
    
  parse: (element) ->
    @id = element.getAttribute("id")
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      @init_from = child.textContent if child.nodeName is "init_from"
      i++
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Image = Image
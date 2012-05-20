# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/input

class Vertices
  constructor: ->
    @input = {}
    
  parse: (element) ->
    @id = element.getAttribute "id"

    length = element.childNodes.length
    for i in [0...length]
      if element.childNodes[i].nodeName is "input"
        input = new THREE.Collada.Input().parse element.childNodes[i]
        @input[input.semantic] = input
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Vertices = Vertices
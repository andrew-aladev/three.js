class Verticles
  constructor: ->
    @input = {}
    
  parse: (element) ->
    @id = element.getAttribute "id"

    length = element.childNodes.length
    for i in [0...length]
      if element.childNodes[i].nodeName is "input"
        input = new Input().parse element.childNodes[i]
        @input[input.semantic] = input
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Verticles = Verticles
class Geometry
  constructor: ->
    @id   = ""
    @mesh = null
    
  parse: (element) ->
    @id = element.getAttribute("id")

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "mesh"
          @mesh = new Mesh(this).parse child
    this

namespace "THREE.Collada", (exports) ->
  exports.Geometry = Geometry
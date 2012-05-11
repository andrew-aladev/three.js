# @author mr.doob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

class Vertex
  constructor: ->
    console.warn "THREE.Vertex has been DEPRECATED. Use THREE.Vector3 instead."

namespace "THREE", (exports) ->
  exports.Vertex = Vertex
# @author mr.doob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

class AmbientLight extends THREE.Light
  constructor: (hex) ->
    super hex

namespace "THREE", (exports) ->
  exports.AmbientLight = AmbientLight
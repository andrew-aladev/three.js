# @author mr.doob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

class PointLight extends THREE.Light
  constructor: (hex, intensity, distance) ->
    super hex
    @position = new THREE.Vector3 0, 0, 0
    @intensity = (if (intensity isnt undefined) then intensity else 1)
    @distance = (if (distance isnt undefined) then distance else 0)
  
namespace "THREE", (exports) ->
  exports.PointLight = PointLight
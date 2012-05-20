# @author mr.doob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

#= require new_src/core/color
#= require new_src/core/object_3d

class Light extends THREE.Object3D
  constructor: (hex) ->
	  super()
	  @color = new THREE.Color hex
    
namespace "THREE", (exports) ->
	exports.Light = Light
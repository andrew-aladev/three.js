# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class SpotLight extends THREE.Light
  constrcutor: (hex, intensity, distance, angle, exponent) ->
    super hex
    @position = new THREE.Vector3 0, 1, 0
    @target = new THREE.Object3D()
    @intensity = (if (intensity isnt undefined) then intensity else 1)
    @distance = (if (distance isnt undefined) then distance else 0)
    @angle = (if (angle isnt undefined) then angle else Math.PI / 2)
    @exponent = (if (exponent isnt undefined) then exponent else 10)
    @castShadow = false
    @onlyShadow = false
    @shadowCameraNear = 50
    @shadowCameraFar = 5000
    @shadowCameraFov = 50
    @shadowCameraVisible = false
    @shadowBias = 0
    @shadowDarkness = 0.5
    @shadowMapWidth = 512
    @shadowMapHeight = 512
    @shadowMap = null
    @shadowMapSize = null
    @shadowCamera = null
    @shadowMatrix = null
    
namespace "THREE", (exports) ->
  exports.SpotLight = SpotLight
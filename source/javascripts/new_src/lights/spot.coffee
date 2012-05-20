# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class SpotLight extends THREE.Light
  constructor: (hex, intensity, distance, angle, exponent) ->
    super hex
    @position = new THREE.Vector3 0, 1, 0
    @target   = new THREE.Object3D()
    
    if intensity isnt undefined
      @intensity = intensity
    else
      @intensity = 1

    if distance isnt undefined
      @distance = distance
    else
      @distance = 0
    
    if angle isnt undefined 
      @angle = angle
    else
      @angle = Math.PI / 2

    if exponent isnt undefined 
      @exponent = exponent
    else
      @exponent = 10

    @castShadow = false
    @onlyShadow = false
    
    @shadowCameraNear     = 50
    @shadowCameraFar      = 5000
    @shadowCameraFov      = 50
    @shadowCameraVisible  = false
    @shadowBias           = 0
    @shadowDarkness       = 0.5
    @shadowMapWidth       = 512
    @shadowMapHeight      = 512
    @shadowMap            = null
    @shadowMapSize        = null
    @shadowCamera         = null
    @shadowMatrix         = null
    
namespace "THREE", (exports) ->
  exports.SpotLight = SpotLight
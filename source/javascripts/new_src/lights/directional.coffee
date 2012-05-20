# @author mr.doob / http://mrdoob.com/
# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

#= require new_src/core/vector_3
#= require new_src/core/object_3d
#= require new_src/lights/light

class DirectionalLight extends THREE.Light
  constructor: (hex, intensity, distance) ->
    super hex
    @position = new THREE.Vector3(0, 1, 0)
    @target = new THREE.Object3D()
    @intensity = (if (intensity isnt undefined) then intensity else 1)
    @distance = (if (distance isnt undefined) then distance else 0)
    @castShadow = false
    @onlyShadow = false
    @shadowCameraNear = 50
    @shadowCameraFar = 5000
    @shadowCameraLeft = -500
    @shadowCameraRight = 500
    @shadowCameraTop = 500
    @shadowCameraBottom = -500
    @shadowCameraVisible = false
    @shadowBias = 0
    @shadowDarkness = 0.5
    @shadowMapWidth = 512
    @shadowMapHeight = 512
    @shadowCascade = false
    @shadowCascadeOffset = new THREE.Vector3(0, 0, -1000)
    @shadowCascadeCount = 2
    @shadowCascadeBias = [ 0, 0, 0 ]
    @shadowCascadeWidth = [ 512, 512, 512 ]
    @shadowCascadeHeight = [ 512, 512, 512 ]
    @shadowCascadeNearZ = [ -1.000, 0.990, 0.998 ]
    @shadowCascadeFarZ = [ 0.990, 0.998, 1.000 ]
    @shadowCascadeArray = []
    @shadowMap = null
    @shadowMapSize = null
    @shadowCamera = null
    @shadowMatrix = null

namespace "THREE", (exports) ->
  exports.DirectionalLight = DirectionalLight
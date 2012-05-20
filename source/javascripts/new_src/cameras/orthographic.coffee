# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

#= require new_src/cameras/camera

class OrthographicCamera extends THREE.Camera
  constructor: (left, right, top, bottom, near, far) ->
    super()
    @left   = left
    @right  = right
    @top    = top
    @bottom = bottom
    @near   = (if (near isnt undefined) then near else 0.1)
    @far    = (if (far isnt undefined) then far else 2000)
    @updateProjectionMatrix()

  updateProjectionMatrix: ->
    @projectionMatrix.makeOrthographic @left, @right, @top, @bottom, @near, @far
    
namespace "THREE", (exports) ->
  exports.OrthographicCamera = OrthographicCamera
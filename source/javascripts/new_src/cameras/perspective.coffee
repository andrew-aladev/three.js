# @author mr.doob / http://mrdoob.com/
# @author greggman / http://games.greggman.com/
# @author zz85 / http://www.lab4games.net/zz85/blog
# @author aladjev.andrew@gmail.com

class PerspectiveCamera extends THREE.Camera
  constructor: (fov, aspect, near, far) ->
    super()
    @fov    = (if fov isnt `undefined` then fov else 50)
    @aspect = (if aspect isnt `undefined` then aspect else 1)
    @near   = (if near isnt `undefined` then near else 0.1)
    @far    = (if far isnt `undefined` then far else 2000)
    @updateProjectionMatrix()

# Uses Focal Length (in mm) to estimate and set FOV
# 35mm (fullframe) camera is used if frame size is not specified;
# Formula based on http://www.bobatkins.com/photography/technical/field_of_view.html

  setLens: (focalLength, frameHeight) ->
    frameHeight = (if frameHeight isnt `undefined` then frameHeight else 24)
    @fov = 2 * Math.atan(frameHeight / (focalLength * 2)) * (180 / Math.PI)
    @updateProjectionMatrix()


# Sets an offset in a larger frustum. This is useful for multi-window or
# multi-monitor/multi-machine setups.
#
# For example, if you have 3x2 monitors and each monitor is 1920x1080 and
# the monitors are in grid like this
#
#   +---+---+---+
#   | A | B | C |
#   +---+---+---+
#   | D | E | F |
#   +---+---+---+
#
# then for each monitor you would call it like this
#
#   var w = 1920;
#   var h = 1080;
#   var fullWidth = w * 3;
#   var fullHeight = h * 2;
#
#   --A--
#   camera.setOffset( fullWidth, fullHeight, w * 0, h * 0, w, h );
#   --B--
#   camera.setOffset( fullWidth, fullHeight, w * 1, h * 0, w, h );
#   --C--
#   camera.setOffset( fullWidth, fullHeight, w * 2, h * 0, w, h );
#   --D--
#   camera.setOffset( fullWidth, fullHeight, w * 0, h * 1, w, h );
#   --E--
#   camera.setOffset( fullWidth, fullHeight, w * 1, h * 1, w, h );
#   --F--
#   camera.setOffset( fullWidth, fullHeight, w * 2, h * 1, w, h );
#
#   Note there is no reason monitors have to be the same size or in a grid.

  setViewOffset: (fullWidth, fullHeight, x, y, width, height) ->
    @fullWidth = fullWidth
    @fullHeight = fullHeight
    @x = x
    @y = y
    @width = width
    @height = height
    @updateProjectionMatrix()

  updateProjectionMatrix: ->
    if @fullWidth
      aspect = @fullWidth / @fullHeight
      top = Math.tan(@fov * Math.PI / 360) * @near
      bottom = -top
      left = aspect * bottom
      right = aspect * top
      width = Math.abs(right - left)
      height = Math.abs(top - bottom)
      @projectionMatrix.makeFrustum left + @x * width / @fullWidth, left + (@x + @width) * width / @fullWidth, top - (@y + @height) * height / @fullHeight, top - @y * height / @fullHeight, @near, @far
    else
      @projectionMatrix.makePerspective @fov, @aspect, @near, @far

namespace "THREE", (exports) ->
  exports.PerspectiveCamera = PerspectiveCamera
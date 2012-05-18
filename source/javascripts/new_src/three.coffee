# @author mr.doob / http://mrdoob.com/
# @autor aladjev.andrew@gmail.com

namespace "THREE", (exports) ->
  exports.REVISION = 49
      
unless self.Int32Array
  self.Int32Array = Array
  self.Float32Array = Array
  
# http://paulirish.com/2011/requestanimationframe-for-smart-animating/
# http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating
# requestAnimationFrame polyfill by Erik Möller
# fixes from Paul Irish and Tino Zijdel

(->
  lastTime = 0
  vendors = [ "ms", "moz", "webkit", "o" ]
  x = 0

  while x < vendors.length and not window.requestAnimationFrame
    window.requestAnimationFrame = window[vendors[x] + "RequestAnimationFrame"]
    window.cancelAnimationFrame = window[vendors[x] + "CancelAnimationFrame"] or window[vendors[x] + "CancelRequestAnimationFrame"]
    ++x
  unless window.requestAnimationFrame
    window.requestAnimationFrame = (callback, element) ->
      currTime = Date.now()
      timeToCall = Math.max(0, 16 - (currTime - lastTime))
      id = window.setTimeout(->
        callback currTime + timeToCall
      , timeToCall)
      lastTime = currTime + timeToCall
      id
  unless window.cancelAnimationFrame
    window.cancelAnimationFrame = (id) ->
      clearTimeout id
)()
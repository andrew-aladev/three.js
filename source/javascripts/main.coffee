# @author mr.doob / http://mrdoob.com/
# @autor aladjev.andrew@gmail.com

class window.Three
  @rev: "49"

if !window.Int32Array
	window.Int32Array = Array
	window.Float32Array = Array

# http://paulirish.com/2011/requestanimationframe-for-smart-animating/
# http://my.opera.com/emoller/blog/2011/12/20/requestanimationframe-for-smart-er-animating
# requestAnimationFrame polyfill by Erik Möller
# fixes from Paul Irish and Tino Zijdel

last_time = 0
vendors = ["ms", "moz", "webkit", "o"]
for x in vendors when !window.requestAnimationFrame
  window.requestAnimationFrame = window[vendors[x] + "RequestAnimationFrame"]
  window.cancelAnimationFrame = window[vendors[x] + "CancelAnimationFrame"] || window[vendors[x] + "CancelRequestAnimationFrame"]

if !window.requestAnimationFrame
  window.requestAnimationFrame = (callback, element) ->
    currrent_time = Date.now()
    time_to_call = Math.max(0, 16 - (current_time - last_time))
    last_time = current_time + time_to_call
    id = window.setTimeout( ->
      callback(currTime + timeToCall)
    , timeToCall)

if !window.cancelAnimationFrame
  window.cancelAnimationFrame = (id) ->
    clearTimeout id
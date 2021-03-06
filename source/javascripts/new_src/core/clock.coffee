# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class Clock
  constructor: (autoStart) ->
    if autoStart is undefined
      @autoStart = true

    @startTime    = 0
    @oldTime      = 0
    @elapsedTime  = 0
    @running      = false

  start: ->
    @startTime  = Date.now()
    @oldTime    = @startTime
    @running    = true

  stop: ->
    @getElapsedTime()
    @running = false

  getElapsedTime: ->
    @elapsedTime += @getDelta()

  getDelta: ->
    diff = 0
    @start() if @autoStart and not @running

    if @running
      newTime       = Date.now()
      diff          = 0.001 * (newTime - @oldTime)
      @oldTime      = newTime
      @elapsedTime  += diff
    diff
    
namespace "THREE", (exports) ->
  exports.Clock = Clock
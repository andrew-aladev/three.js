# @author alteredq / http://alteredqualia.com/
# @autor aladjev.andrew@gmail.com

class window.Three::Clock
  constructor: (auto_start) ->
    if auto_start
      @auto_start = auto_start
    else
      @auto_start = false
    @start_time = 0
    @old_time = 0
    @elapsed_time = 0
    @running = false

  start: ->
    @start_time = Date.now()
    @old_time = @start_time
    @running = true

  stop: ->
    @getElapsedTime()
    @running = false

  get_elapsed_time: ->
    @elapsed_time += @get_delta()

  get_delta: ->
    if @auto_start && !@running
      @start()
    
    if @running
      new_time = Date.now()
      diff = 0.001 * (new_time - @old_time)
      @old_time = new_time
      @elapsed_time += diff

    diff
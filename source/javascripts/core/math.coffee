# @author alteredq / http://alteredqualia.com/
# @autor aladjev.andrew@gmail.com

class window.Three::Math

  # clamp value to range <a, b>
  @clamp: (x, a, b) ->
    if (x < a)
      a
    else if (x > b)
      b
    else
      x

  # clamp value to range <a, inf)
  @clamp_bottom: (x, a) ->
    if x < a
      a
    else
      x

  # linear mapping from range <a1, a2> to range <b1, b2>
  @map_linear: (x, a1, a2, b1, b2) ->
    b1 + (x - a1) * (b2 - b1) / (a2 - a1)


  # Random float from <0, 1> with 16 bits of randomness
	# (standard Math.random() creates repetitive patterns when applied over larger space
  @random_16: ->
    (65280 * Math.random() + 255 * Math.random()) / 65535

  # random integer from <low, high> interval
  @rand_int: (low, high) ->
    low + Math.floor(Math.random() * (high - low + 1))

  # random float from <low, high> interval
  @rand_float: (low, high) ->
    low + Math.random() * (high - low)

  # random float from <-range/2, range/2> interval
  @rand_float_spread: (range) ->
    range * (0.5 - Math.random())

  @sign: (x) ->
    if x < 0
      -1
    else if x > 0
      1
    else
      0
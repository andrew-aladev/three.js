# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class _Math

  # Clamp value to range <a, b>
  @clamp: (x, a, b) ->
    if (x < a) then a else (if (x > b) then b else x)

  # Clamp value to range <a, inf)
  @clampBottom: (x, a) ->
    if x < a then a else x

  # Linear mapping from range <a1, a2> to range <b1, b2>
  @mapLinear: (x, a1, a2, b1, b2) ->
    b1 + (x - a1) * (b2 - b1) / (a2 - a1)

  # Random float from <0, 1> with 16 bits of randomness
  # (standard Math.random() creates repetitive patterns when applied over larger space)
  @random16: ->
    (65280 * Math.random() + 255 * Math.random()) / 65535

  # Random integer from <low, high> interval
  @randInt: (low, high) ->
    low + Math.floor(Math.random() * (high - low + 1))

  # Random float from <low, high> interval
  @randFloat: (low, high) ->
    low + Math.random() * (high - low)

  # Random float from <-range/2, range/2> interval
  @randFloatSpread: (range) ->
    range * (0.5 - Math.random())

  @sign: (x) ->
    if (x < 0) then -1 else (if (x > 0) then 1 else 0)
    
namespace "THREE", (exports) ->
  exports.Math = _Math
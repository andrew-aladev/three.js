# @author mr.doob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

class Color
  r: 1
  g: 1
  b: 1
  
  constructor: (hex) ->
    @setHex hex  if hex isnt undefined
    this
  
  copy: (color) ->
    @r = color.r
    @g = color.g
    @b = color.b
    this

  copyGammaToLinear: (color) ->
    @r = color.r * color.r
    @g = color.g * color.g
    @b = color.b * color.b
    this

  copyLinearToGamma: (color) ->
    @r = Math.sqrt(color.r)
    @g = Math.sqrt(color.g)
    @b = Math.sqrt(color.b)
    this

  convertGammaToLinear: ->
    r = @r
    g = @g
    b = @b
    @r = r * r
    @g = g * g
    @b = b * b
    this

  convertLinearToGamma: ->
    @r = Math.sqrt(@r)
    @g = Math.sqrt(@g)
    @b = Math.sqrt(@b)
    this

  setRGB: (r, g, b) ->
    @r = r
    @g = g
    @b = b
    this

  setHSV: (h, s, v) ->
    # based on MochiKit implementation by Bob Ippolito
    # h,s,v ranges are < 0.0 - 1.0 >
  
    if v is 0
      @r = @g = @b = 0
    else
      i = Math.floor h * 6
      f = h * 6 - i
      p = v * (1 - s)
      q = v * (1 - s * f)
      t = v * (1 - s * (1 - f))
      switch i
        when 1
          @r = q
          @g = v
          @b = p
        when 2
          @r = p
          @g = v
          @b = t
        when 3
          @r = p
          @g = q
          @b = v
        when 4
          @r = t
          @g = p
          @b = v
        when 5
          @r = v
          @g = p
          @b = q
        when 6, 0
          @r = v
          @g = t
          @b = p
    this

  setHex: (hex) ->
    hex = Math.floor(hex)
    @r  = (hex >> 16 & 255) / 255
    @g  = (hex >> 8 & 255) / 255
    @b  = (hex & 255) / 255
    this

  lerpSelf: (color, alpha) ->
    @r += (color.r - @r) * alpha
    @g += (color.g - @g) * alpha
    @b += (color.b - @b) * alpha
    this

  getHex: ->
    Math.floor(@r * 255) << 16 ^ Math.floor(@g * 255) << 8 ^ Math.floor(@b * 255)

  getContextStyle: ->
    "rgb(" + Math.floor(@r * 255) + "," + Math.floor(@g * 255) + "," + Math.floor(@b * 255) + ")"

  clone: ->
    new Color().setRGB @r, @g, @b
    
namespace "THREE", (exports) ->
  exports.Color = Color
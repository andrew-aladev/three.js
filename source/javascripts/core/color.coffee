# @author mr.doob / http://mrdoob.com/
# @autor aladjev.andrew@gmail.com

class window.Three.Color extends window.Three
  constructor: (hex) ->
    @set_hex hex if hex
    return @

  @r: 1, @g: 1, @b: 1
  
  copy: (color) ->
    @r = color.r
    @g = color.g
    @b = color.b
    return @
    
  copy_gamma_to_linear: (color) ->
    @r = color.r * color.r
    @g = color.g * color.g
    @b = color.b * color.b
    return @
    
  copy_linear_to_gamma: (color) ->
    @r = Math.sqrt color.r
    @g = Math.sqrt color.g
    @b = Math.sqrt color.b
    return @
    
  convert_gamma_to_linear: ->
    @r = @r * @r
    @g = @g * @g
    @b = @b * @b
    return @
    
  convert_linear_to_gamma: ->
    @r = Math.sqrt @r
    @g = Math.sqrt @g
    @b = Math.sqrt @b
    return @
    
  set_rgb: (r, g, b) ->
    @r = @r
    @g = @g
    @b = @b
    return @

  set_hsv: (h, s, v) ->
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
        when 0
          @r = v
          @g = t
          @b = p
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
          
    return @

  set_hex: (hex) ->
    hex = Math.floor hex
    @r = (hex >> 16 & 255) / 255
    @g = (hex >> 8 & 255) / 255
    @b = (hex & 255) / 255
    
    return @
    
  lerp_self: (color, alpha) ->
    @r += (color.r - @r) * alpha
    @g += (color.g - @g) * alpha
    @b += (color.b - @b) * alpha
    
    return @
    
  get_hex: ->
    Math.floor(@r * 255) << 16 ^ Math.floor(@g * 255) << 8 ^ Math.floor(@b * 255)
    
  get_context_style: ->
    return "rgb(" + Math.floor(@r * 255) + "," + Math.floor(@g * 255) + "," + Math.floor(@b * 255) + ")"

  clone: ->
    new Three.Color().setRGB @r, @g, @b
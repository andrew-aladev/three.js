class ColorOrTexture
  constructor: ->
    @color    = new THREE.Color(0)
    @color.setRGB Math.random(), Math.random(), Math.random()
    @color.a  = 1.0
    @texture  = null
    @texcoord = null
    @texOpts  = null
    
  isColor: ->
    not @texture?

  isTexture: ->
    @texture?

  parse: (element) ->
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "color"
          rgba    = _floats child.textContent
          @color  = new THREE.Color(0)
          @color.setRGB rgba[0], rgba[1], rgba[2]
          @color.a = rgba[3]
        when "texture"
          @texture  = child.getAttribute "texture"
          @texcoord = child.getAttribute "texcoord"
          
          # Defaults from:
          # https://collada.org/mediawiki/index.php/Maya_texture_placement_MAYA_extension
          @texOpts =
            offsetU:  0
            offsetV:  0
            repeatU:  1
            repeatV:  1
            wrapU:    1
            wrapV:    1

          @parseTexture child
    this
    
  parseTexture: (element) ->
    return this unless element.childNodes
    
    if element.childNodes[1] and element.childNodes[1].nodeName is "extra"     
      # This should be supported by Maya, 3dsMax, and MotionBuilder
      element = element.childNodes[1]
      if element.childNodes[1] and element.childNodes[1].nodeName is "technique"
        element = element.childNodes[1]

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "offsetU", "offsetV", "repeatU", "repeatV"
          @texOpts[child.nodeName] = parseFloat child.textContent
        when "wrapU", "wrapV"
          @texOpts[child.nodeName] = parseInt child.textContent
        else
          @texOpts[child.nodeName] = child.textContent
    this
    
namespace "THREE.Collada", (exports) ->
  exports.ColorOrTexture = ColorOrTexture
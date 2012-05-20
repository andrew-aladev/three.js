# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/color_or_texture

class Shader
  constructor: (loader, type, effect) ->
    @type     = type
    @effect   = effect
    @material = null
    @loader   = loader
    
  parse: (element) ->
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "ambient", "emission", "diffuse", "specular", "transparent"
          this[child.nodeName] = new THREE.Collada.ColorOrTexture().parse child
        when "shininess", "reflectivity", "transparency"
          f = @loader.evaluateXPath child, ".//dae:float"
          this[child.nodeName] = parseFloat(f[0].textContent) if f.length > 0

    @create()
    this

  create: ->
    props = {}
    transparent = this["transparency"] isnt undefined and this["transparency"] < 1.0
    for prop of this
      switch prop
        when "ambient", "emission", "diffuse", "specular"
          cot = this[prop]
          if cot instanceof THREE.Collada.ColorOrTexture
            if cot.isTexture()
              if @effect.sampler and @effect.surface
                if @effect.sampler.source is @effect.surface.sid
                  image = @loader.images[@effect.surface.init_from]
                  if image
                    texture = THREE.ImageUtils.loadTexture @loader.baseUrl + image.init_from
                    if cot.texOpts.wrapU
                      texture.wrapS = THREE.RepeatWrapping
                    else
                      texture.wrapS = THREE.ClampToEdgeWrapping
                    if cot.texOpts.wrapV
                      texture.wrapT = THREE.RepeatWrapping
                    else
                      texture.wrapT = THREE.ClampToEdgeWrapping 
                    texture.offset.x = cot.texOpts.offsetU
                    texture.offset.y = cot.texOpts.offsetV
                    texture.repeat.x = cot.texOpts.repeatU
                    texture.repeat.y = cot.texOpts.repeatV
                    props["map"] = texture
                    
                    # Texture with baked lighting?
                    props["emissive"] = 0xffffff  if prop is "emission"

            else if prop is "diffuse" or not transparent
              if prop is "emission"
                props["emissive"] = cot.color.getHex()
              else
                props[prop] = cot.color.getHex()

        when "shininess", "reflectivity"
          props[prop] = this[prop]
        when "transparency"
          if transparent
            props["transparent"] = true
            props["opacity"] = this[prop]
            transparent = true

    props["shading"] = @loader.preferredShading
    switch @type
      when "constant"
        props.color = props.emission
        @material   = new THREE.MeshBasicMaterial(props)
      when "phong", "blinn"
        props.color = props.diffuse
        @material   = new THREE.MeshPhongMaterial(props)
      when "lambert"
      else
        props.color = props.diffuse
        @material   = new THREE.MeshLambertMaterial(props)
    @material
    
namespace "THREE.Collada", (exports) ->
  exports.Shader = Shader
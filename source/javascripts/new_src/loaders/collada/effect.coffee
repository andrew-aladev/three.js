# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/image
#= require new_src/loaders/collada/surface
#= require new_src/loaders/collada/sampler_2d
#= require new_src/loaders/collada/shader

class Effect
  constructor: (loader) ->
    @id       = ""
    @name     = ""
    @shader   = null
    @surface  = null
    @sampler  = null
    @loader   = loader
    
  create: ->
    null unless @shader?

  parse: (element) ->
    @id     = element.getAttribute "id"
    @name   = element.getAttribute "name"
    @shader = null

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "profile_COMMON"
          @parseTechnique @parseProfileCOMMON(child)
    this

  parseNewparam: (element) ->
    sid = element.getAttribute "sid"

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "surface"
          @surface = new THREE.Collada.Surface(this).parse child
          @surface.sid = sid
        when "sampler2D"
          @sampler = new THREE.Collada.Sampler2D(this).parse child
          @sampler.sid = sid
        when "extra"
        else
          console.warn child.nodeName

  parseProfileCOMMON: (element) ->
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "profile_COMMON"
          @parseProfileCOMMON child
        when "technique"
          technique = child
        when "newparam"
          @parseNewparam child
        when "image"
          _image = new THREE.Collada.Image().parse child
          images[_image.id] = _image
        when "extra"
        else
          console.warn child.nodeName
    technique

  parseTechnique: (element) ->
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "constant", "lambert", "blinn", "phong"
          @shader = new THREE.Collada.Shader(@loader, child.nodeName, this).parse child
    
namespace "THREE.Collada", (exports) ->
  exports.Effect = Effect
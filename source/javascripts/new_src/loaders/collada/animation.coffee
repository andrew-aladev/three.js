# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/source
#= require new_src/loaders/collada/sampler

class Animation
  constructor: (loader) ->
    @id       = ""
    @name     = ""
    @source   = {}
    @sampler  = []
    @channel  = []
    @loader   = loader
    
  parse: (element) ->
    @id     = element.getAttribute "id"
    @name   = element.getAttribute "name"
    @source = {}

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "animation"
          anim = new Animation().parse child
          for src of anim.source
            @source[src] = anim.source[src]

          anim_length = anim.channel.length
          for j in [0...anim_length]
            @channel.push anim.channel[j]
            @sampler.push anim.sampler[j]

        when "source"
          src = new THREE.Collada.Source(@loader).parse child
          @source[src.id] = src
        when "sampler"
          @sampler.push new THREE.Collada.Sampler(this).parse child
        when "channel"
          @channel.push new THREE.Collada.Channel(this).parse child
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Animation = Animation
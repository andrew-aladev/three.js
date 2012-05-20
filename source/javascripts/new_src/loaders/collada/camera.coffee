# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class Camera
  constructor: ->
    @id         = ""
    @name       = ""
    @technique  = ""
    
  parse: (element) ->
    @id   = element.getAttribute "id"
    @name = element.getAttribute "name"

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "optics"
          @parseOptics child
    this

  parseOptics: (element) ->
    length = element.childNodes.length
    for i in [0...length]
      if element.childNodes[i].nodeName is "technique_common"
        technique = element.childNodes[i]

        technique_length = technique.childNodes.length
        for j in [0...technique_length]
          @technique = technique.childNodes[j].nodeName
          if @technique is "perspective"
            perspective = technique.childNodes[j]

            perspective_length = perspective.childNodes.length
            for k in [0...perspective_length]
              param = perspective.childNodes[k]
              switch param.nodeName
                when "yfov"
                  @yfov = param.textContent
                when "xfov"
                  @xfov = param.textContent
                when "znear"
                  @znear = param.textContent
                when "zfar"
                  @zfar = param.textContent
                when "aspect_ratio"
                  @aspect_ratio = param.textContent

          else if @technique is "orthographic"
            orthographic = technique.childNodes[j]

            orthographic_length = orthographic.childNodes.length
            for k in [0...orthographic_length]
              param = orthographic.childNodes[k]
              switch param.nodeName
                when "xmag"
                  @xmag = param.textContent
                when "ymag"
                  @ymag = param.textContent
                when "znear"
                  @znear = param.textContent
                when "zfar"
                  @zfar = param.textContent
                when "aspect_ratio"
                  @aspect_ratio = param.textContent
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Camera = Camera
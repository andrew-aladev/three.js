# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/accessor

class Source
  constructor: (loader, id) ->
    @id     = id
    @type   = null
    @loader = loader
    
  parse: (element) ->
    @id = element.getAttribute "id"

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "bool_array"
          @data = THREE.ColladaLoader._bools child.textContent
          @type = child.nodeName
        when "float_array"
          @data = THREE.ColladaLoader._floats child.textContent
          @type = child.nodeName
        when "int_array"
          @data = THREE.ColladaLoader._ints child.textContent
          @type = child.nodeName
        when "IDREF_array", "Name_array"
          @data = THREE.ColladaLoader._strings child.textContent
          @type = child.nodeName
        when "technique_common"
          child_length = child.childNodes.length
          for j in [0...child_length]
            if child.childNodes[j].nodeName is "accessor"
              @accessor = new THREE.Collada.Accessor().parse child.childNodes[j]
              break
    this

  read: ->
    result  = []
    param   = @accessor.params[0]
    # console.log param.name, " ", param.type
    switch param.type
      when "IDREF", "Name", "name", "float"
        return @data
      when "float4x4"
        length = @data.length
        for j in [0...length] by 16
          s = @data.slice j, j + 16
          m = @loader.getConvertedMat4 s
          result.push m
      else
        console.warn "ColladaLoader: Source: Read dont know how to read ", param.type, "."
    result
    
namespace "THREE.Collada", (exports) ->
  exports.Source = Source
class Source
  constructor: ->
    @id   = id
    @type = null
    
  parse: (element) ->
    @id = element.getAttribute "id"

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "bool_array"
          @data = _bools child.textContent
          @type = child.nodeName
        when "float_array"
          @data = _floats child.textContent
          @type = child.nodeName
        when "int_array"
          @data = _ints child.textContent
          @type = child.nodeName
        when "IDREF_array", "Name_array"
          @data = _strings child.textContent
          @type = child.nodeName
        when "technique_common"
          child_length = child.childNodes.length
          for j in [0...child_length]
            if child.childNodes[j].nodeName is "accessor"
              @accessor = new Accessor().parse child.childNodes[j]
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
          m = getConvertedMat4 s
          result.push m
      else
        console.log "ColladaLoader: Source: Read dont know how to read ", param.type, "."
    result
    
namespace "THREE.Collada", (exports) ->
  exports.Source = Source
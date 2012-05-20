class Skin
  constructor: ->
    @source           = ""
    @bindShapeMatrix  = null
    @invBindMatrices  = []
    @joints           = []
    @weights          = []

  parse: (element) ->
    sources           = {}
    @source           = element.getAttribute("source").replace /^#/, ""
    @invBindMatrices  = []
    @joints           = []
    @weights          = []
    
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "bind_shape_matrix"
          f = _floats(child.textContent)
          @bindShapeMatrix = getConvertedMat4(f)
        when "source"
          src = new Source().parse(child)
          sources[src.id] = src
        when "joints"
          joints = child
        when "vertex_weights"
          weights = child
        else
          console.log child.nodeName

    @parseJoints  joints,   sources
    @parseWeights weights,  sources
    this

  parseJoints: (element, sources) ->
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "input"
          input = new Input().parse child
          source = sources[input.source]
          if input.semantic is "JOINT"
            @joints = source.read()
          else if input.semantic is "INV_BIND_MATRIX"
            @invBindMatrices = source.read()

  parseWeights: (element, sources) ->
    inputs = []
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "input"
          inputs.push new Input().parse child
        when "v"
          v = _ints child.textContent
        when "vcount"
          vcount = _ints child.textContent

    index = 0
    length = vcount.length
    for i in [0...length]
      numBones        = vcount[i]
      vertex_weights  = []

      for j in [0...numBones]
        influence = {}
        
        inputs_length = inputs.length
        for k in [0...inputs_length]
          input = inputs[k]
          value = v[index + input.offset]
          switch input.semantic
            when "JOINT"
              influence.joint   = value
            when "WEIGHT"
              influence.weight  = sources[input.source].data[value]

        vertex_weights.push influence
        index += inputs_length

      weights_length = vertex_weights.length
      for j in [0...weights_length]
        vertex_weights[j].index = i

      @weights.push vertex_weights

namespace "THREE.Collada", (exports) ->
  exports.Skin = Skin
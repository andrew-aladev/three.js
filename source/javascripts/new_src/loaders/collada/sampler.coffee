# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/input

class Sampler
  constructor: (animation) ->
    @id             = ""
    @animation      = animation
    @inputs         = []
    @input          = null
    @output         = null
    @strideOut      = null
    @interpolation  = null
    @startTime      = null
    @endTime        = null
    @duration       = 0
    
  parse: (element) ->
    @id     = element.getAttribute "id"
    @inputs = []

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "input"
          @inputs.push new THREE.Collada.Input().parse child
    this

  create: ->
    length = @inputs.length
    for i in [0...length]
      input = @inputs[i]
      source = @animation.source[input.source]
      switch input.semantic
        when "INPUT"
          @input          = source.read()
        when "OUTPUT"
          @output         = source.read()
          @strideOut      = source.accessor.stride
        when "INTERPOLATION"
          @interpolation  = source.read()
        when "IN_TANGENT", "OUT_TANGENT"
        else
          console.warn input.semantic

    @startTime  = 0
    @endTime    = 0
    @duration   = 0
    if @input.length
      @startTime  = 100000000
      @endTime    = -100000000

      length = @input.length
      for i in [0...length]
        @startTime  = Math.min @startTime,  @input[i]
        @endTime    = Math.max @endTime,    @input[i]
      @duration = @endTime - @startTime

  getData: (type, ndx) ->
    if type is "matrix" and @strideOut is 16
      data = @output[ndx]
    else if @strideOut > 1
      data = []
      ndx *= @strideOut

      for i in [0...@strideOut]
        data[i] = @output[ndx + i]

      if @strideOut is 3
        switch type
          when "rotate", "translate"
            fixCoords data, -1
          when "scale"
            fixCoords data, 1
      else if @strideOut is 4 and type is "matrix"
        fixCoords data, -1
    else
      data = @output[ndx]
    data
    
namespace "THREE.Collada", (exports) ->
  exports.Sampler = Sampler
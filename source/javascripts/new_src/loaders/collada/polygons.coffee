# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/core/geometry
#= require new_src/loaders/collada/input

class Polygons
  constructor: ->
    @material = ""
    @count    = 0
    @inputs   = []
    @vcount   = null
    @p        = []
    @geometry = new THREE.Geometry()
    
  setVertices: (vertices) ->
    length = @inputs.length
    for i in [0...length]
      if @inputs[i].source is vertices.id
        @inputs[i].source = vertices.input["POSITION"].source

  parse: (element) ->
    @material = element.getAttribute "material"
    @count    = THREE.ColladaLoader._attr_as_int element, "count", 0

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "input"
          @inputs.push new THREE.Collada.Input().parse(element.childNodes[i])
        when "vcount"
          @vcount = THREE.ColladaLoader._ints child.textContent
        when "p"
          @p.push THREE.ColladaLoader._ints child.textContent
        when "ph"
          console.warn "polygon holes not yet supported!"
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Polygons = Polygons
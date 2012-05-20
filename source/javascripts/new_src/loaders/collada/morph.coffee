# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/source
#= require new_src/loaders/collada/input

class Morph
  constructor: (loader) ->
    @method   = null
    @source   = null
    @targets  = null
    @weights  = null
    @loader   = loader
    
  parse: (element) ->
    sources = {}
    inputs  = []
    @method = element.getAttribute("method")
    @source = element.getAttribute("source").replace /^#/, ""
    
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "source"
          source = new THREE.Collada.Source(@loader).parse child
          sources[source.id] = source
        when "targets"
          inputs = @parseInputs child
        else
          console.warn child.nodeName
    
    length = inputs.length
    for i in [0...length]
      input   = inputs[i]
      source  = sources[input.source]
      switch input.semantic
        when "MORPH_TARGET"
          @targets = source.read()
        when "MORPH_WEIGHT"
          @weights = source.read()

    this

  parseInputs: (element) ->
    inputs = []
    
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue 
      switch child.nodeName
        when "input"
          inputs.push new THREE.Collada.Input().parse child
    inputs
    
namespace "THREE.Collada", (exports) ->
  exports.Morph = Morph
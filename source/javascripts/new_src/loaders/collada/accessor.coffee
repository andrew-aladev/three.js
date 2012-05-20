class Accessor
  constructor: ->
    @source   = ""
    @count    = 0
    @stride   = 0
    @params   = []
    
  parse: (element) ->
    @params = []
    @source = element.getAttribute "source"
    @count  = _attr_as_int element, "count", 0
    @stride = _attr_as_int element, "stride", 0
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      if child.nodeName is "param"
        param = {}
        param["name"] = child.getAttribute("name")
        param["type"] = child.getAttribute("type")
        @params.push param
      i++
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Accessor = Accessor
class VisualScene
  constructor: ->
    @id     = ""
    @name   = ""
    @nodes  = []
    @scene  = new THREE.Object3D()
    
  getChildById: (id, recursive) ->
    length = @nodes.length
    for i in [0...length]
      node = @nodes[i].getChildById id, recursive
      return node if node
    null

  getChildBySid: (sid, recursive) ->
    length = @nodes.length
    for i in [0...length]
      node = @nodes[i].getChildBySid sid, recursive
      return node  if node
    null

  parse: (element) ->
    @id     = element.getAttribute("id")
    @name   = element.getAttribute("name")
    @nodes  = []

    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "node"
          @nodes.push new Node().parse child

    this
    
namespace "THREE.Collada", (exports) ->
  exports.VisualScene = VisualScene
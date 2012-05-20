class Node
  constructor: ->
    @id     = ""
    @name   = ""
    @sid    = ""
    @nodes  = []
    @controllers  = []
    @transforms   = []
    @geometries   = []
    @channels     = []
    @matrix       = new THREE.Matrix4()
    
  getChannelForTransform: (transformSid) ->
    length = @channels.length
    for i in [0...length]
      channel = @channels[i]
      parts   = channel.target.split("/")
      
      id  = parts.shift()
      sid = parts.shift()
      
      dotSyntax = sid.indexOf(".") >= 0
      arrSyntax = sid.indexOf("(") >= 0
      if dotSyntax
        parts   = sid.split "."
        sid     = parts.shift()
        member  = parts.shift()
      else if arrSyntax
        arrIndices  = sid.split "("
        sid         = arrIndices.shift()

        indices_length = arrIndices.length 
        for j in [0...indices_length]
          arrIndices[j] = parseInt arrIndices[j].replace(/\)/, "")

      if sid is transformSid
        channel.info =
          sid:        sid
          dotSyntax:  dotSyntax
          arrSyntax:  arrSyntax
          arrIndices: arrIndices

        return channel
    null

  getChildById: (id, recursive) ->
    return this if @id is id

    if recursive
      length = @nodes.length
      for i in [0...length]
        n = @nodes[i].getChildById id, recursive
        return n if n
    null

  getChildBySid: (sid, recursive) ->
    return this if @sid is sid

    if recursive
      length = @nodes.length
      for i in [0...length]
        n = @nodes[i].getChildBySid sid, recursive
        return n if n
    null

  getTransformBySid: (sid) ->
    length = @transforms.length
    for i in [0...length]
      return @transforms[i] if @transforms[i].sid is sid
    null

  parse: (element) ->
    @id   = element.getAttribute "id"
    @sid  = element.getAttribute "sid"
    @name = element.getAttribute "name"
    @type = element.getAttribute "type"
    if @type isnt "JOINT"
      @type = "NODE"

    @type         = 1
    @nodes        = []
    @transforms   = []
    @geometries   = []
    @cameras      = []
    @controllers  = []
    @matrix       = new THREE.Matrix4()

    length = element.childNodes.length
    for i in [0...length] 
      child = element.childNodes[i]
      unless child.nodeType is 1
        continue
      switch child.nodeName
        when "node"
          @nodes.push       new Node().parse child
        when "instance_camera"
          @cameras.push     new InstanceCamera().parse child
        when "instance_controller"
          @controllers.push new InstanceController().parse child
        when "instance_geometry"
          @geometries.push  new InstanceGeometry().parse child
        when "instance_light", "instance_node"
          url   = child.getAttribute("url").replace /^#/, ""
          iNode = getLibraryNode url
          if iNode
            @nodes.push new Node().parse iNode
        when "rotate", "translate", "scale", "matrix", "lookat", "skew"
          @transforms.push new Transform().parse child
        else
          console.log child.nodeName

    @channels = getChannelsForNode this
    bakeAnimations this
    @updateMatrix()
    this

  updateMatrix: ->
    @matrix.identity()

    length = @transforms.length
    for i in [0...length]
      @transforms[i].apply @matrix
    
namespace "THREE.Collada", (exports) ->
  exports.Node = Node
# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require_tree ./collada
#= require new_src/core/object_3d
#= require new_src/core/matrix_4
#= require new_src/core/vector_3
#= require new_src/cameras/perspective

class ColladaLoader extends THREE.Loader
  constructor: ->
    @sources       = {}
    @images        = {}
    @animations    = {}
    @controllers   = {}
    @geometries    = {}
    @materials     = {}
    @effects       = {}
    @cameras       = {}
    @flip_uv       = true

    @preferredShading = THREE.SmoothShading
    
    # Force Geometry to always be centered at the local origin of the containing Mesh
    @options =
      centerGeometry:   false
      # Axis conversion is done for geometries, animations, and controllers.
      # If we ever pull cameras or lights out of the COLLADA file, they'll
      # need extra work.
      convertUpAxis:    false
      subdivideFaces:   true
      upAxis:           "Y"
  
    # TODO: support unit conversion as well
    @colladaUnit   = 1.0
    @colladaUp     = "Y"
    @TO_RADIANS    = Math.PI / 180
    
    # load: load
    # parse: parse
    # setPreferredShading: setPreferredShading
    # applySkin: applySkin
    # geometries: geometries
    # options: options
  
  load: (url, readyCallback, progressCallback) ->
    length = 0
    if document.implementation and document.implementation.createDocument
      req = new XMLHttpRequest()
      req.overrideMimeType "text/xml" if req.overrideMimeType
      req.onreadystatechange = =>
        if req.readyState is 4
          if req.status is 0 or req.status is 200
            if req.responseXML
              @readyCallbackFunc = readyCallback
              @parse req.responseXML, undefined, url
            else
              console.error "ColladaLoader: Empty or non-existing file (" + url + ")"
        else if req.readyState is 3
          if progressCallback
            length = req.getResponseHeader("Content-Length")  if length is 0
            progressCallback
              total: length
              loaded: req.responseText.length

      req.open "GET", url, true
      req.send null
    else
      alert "Don't know how to parse XML!"

  parse: (doc, callBack, url) ->
    @COLLADA  = doc
    callBack  = callBack or @readyCallbackFunc
    if url isnt undefined
      parts = url.split("/")
      parts.pop()
      if parts.length < 1
        @baseUrl = "./"
      else
        @baseUrl = parts.join("/") + "/"

    @parseAsset()
    @setUpConversion()

    @images       = @parseLib "//dae:library_images/dae:image",                THREE.Collada.Image,        "image"
    @materials    = @parseLib "//dae:library_materials/dae:material",          THREE.Collada.Material,     "material"
    @effects      = @parseLib "//dae:library_effects/dae:effect",              THREE.Collada.Effect,       "effect"
    @geometries   = @parseLib "//dae:library_geometries/dae:geometry",         THREE.Collada.Geometry,     "geometry"
    @cameras      = @parseLib ".//dae:library_cameras/dae:camera",             THREE.Collada.Camera,       "camera"
    @controllers  = @parseLib "//dae:library_controllers/dae:controller",      THREE.Collada.Controller,   "controller"
    @animations   = @parseLib "//dae:library_animations/dae:animation",        THREE.Collada.Animation,    "animation"
    @visualScenes = @parseLib ".//dae:library_visual_scenes/dae:visual_scene", THREE.Collada.VisualScene,  "visual_scene"
    @morphs       = []
    @skins        = []
    @daeScene     = @parseScene()
    @scene        = new THREE.Object3D()

    length = @daeScene.nodes.length
    for i in [0...length]
      @scene.add @createSceneGraph(@daeScene.nodes[i])

    @createAnimations()
    result =
      scene:      @scene
      morphs:     @morphs
      skins:      @skins
      animations: @animData
      dae:
        images:       @images
        materials:    @materials
        cameras:      @cameras
        effects:      @effects
        geometries:   @geometries
        controllers:  @controllers
        animations:   @animations
        visualScenes: @visualScenes
        scene:        @daeScene

    callBack result if callBack
    result

  setPreferredShading: (shading) ->
    @preferredShading = shading

  parseAsset: ->
    elements  = @COLLADA.evaluate "//dae:asset", @COLLADA, ColladaLoader._nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null
    element   = elements.iterateNext()
    if element and element.childNodes
      length = element.childNodes.length
      for i in [0...length]
        child = element.childNodes[i]
        switch child.nodeName
          when "unit"
            meter       = child.getAttribute "meter"
            @colladaUnit = parseFloat(meter) if meter
          when "up_axis"
            @colladaUp   = child.textContent.charAt 0

  parseLib: (q, classSpec, prefix) ->
    elements  = @COLLADA.evaluate q, @COLLADA, ColladaLoader._nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null
    lib       = {}
    element   = elements.iterateNext()

    i = 0
    while element
      daeElement = new classSpec(this).parse element
      if not daeElement.id or daeElement.id.length is 0
        daeElement.id = prefix + (i++)
      lib[daeElement.id] = daeElement
      element = elements.iterateNext()
    lib

  parseScene: ->
    sceneElement = @COLLADA.evaluate(
      ".//dae:scene/dae:instance_visual_scene"
      @COLLADA
      ColladaLoader._nsResolver
      XPathResult.ORDERED_NODE_ITERATOR_TYPE
      null
    ).iterateNext()

    if sceneElement
      url = sceneElement.getAttribute("url").replace /^#/, ""
      if url.length > 0
        @visualScenes[url]
      else
        @visualScenes["visual_scene0"]
    else
      null

  createAnimations: ->
    @animData = []
    # fill in the keys
    @recurseHierarchy @scene

  recurseHierarchy: (node) ->
    n = @daeScene.getChildById node.name, true
    newData = null
    if n and n.keys
      newData =
        fps:        60
        hierarchy:  [
          node: n
          keys: n.keys
          sids: n.sids
        ]
        node:       node
        name:       "animation_" + node.name
        length:     0

      @animData.push newData
      keys_length = n.keys.length
      for i in [0...keys_length]
        newData.length = Math.max newData.length, n.keys[i].time

    else
      newData = hierarchy: [
        keys: []
        sids: []
      ]

    node_length = node.children.length
    for i in [0...node_length]
      d = @recurseHierarchy node.children[i]

      hierarchy_length = d.hierarchy.length
      for j in [0...hierarchy_length]
        newData.hierarchy.push
          keys: []
          sids: []

    newData

  calcAnimationBounds: ->
    start   = 1000000
    end     = -start
    frames  = 0
    for id of @animations
      animation = @animations[id]

      sampler_length = animation.sampler.length
      for i in [0...sampler_length]
        sampler = animation.sampler[i]
        sampler.create()
        start   = Math.min start, sampler.startTime
        end     = Math.max end, sampler.endTime
        frames  = Math.max frames, sampler.input.length

    start:  start
    end:    end
    frames: frames

  createMorph: (geometry, ctrl) ->
    if ctrl instanceof InstanceController
      morphCtrl = @controllers[ctrl.url]
    else
      morphCtrl = ctrl
    if not morphCtrl or not morphCtrl.morph
      console.warn "could not find morph controller!"
      return

    morph = morphCtrl.morph
    targets_length = morph.targets.length
    for i in [0...targets_length]
      target_id   = morph.targets[i]
      daeGeometry = @geometries[target_id]
      if not daeGeometry.mesh or not daeGeometry.mesh.primitives or not daeGeometry.mesh.primitives.length
        continue

      target = daeGeometry.mesh.primitives[0].geometry
      if target.vertices.length is geometry.vertices.length
        geometry.morphTargets.push
          name:     "target_1"
          vertices: target.vertices

    geometry.morphTargets.push
      name:     "target_Z"
      vertices: geometry.vertices

  createSkin: (geometry, ctrl, applyBindShape) ->
    skinCtrl = @controllers[ctrl.url]

    if not skinCtrl or not skinCtrl.skin
      console.warn "could not find skin controller!"
      return
    if not ctrl.skeleton or not ctrl.skeleton.length
      console.warn "could not find the skeleton for the skin!"
      return

    skin      = skinCtrl.skin
    skeleton  = @daeScene.getChildById ctrl.skeleton[0]
    hierarchy = []
    
    # createBones geometry.bones, skin, hierarchy, skeleton, null, -1
    # createWeights skin, geometry.bones, geometry.skinIndices, geometry.skinWeights
    # geometry.animation =
      # name: 'take_001'
      # fps: 30
      # length: 2
      # JIT: true
      # hierarchy: hierarchy

    if applyBindShape isnt undefined
      applyBindShape = applyBindShape
    else
      applyBindShape = true

    bones                 = []
    geometry.skinWeights  = []
    geometry.skinIndices  = []

    if applyBindShape
      vertices_length = geometry.vertices.length
      for i in [0...vertices_length]
        skin.bindShapeMatrix.multiplyVector3 geometry.vertices[i]

  setupSkeleton: (node, bones, frame, parent) ->
    node.world = node.world or new THREE.Matrix4()
    node.world.copy node.matrix

    if node.channels and node.channels.length
      channel = node.channels[0]
      m = channel.sampler.output[frame]
      node.world.copy m if m instanceof THREE.Matrix4

    node.world.multiply parent, node.world if parent
    bones.push node

    length = node.nodes.length
    for i in [0...length]
      @setupSkeleton node.nodes[i], bones, frame, node.world

  setupSkinningMatrices: (bones, skin) ->
    # FIXME: this is dumb...
    # skin 'm
    
    length = bones.length
    for i in [0...length]
      bone  = bones[i]
      found = -1
      unless bone.type is "JOINT"
        continue

      joints_length = skin.joints.length
      for j in [0...joints_length]
        if bone.sid is skin.joints[j]
          found = j
          break

      if found >= 0
        inv = skin.invBindMatrices[found]
        bone.invBindMatrix  = inv
        bone.skinningMatrix = new THREE.Matrix4()
        bone.skinningMatrix.multiply bone.world, inv
        bone.weights = []

        weights_length = skin.weights.length
        for j in [0...weights_length]

          current_length = skin.weights[j].length 
          for k in [0...current_length]
            w = skin.weights[j][k]
            bone.weights.push w if w.joint is found

      else
        throw "ColladaLoader: Could not find joint '" + bone.sid + "'."

  applySkin: (geometry, instanceCtrl, frame) ->
    skinController = @controllers[instanceCtrl.url]
    if frame is undefined
      frame = 40

    if not skinController or not skinController.skin
      console.warn "ColladaLoader: Could not find skin controller."
      return
    if not instanceCtrl.skeleton or not instanceCtrl.skeleton.length
      console.warn "ColladaLoader: Could not find the skeleton for the skin. "
      return

    animationBounds = @calcAnimationBounds()
    skeleton        = @daeScene.getChildById(instanceCtrl.skeleton[0], true) or @daeScene.getChildBySid(instanceCtrl.skeleton[0], true)
    v               = new THREE.Vector3()
    
    # move vertices to bind shape
    vertices_length = geometry.vertices.length
    for i in [0...vertices_length]
      skinController.skin.bindShapeMatrix.multiplyVector3 geometry.vertices[i]

    # process animation, or simply pose the rig if no animation
    frames_length = animationBounds.frames
    for frame in [0...frames_length]
      bones   = []
      skinned = []
      
      # zero skinned vertices
      vertices_length = geometry.vertices.length 
      for i in [0...vertices_length]
        skinned.push new THREE.Vector3()
        
      # process the frame and setup the rig with a fresh
      # transform, possibly from the bone's animation channel(s)
      @setupSkeleton         skeleton, bones, frame
      @setupSkinningMatrices bones,    skinController.skin

      bones_length = bones.length
      for i in [0...bones_length]
        unless bones[i].type is "JOINT"
          continue
          
        weights_length = bones[i].weights.length
        for j in [0...weights_length]
          w       = bones[i].weights[j]
          vidx    = w.index
          weight  = w.weight
          o       = geometry.vertices[vidx]
          s       = skinned[vidx]
          v.x     = o.x
          v.y     = o.y
          v.z     = o.z
          bones[i].skinningMatrix.multiplyVector3 v

          s.x += v.x * weight
          s.y += v.y * weight
          s.z += v.z * weight

      geometry.morphTargets.push
        name:     "target_" + frame
        vertices: skinned

  createSceneGraph: (node, parent) ->
    obj     = new THREE.Object3D()
    skinned = false

    controllers_length = node.controllers.length
    # FIXME: controllers
    for i in [0...controllers_length]
      controller = @controllers[node.controllers[i].url]

      switch controller.type
        when "skin"
          if @geometries[controller.skin.source]
            inst_geom                   = new THREE.Collada.InstanceGeometry this
            inst_geom.url               = controller.skin.source
            inst_geom.instance_material = node.controllers[i].instance_material
            node.geometries.push inst_geom

            skinned         = true
            skinController  = node.controllers[i]

          else if controllers[controller.skin.source]          
            # urgh: controller can be chained
            # handle the most basic case... 
            second = controllers[controller.skin.source]
            morphController = second
            # skinController = node.controllers[i]
            
            if second.morph and @geometries[second.morph.source]
              inst_geom                   = new THREE.Collada.InstanceGeometry this
              inst_geom.url               = second.morph.source
              inst_geom.instance_material = node.controllers[i].instance_material
              node.geometries.push inst_geom

        when "morph"
          if @geometries[controller.morph.source]
            inst_geom                   = new THREE.Collada.InstanceGeometry this
            inst_geom.url               = controller.morph.source
            inst_geom.instance_material = node.controllers[i].instance_material
            node.geometries.push inst_geom

            morphController = node.controllers[i]
          console.warn "ColladaLoader: Morph-controller partially supported."

    # FIXME: multi-material mesh?
    # geometries
    geometries_length = node.geometries.length
    for i in [0...geometries_length]
      instance_geometry   = node.geometries[i]
      instance_materials  = instance_geometry.instance_material
      
      geometry              = @geometries[instance_geometry.url]
      used_materials        = {}
      used_materials_array  = []
      num_materials         = 0

      if geometry
        if not geometry.mesh or not geometry.mesh.primitives
          continue
        obj.name = geometry.id if obj.name.length is 0
        
        # collect used fx for this geometry-instance
        if instance_materials
          materials_length = instance_materials.length
          for j in [0...materials_length]
            instance_material = instance_materials[j]

            mat       = @materials[instance_material.target]
            effect_id = mat.instance_effect.url
            shader    = @effects[effect_id].shader
            if not shader.material.opacity
              shader.material.opacity = 1
            else
              shader.material.opacity = shader.material.opacity

            used_materials[instance_material.symbol] = num_materials
            used_materials_array.push shader.material

            first_material = shader.material
            if not mat.name? or mat.name is ""
              first_material.name = mat.id
            else
              first_material.name = mat.name

            num_materials++

        material = first_material or new THREE.MeshLambertMaterial(
          color:    0xdddddd
          shading:  THREE.FlatShading
        )
        geom = geometry.mesh.geometry3js

        if num_materials > 1
          material        = new THREE.MeshFaceMaterial()
          geom.materials  = used_materials_array

          faces_length = geom.faces.length
          for j in [0...faces_length]
            face = geom.faces[j]
            face.materialIndex = used_materials[face.daeMaterial]

        if skinController isnt undefined
          @applySkin geom, skinController
          material.morphTargets = true
          
          mesh                        = new THREE.SkinnedMesh geom, material
          mesh.skeleton               = skinController.skeleton
          mesh.skinController         = @controllers[skinController.url]
          mesh.skinInstanceController = skinController
          mesh.name = "skin_" + @skins.length
          @skins.push mesh

        else if morphController isnt undefined
          @createMorph geom, morphController
          material.morphTargets = true
          mesh      = new THREE.Mesh geom, material
          # mesh.geom.name = geometry.id
          mesh.name = "morph_" + @morphs.length
          @morphs.push mesh
        else
          mesh = new THREE.Mesh(geom, material)

        if node.geometries.length > 1
          obj.add mesh
        else
          obj = mesh

    cameras_length = node.cameras.length
    for i in [0...cameras_length]
      instance_camera = node.cameras[i]
      cparams         = @cameras[instance_camera.url]
      obj             = new THREE.PerspectiveCamera cparams.fov, cparams.aspect_ratio, cparams.znear, cparams.zfar

    props = node.matrix.decompose()
    obj.name          = node.id or ""
    obj.matrix        = node.matrix
    obj.position      = props[0]
    obj.quaternion    = props[1]
    obj.useQuaternion = true
    obj.scale         = props[2]

    if @options.centerGeometry and obj.geometry
      delta = THREE.GeometryUtils.center obj.geometry
      obj.quaternion.multiplyVector3 delta.multiplySelf(obj.scale)
      obj.position.subSelf delta

    nodes_length = node.nodes.length
    for i in [0...nodes_length]
      obj.add @createSceneGraph(node.nodes[i], node)

    obj

  getJointId: (skin, id) ->
    length = skin.joints.length
    for i in [0...length]
      return i if skin.joints[i] is id

  getLibraryNode: (id) ->
    @COLLADA.evaluate(
      ".//dae:library_nodes//dae:node[@id='" + id + "']"
      @COLLADA
      ColladaLoader._nsResolver
      XPathResult.ORDERED_NODE_ITERATOR_TYPE
      null
    ).iterateNext()

  getChannelsForNode: (node) ->
    channels  = []
    startTime = 1000000
    endTime   = -1000000

    for id of @animations
      animation = @animations[id]

      channel_length = animation.channel.length
      for i in [0...channel_length]
        channel = animation.channel[i]
        sampler = animation.sampler[i]
        id      = channel.target.split("/")[0]

        if id is node.id
          sampler.create()
          channel.sampler = sampler
          startTime       = Math.min startTime, sampler.startTime
          endTime         = Math.max endTime,   sampler.endTime
          channels.push channel

    if channels.length
      node.startTime  = startTime
      node.endTime    = endTime
    channels

  calcFrameDuration: (node) ->
    minT = 10000000

    channels_length = node.channels.length
    for i in [0...channels_length]
      sampler = node.channels[i].sampler

      input_length_1 = sampler.input.length - 1
      for j in [0...input_length_1]
        t0    = sampler.input[j]
        t1    = sampler.input[j + 1]
        minT  = Math.min minT, t1 - t0

    minT

  calcMatrixAt: (node, t) ->
    animated = {}

    length = node.channels.length
    for i in [0...length]
      channel = node.channels[i]
      animated[channel.sid] = channel

    matrix = new THREE.Matrix4()

    length = node.transforms.length
    for i in [0...length]
      transform = node.transforms[i]
      channel   = animated[transform.sid]
      if channel isnt undefined
        sampler = channel.sampler
        
        input_length_1 = sampler.input.length - 1
        for j in [0...input_length_1]
          if sampler.input[j + 1] > t
            value = sampler.output[j]
            # console.log value.flatten
            break

        if value isnt undefined
          if value instanceof THREE.Matrix4
            # FIXME: handle other types
            matrix = matrix.multiply matrix, value
          else
            matrix = matrix.multiply matrix, transform.matrix
        else
          matrix = matrix.multiply matrix, transform.matrix
      else
        matrix = matrix.multiply matrix, transform.matrix

    matrix

  bakeAnimations: (node) ->
    if node.channels and node.channels.length
      keys = []
      sids = []

      channels_length = node.channels.length
      for i in [0...channels_length]
        channel   = node.channels[i]
        fullSid   = channel.fullSid
        sampler   = channel.sampler
        input     = sampler.input
        transform = node.getTransformBySid channel.sid

        if channel.arrIndices
          member = []
          
          indices_length = channel.arrIndices.length
          for j in [0...indices_length]
            member[j] = @getConvertedIndex channel.arrIndices[j]
        else
          member = @getConvertedMember channel.member
        if transform
          sids.push fullSid if sids.indexOf(fullSid) is -1

          input_length = input.length
          for j in [0...input_length]
            time  = input[j]
            data  = sampler.getData transform.type, j
            key   = ColladaLoader.findKey keys, time
            unless key
              key     = new THREE.Collada.Key time
              timeNdx = ColladaLoader.findTimeNdx keys, time
              if timeNdx is -1
                keys.splice keys.length,  0, key
              else
                keys.splice timeNdx,      0, key

            key.addTarget fullSid, transform, member, data
        else
          console.warn "Could not find transform '", channel.sid, "' in node ", node.id

      # post process
      sids_length = sids.length
      for i in [0...sids_length]
        sid = sids[i]

        keys_length = keys.length
        for j in [0...keys_length]
          key = keys[j]
          ColladaLoader.interpolateKeys keys, key, j, sid unless key.hasTarget(sid)

      node.keys = keys
      node.sids = sids

  @findKey: (keys, time) ->
    result  = null
    length  = keys.length
    for i in [0...length] when not result?
      key = keys[i]
      if key.time is time
        result = key
      else if key.time > time
        break

    result

  @findTimeNdx: (keys, time) ->
    ndx     = -1
    length  = keys.length

    for i in [0...length] when ndx is -1
      key = keys[i]
      ndx = i if key.time >= time

    ndx

  @interpolateKeys: (keys, key, ndx, fullSid) ->
    if ndx
      prevKey = ColladaLoader.getPrevKeyWith keys, fullSid, ndx - 1
    else
      prevKey = ColladaLoader.getPrevKeyWith keys, fullSid, 0
    if ndx
      prevKey = ColladaLoader.getPrevKeyWith keys, fullSid, ndx - 1
    else
      prevKey = ColladaLoader.getPrevKeyWith keys, fullSid, 0
    nextKey = ColladaLoader.getNextKeyWith keys, fullSid, ndx + 1

    if prevKey and nextKey
      scale       = (key.time - prevKey.time) / (nextKey.time - prevKey.time)
      prevTarget  = prevKey.getTarget fullSid
      nextData    = nextKey.getTarget(fullSid).data
      prevData    = prevTarget.data

      if prevTarget.type is "matrix"
        data = prevData
      else if prevData.length
        data = []

        length = prevData.length
        for i in [0...length]
          data[i] = prevData[i] + (nextData[i] - prevData[i]) * scale
      else
        data = prevData + (nextData - prevData) * scale

      key.addTarget fullSid, prevTarget.transform, prevTarget.member, data

  # Get next key with given sid
  @getNextKeyWith: (keys, fullSid, ndx) ->
    length = keys.length
    for ndx in [0...length]
      key = keys[ndx]
      return key if key.hasTarget(fullSid)

    null

  # Get previous key with given sid
  @getPrevKeyWith: (keys, fullSid, ndx) ->
    unless ndx >= 0
      ndx = ndx + keys.length

    for i in [ndx..0]
      key = keys[ndx]
      return key if key.hasTarget(fullSid)
    null

  _source: (element) ->
    id = element.getAttribute "id"
    return @sources[id] unless @sources[id] is undefined
    @sources[id] = new THREE.Collada.Source(this, id).parse element

  @_nsResolver: (nsPrefix) ->
    return "http://www.collada.org/2005/11/COLLADASchema" if nsPrefix is "dae"
    null

  @_bools: (str) ->
    raw   = ColladaLoader._strings(str)
    data  = []
    
    length = raw.length
    for i in [0...length]
      if raw[i] is "true" or raw[i] is "1"
        data.push true
      else
        data.push false

    data

  @_floats: (str) ->
    raw   = ColladaLoader._strings(str)
    data  = []

    length = raw.length
    for i in [0...length]
      data.push parseFloat(raw[i])

    data

  @_ints: (str) ->
    raw   = ColladaLoader._strings(str)
    data  = []

    length = raw.length
    for i in [0...length]
      data.push parseInt(raw[i], 10)

    data

  @_strings: (str) ->
    if str.length > 0 
      ColladaLoader._trimString(str).split /\s+/
    else
      []

  @_trimString: (str) ->
    str.replace(/^\s+/, "").replace /\s+$/, ""

  @_attr_as_float: (element, name, defaultValue) ->
    if element.hasAttribute(name)
      parseFloat element.getAttribute(name)
    else
      defaultValue

  @_attr_as_int: (element, name, defaultValue) ->
    if element.hasAttribute(name)
      parseInt element.getAttribute(name), 10
    else
      defaultValue

  @_attr_as_string: (element, name, defaultValue) ->
    if element.hasAttribute(name)
      element.getAttribute name
    else
      defaultValue

  @_format_float: (f, num) ->
    if f is undefined
      s = "0."
      while s.length < num + 2
        s += "0"
      return s

    num   = num or 2
    parts = f.toString().split(".")
    if parts.length > 1
      parts[1] = parts[1].substr 0, num
    else
      parts[1] = "0"

    while parts[1].length < num
      parts[1] += "0"

    parts.join "."

  evaluateXPath: (node, query) ->
    instances = @COLLADA.evaluate query, node, ColladaLoader._nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null
    inst = instances.iterateNext()
    result = []
    while inst
      result.push inst
      inst = instances.iterateNext()
    result
    
  # Up axis conversion
  setUpConversion: ->
    if not @options.convertUpAxis or @colladaUp is @options.upAxis
      @upConversion = null
    else
      switch @colladaUp
        when "X"
          if @options.upAxis is "Y"
            @upConversion = "XtoY"
          else
            @upConversion = "XtoZ" 
        when "Y"
          if @options.upAxis is "X"
            @upConversion = "YtoX"
          else
            @upConversion = "YtoZ"
        when "Z"
          if @options.upAxis is "X"
            @upConversion = "ZtoX"
          else
            @upConversion = "ZtoY"

  fixCoords: (data, sign) ->
    if not @options.convertUpAxis or @colladaUp is @options.upAxis
      return

    switch @upConversion
      when "XtoY"
        tmp     = data[0]
        data[0] = sign * data[1]
        data[1] = tmp
      when "XtoZ"
        tmp     = data[2]
        data[2] = data[1]
        data[1] = data[0]
        data[0] = tmp
      when "YtoX"
        tmp     = data[0]
        data[0] = data[1]
        data[1] = sign * tmp
      when "YtoZ"
        tmp     = data[1]
        data[1] = sign * data[2]
        data[2] = tmp
      when "ZtoX"
        tmp     = data[0]
        data[0] = data[1]
        data[1] = data[2]
        data[2] = tmp
      when "ZtoY"
        tmp     = data[1]
        data[1] = data[2]
        data[2] = sign * tmp

  getConvertedVec3: (data, offset) ->
    arr = [
      data[offset]
      data[offset + 1]
      data[offset + 2]
    ]
    @fixCoords arr, -1
    new THREE.Vector3 arr[0], arr[1], arr[2]
  
  getConvertedMat4: (data) ->
    if @options.convertUpAxis
      # First fix rotation and scale
      # Columns first
      arr       = [data[0], data[4], data[8]]
      @fixCoords arr, -1
      data[0]   = arr[0]
      data[4]   = arr[1]
      data[8]   = arr[2]

      arr       = [data[1], data[5], data[9]]
      @fixCoords arr, -1
      data[1]   = arr[0]
      data[5]   = arr[1]
      data[9]   = arr[2]

      arr       = [data[2], data[6], data[10]]
      @fixCoords arr, -1
      data[2]   = arr[0]
      data[6]   = arr[1]
      data[10]  = arr[2]
      
      # Rows second
      arr       = [data[0], data[1], data[2]]
      @fixCoords arr, -1
      data[0]   = arr[0]
      data[1]   = arr[1]
      data[2]   = arr[2]

      arr       = [data[4], data[5], data[6]]
      @fixCoords arr, -1
      data[4]   = arr[0]
      data[5]   = arr[1]
      data[6]   = arr[2]

      arr       = [data[8], data[9], data[10]]
      @fixCoords arr, -1
      data[8]   = arr[0]
      data[9]   = arr[1]
      data[10]  = arr[2]
      
      # Now fix translation
      arr       = [data[3], data[7], data[11]]
      @fixCoords arr, -1
      data[3]   = arr[0]
      data[7]   = arr[1]
      data[11]  = arr[2]

    new THREE.Matrix4(
      data[0],  data[1],  data[2],  data[3]
      data[4],  data[5],  data[6],  data[7]
      data[8],  data[9],  data[10], data[11]
      data[12], data[13], data[14], data[15]
    )

  getConvertedIndex: (index) ->
    if index > -1 and index < 3
      members = ["X", "Y", "Z"]
      indices =
        X: 0
        Y: 1
        Z: 2

      index = @getConvertedMember members[index]
      index = indices[index]
    index

  getConvertedMember: (member) ->
    if @options.convertUpAxis
      switch member
        when "X"
          switch @upConversion
            when "XtoY", "XtoZ", "YtoX"
              member = "Y"
            when "ZtoX"
              member = "Z"
        when "Y"
          switch @upConversion
            when "XtoY", "YtoX", "ZtoX"
              member = "X"
            when "XtoZ", "YtoZ", "ZtoY"
              member = "Z"
        when "Z"
          switch @upConversion
            when "XtoZ"
              member = "X"
            when "YtoZ", "ZtoX", "ZtoY"
              member = "Y"
    member

namespace "THREE", (exports) ->
  exports.ColladaLoader = ColladaLoader
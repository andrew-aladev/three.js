# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class ColladaLoader extends THREE.Loader
  
  load: (url, readyCallback, progressCallback) ->
    length = 0
    if document.implementation and document.implementation.createDocument
      req = new XMLHttpRequest()
      req.overrideMimeType "text/xml"  if req.overrideMimeType
      req.onreadystatechange = ->
        if req.readyState is 4
          if req.status is 0 or req.status is 200
            if req.responseXML
              readyCallbackFunc = readyCallback
              parse req.responseXML, `undefined`, url
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
    COLLADA = doc
    callBack = callBack or readyCallbackFunc
    if url isnt `undefined`
      parts = url.split("/")
      parts.pop()
      baseUrl = (if parts.length < 1 then "." else parts.join("/")) + "/"
    parseAsset()
    setUpConversion()
    images = parseLib("//dae:library_images/dae:image", _Image, "image")
    materials = parseLib("//dae:library_materials/dae:material", Material, "material")
    effects = parseLib("//dae:library_effects/dae:effect", Effect, "effect")
    geometries = parseLib("//dae:library_geometries/dae:geometry", Geometry, "geometry")
    cameras = parseLib(".//dae:library_cameras/dae:camera", Camera, "camera")
    controllers = parseLib("//dae:library_controllers/dae:controller", Controller, "controller")
    animations = parseLib("//dae:library_animations/dae:animation", Animation, "animation")
    visualScenes = parseLib(".//dae:library_visual_scenes/dae:visual_scene", VisualScene, "visual_scene")
    morphs = []
    skins = []
    daeScene = parseScene()
    scene = new THREE.Object3D()
    i = 0

    while i < daeScene.nodes.length
      scene.add createSceneGraph(daeScene.nodes[i])
      i++
    createAnimations()
    result =
      scene: scene
      morphs: morphs
      skins: skins
      animations: animData
      dae:
        images: images
        materials: materials
        cameras: cameras
        effects: effects
        geometries: geometries
        controllers: controllers
        animations: animations
        visualScenes: visualScenes
        scene: daeScene

    callBack result  if callBack
    result

  setPreferredShading: (shading) ->
    preferredShading = shading

  parseAsset: ->
    elements = COLLADA.evaluate("//dae:asset", COLLADA, _nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null)
    element = elements.iterateNext()
    if element and element.childNodes
      i = 0

      while i < element.childNodes.length
        child = element.childNodes[i]
        switch child.nodeName
          when "unit"
            meter = child.getAttribute("meter")
            colladaUnit = parseFloat(meter)  if meter
          when "up_axis"
            colladaUp = child.textContent.charAt(0)
        i++

  parseLib: (q, classSpec, prefix) ->
    elements = COLLADA.evaluate(q, COLLADA, _nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null)
    lib = {}
    element = elements.iterateNext()
    i = 0
    while element
      daeElement = (new classSpec()).parse(element)
      daeElement.id = prefix + (i++)  if not daeElement.id or daeElement.id.length is 0
      lib[daeElement.id] = daeElement
      element = elements.iterateNext()
    lib

  parseScene: ->
    sceneElement = COLLADA.evaluate(".//dae:scene/dae:instance_visual_scene", COLLADA, _nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null).iterateNext()
    if sceneElement
      url = sceneElement.getAttribute("url").replace(/^#/, "")
      visualScenes[(if url.length > 0 then url else "visual_scene0")]
    else
      null

  createAnimations: ->
    animData = []
    
    # fill in the keys
    recurseHierarchy scene

  recurseHierarchy: (node) ->
    n = daeScene.getChildById(node.name, true)
    newData = null
    if n and n.keys
      newData =
        fps: 60
        hierarchy: [
          node: n
          keys: n.keys
          sids: n.sids
         ]
        node: node
        name: "animation_" + node.name
        length: 0

      animData.push newData
      i = 0
      il = n.keys.length

      while i < il
        newData.length = Math.max(newData.length, n.keys[i].time)
        i++
    else
      newData = hierarchy: [
        keys: []
        sids: []
       ]
    i = 0
    il = node.children.length

    while i < il
      d = recurseHierarchy(node.children[i])
      j = 0
      jl = d.hierarchy.length

      while j < jl
        newData.hierarchy.push
          keys: []
          sids: []
        j++
      i++
    newData

  calcAnimationBounds: ->
    start = 1000000
    end = -start
    frames = 0
    for id of animations
      animation = animations[id]
      i = 0

      while i < animation.sampler.length
        sampler = animation.sampler[i]
        sampler.create()
        start = Math.min(start, sampler.startTime)
        end = Math.max(end, sampler.endTime)
        frames = Math.max(frames, sampler.input.length)
        i++
    start: start
    end: end
    frames: frames

  createMorph: (geometry, ctrl) ->
    morphCtrl = (if ctrl instanceof InstanceController then controllers[ctrl.url] else ctrl)
    if not morphCtrl or not morphCtrl.morph
      console.log "could not find morph controller!"
      return
    morph = morphCtrl.morph
    i = 0

    while i < morph.targets.length
      target_id = morph.targets[i]
      daeGeometry = geometries[target_id]
      continue  if not daeGeometry.mesh or not daeGeometry.mesh.primitives or not daeGeometry.mesh.primitives.length
      target = daeGeometry.mesh.primitives[0].geometry
      if target.vertices.length is geometry.vertices.length
        geometry.morphTargets.push
          name: "target_1"
          vertices: target.vertices
      i++
    geometry.morphTargets.push
      name: "target_Z"
      vertices: geometry.vertices

  createSkin: (geometry, ctrl, applyBindShape) ->
    skinCtrl = controllers[ctrl.url]
    if not skinCtrl or not skinCtrl.skin
      console.log "could not find skin controller!"
      return
    if not ctrl.skeleton or not ctrl.skeleton.length
      console.log "could not find the skeleton for the skin!"
      return
    skin = skinCtrl.skin
    skeleton = daeScene.getChildById(ctrl.skeleton[0])
    hierarchy = []
    
    # createBones geometry.bones, skin, hierarchy, skeleton, null, -1
    # createWeights skin, geometry.bones, geometry.skinIndices, geometry.skinWeights
    # geometry.animation =
      # name: 'take_001'
      # fps: 30
      # length: 2
      # JIT: true
      # hierarchy: hierarchy
    applyBindShape = (if applyBindShape isnt `undefined` then applyBindShape else true)
    bones = []
    geometry.skinWeights = []
    geometry.skinIndices = []
    if applyBindShape
      i = 0

      while i < geometry.vertices.length
        skin.bindShapeMatrix.multiplyVector3 geometry.vertices[i]
        i++

  setupSkeleton: (node, bones, frame, parent) ->
    node.world = node.world or new THREE.Matrix4()
    node.world.copy node.matrix
    if node.channels and node.channels.length
      channel = node.channels[0]
      m = channel.sampler.output[frame]
      node.world.copy m  if m instanceof THREE.Matrix4
    node.world.multiply parent, node.world  if parent
    bones.push node
    i = 0

    while i < node.nodes.length
      setupSkeleton node.nodes[i], bones, frame, node.world
      i++

  setupSkinningMatrices: (bones, skin) ->
    # FIXME: this is dumb...
    i = 0

    # skin 'm
    while i < bones.length
      bone = bones[i]
      found = -1
      continue  unless bone.type is "JOINT"
      j = 0

      while j < skin.joints.length
        if bone.sid is skin.joints[j]
          found = j
          break
        j++
      if found >= 0
        inv = skin.invBindMatrices[found]
        bone.invBindMatrix = inv
        bone.skinningMatrix = new THREE.Matrix4()
        bone.skinningMatrix.multiply bone.world, inv
        bone.weights = []
        j = 0

        while j < skin.weights.length
          k = 0

          while k < skin.weights[j].length
            w = skin.weights[j][k]
            bone.weights.push w  if w.joint is found
            k++
          j++
      else
        throw "ColladaLoader: Could not find joint '" + bone.sid + "'."
      i++

  applySkin: (geometry, instanceCtrl, frame) ->
    skinController = controllers[instanceCtrl.url]
    frame = (if frame isnt `undefined` then frame else 40)
    if not skinController or not skinController.skin
      console.log "ColladaLoader: Could not find skin controller."
      return
    if not instanceCtrl.skeleton or not instanceCtrl.skeleton.length
      console.log "ColladaLoader: Could not find the skeleton for the skin. "
      return
    animationBounds = calcAnimationBounds()
    skeleton = daeScene.getChildById(instanceCtrl.skeleton[0], true) or daeScene.getChildBySid(instanceCtrl.skeleton[0], true)
    i = undefined
    j = undefined
    w = undefined
    vidx = undefined
    weight = undefined
    v = new THREE.Vector3()
    o = undefined
    s = undefined
    i = 0
    
    # move vertices to bind shape
    while i < geometry.vertices.length
      skinController.skin.bindShapeMatrix.multiplyVector3 geometry.vertices[i]
      i++
    frame = 0
    
    # process animation, or simply pose the rig if no animation
    while frame < animationBounds.frames
      bones = []
      skinned = []
      i = 0
      
      # zero skinned vertices
      while i < geometry.vertices.length
        skinned.push new THREE.Vector3()
        i++
        
      # process the frame and setup the rig with a fresh
      # transform, possibly from the bone's animation channel(s)
      setupSkeleton skeleton, bones, frame
      setupSkinningMatrices bones, skinController.skin
      i = 0
      while i < bones.length
        continue  unless bones[i].type is "JOINT"
        j = 0
        while j < bones[i].weights.length
          w = bones[i].weights[j]
          vidx = w.index
          weight = w.weight
          o = geometry.vertices[vidx]
          s = skinned[vidx]
          v.x = o.x
          v.y = o.y
          v.z = o.z
          bones[i].skinningMatrix.multiplyVector3 v
          s.x += (v.x * weight)
          s.y += (v.y * weight)
          s.z += (v.z * weight)
          j++
        i++
      geometry.morphTargets.push
        name: "target_" + frame
        vertices: skinned
      frame++

  createSceneGraph: (node, parent) ->
    obj = new THREE.Object3D()
    skinned = false
    skinController = undefined
    morphController = undefined
    i = undefined
    j = undefined
    i = 0
    
    # FIXME: controllers
    while i < node.controllers.length
      controller = controllers[node.controllers[i].url]
      switch controller.type
        when "skin"
          if geometries[controller.skin.source]
            inst_geom = new InstanceGeometry()
            inst_geom.url = controller.skin.source
            inst_geom.instance_material = node.controllers[i].instance_material
            node.geometries.push inst_geom
            skinned = true
            skinController = node.controllers[i]
          else if controllers[controller.skin.source]
          
            # urgh: controller can be chained
            # handle the most basic case... 
            second = controllers[controller.skin.source]
            morphController = second
            # skinController = node.controllers[i]
            
            if second.morph and geometries[second.morph.source]
              inst_geom = new InstanceGeometry()
              inst_geom.url = second.morph.source
              inst_geom.instance_material = node.controllers[i].instance_material
              node.geometries.push inst_geom
        when "morph"
          if geometries[controller.morph.source]
            inst_geom = new InstanceGeometry()
            inst_geom.url = controller.morph.source
            inst_geom.instance_material = node.controllers[i].instance_material
            node.geometries.push inst_geom
            morphController = node.controllers[i]
          console.log "ColladaLoader: Morph-controller partially supported."
        else
      i++
    i = 0
    
    # FIXME: multi-material mesh?
    # geometries
    while i < node.geometries.length
      instance_geometry = node.geometries[i]
      instance_materials = instance_geometry.instance_material
      geometry = geometries[instance_geometry.url]
      used_materials = {}
      used_materials_array = []
      num_materials = 0
      first_material = undefined
      if geometry
        continue  if not geometry.mesh or not geometry.mesh.primitives
        obj.name = geometry.id  if obj.name.length is 0
        
        # collect used fx for this geometry-instance
        if instance_materials
          j = 0
          while j < instance_materials.length
            instance_material = instance_materials[j]
            mat = materials[instance_material.target]
            effect_id = mat.instance_effect.url
            shader = effects[effect_id].shader
            shader.material.opacity = (if not shader.material.opacity then 1 else shader.material.opacity)
            used_materials[instance_material.symbol] = num_materials
            used_materials_array.push shader.material
            first_material = shader.material
            first_material.name = (if not mat.name? or mat.name is "" then mat.id else mat.name)
            num_materials++
            j++
        mesh = undefined
        material = first_material or new THREE.MeshLambertMaterial(
          color: 0xdddddd
          shading: THREE.FlatShading
        )
        geom = geometry.mesh.geometry3js
        if num_materials > 1
          material = new THREE.MeshFaceMaterial()
          geom.materials = used_materials_array
          j = 0
          while j < geom.faces.length
            face = geom.faces[j]
            face.materialIndex = used_materials[face.daeMaterial]
            j++
        if skinController isnt `undefined`
          applySkin geom, skinController
          material.morphTargets = true
          mesh = new THREE.SkinnedMesh(geom, material)
          mesh.skeleton = skinController.skeleton
          mesh.skinController = controllers[skinController.url]
          mesh.skinInstanceController = skinController
          mesh.name = "skin_" + skins.length
          skins.push mesh
        else if morphController isnt `undefined`
          createMorph geom, morphController
          material.morphTargets = true
          mesh = new THREE.Mesh(geom, material)
          # mesh.geom.name = geometry.id
          
          mesh.name = "morph_" + morphs.length
          morphs.push mesh
        else
          mesh = new THREE.Mesh(geom, material)
        (if node.geometries.length > 1 then obj.add(mesh) else obj = mesh)
      i++
    i = 0
    while i < node.cameras.length
      instance_camera = node.cameras[i]
      cparams = cameras[instance_camera.url]
      obj = new THREE.PerspectiveCamera(cparams.fov, cparams.aspect_ratio, cparams.znear, cparams.zfar)
      i++
    obj.name = node.id or ""
    obj.matrix = node.matrix
    props = node.matrix.decompose()
    obj.position = props[0]
    obj.quaternion = props[1]
    obj.useQuaternion = true
    obj.scale = props[2]
    if options.centerGeometry and obj.geometry
      delta = THREE.GeometryUtils.center(obj.geometry)
      obj.quaternion.multiplyVector3 delta.multiplySelf(obj.scale)
      obj.position.subSelf delta
    i = 0
    while i < node.nodes.length
      obj.add createSceneGraph(node.nodes[i], node)
      i++
    obj

  getJointId: (skin, id) ->
    i = 0

    while i < skin.joints.length
      return i  if skin.joints[i] is id
      i++

  getLibraryNode: (id) ->
    COLLADA.evaluate(".//dae:library_nodes//dae:node[@id='" + id + "']", COLLADA, _nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null).iterateNext()

  getChannelsForNode: (node) ->
    channels = []
    startTime = 1000000
    endTime = -1000000
    for id of animations
      animation = animations[id]
      i = 0

      while i < animation.channel.length
        channel = animation.channel[i]
        sampler = animation.sampler[i]
        id = channel.target.split("/")[0]
        if id is node.id
          sampler.create()
          channel.sampler = sampler
          startTime = Math.min(startTime, sampler.startTime)
          endTime = Math.max(endTime, sampler.endTime)
          channels.push channel
        i++
    if channels.length
      node.startTime = startTime
      node.endTime = endTime
    channels

  calcFrameDuration: (node) ->
    minT = 10000000
    i = 0

    while i < node.channels.length
      sampler = node.channels[i].sampler
      j = 0

      while j < sampler.input.length - 1
        t0 = sampler.input[j]
        t1 = sampler.input[j + 1]
        minT = Math.min(minT, t1 - t0)
        j++
      i++
    minT

  calcMatrixAt: (node, t) ->
    animated = {}
    i = undefined
    j = undefined
    i = 0
    while i < node.channels.length
      channel = node.channels[i]
      animated[channel.sid] = channel
      i++
    matrix = new THREE.Matrix4()
    i = 0
    while i < node.transforms.length
      transform = node.transforms[i]
      channel = animated[transform.sid]
      if channel isnt `undefined`
        sampler = channel.sampler
        value = undefined
        j = 0
        while j < sampler.input.length - 1
          if sampler.input[j + 1] > t
            value = sampler.output[j]
            # console.log value.flatten
            break
          j++
        if value isnt `undefined`
          if value instanceof THREE.Matrix4
            
            # FIXME: handle other types
            matrix = matrix.multiply(matrix, value)
          else
            matrix = matrix.multiply(matrix, transform.matrix)
        else
          matrix = matrix.multiply(matrix, transform.matrix)
      else
        matrix = matrix.multiply(matrix, transform.matrix)
      i++
    matrix

  bakeAnimations: (node) ->
    if node.channels and node.channels.length
      keys = []
      sids = []
      i = 0
      il = node.channels.length

      while i < il
        channel = node.channels[i]
        fullSid = channel.fullSid
        sampler = channel.sampler
        input = sampler.input
        transform = node.getTransformBySid(channel.sid)
        member = undefined
        if channel.arrIndices
          member = []
          j = 0
          jl = channel.arrIndices.length

          while j < jl
            member[j] = getConvertedIndex(channel.arrIndices[j])
            j++
        else
          member = getConvertedMember(channel.member)
        if transform
          sids.push fullSid  if sids.indexOf(fullSid) is -1
          j = 0
          jl = input.length

          while j < jl
            time = input[j]
            data = sampler.getData(transform.type, j)
            key = findKey(keys, time)
            unless key
              key = new Key(time)
              timeNdx = findTimeNdx(keys, time)
              keys.splice (if timeNdx is -1 then keys.length else timeNdx), 0, key
            key.addTarget fullSid, transform, member, data
            j++
        else
          console.log "Could not find transform \"" + channel.sid + "\" in node " + node.id
        i++
      i = 0

      # post process
      while i < sids.length
        sid = sids[i]
        j = 0

        while j < keys.length
          key = keys[j]
          interpolateKeys keys, key, j, sid  unless key.hasTarget(sid)
          j++
        i++
      node.keys = keys
      node.sids = sids

  findKey: (keys, time) ->
    retVal = null
    i = 0
    il = keys.length

    while i < il and not retVal?
      key = keys[i]
      if key.time is time
        retVal = key
      else break  if key.time > time
      i++
    retVal

  findTimeNdx: (keys, time) ->
    ndx = -1
    i = 0
    il = keys.length

    while i < il and ndx is -1
      key = keys[i]
      ndx = i  if key.time >= time
      i++
    ndx

  interpolateKeys: (keys, key, ndx, fullSid) ->
    prevKey = getPrevKeyWith(keys, fullSid, (if ndx then ndx - 1 else 0))
    nextKey = getNextKeyWith(keys, fullSid, ndx + 1)
    if prevKey and nextKey
      scale = (key.time - prevKey.time) / (nextKey.time - prevKey.time)
      prevTarget = prevKey.getTarget(fullSid)
      nextData = nextKey.getTarget(fullSid).data
      prevData = prevTarget.data
      data = undefined
      if prevTarget.type is "matrix"
        data = prevData
      else if prevData.length
        data = []
        i = 0

        while i < prevData.length
          data[i] = prevData[i] + (nextData[i] - prevData[i]) * scale
          ++i
      else
        data = prevData + (nextData - prevData) * scale
      key.addTarget fullSid, prevTarget.transform, prevTarget.member, data

  # Get next key with given sid
  getNextKeyWith: (keys, fullSid, ndx) ->
    while ndx < keys.length
      key = keys[ndx]
      return key  if key.hasTarget(fullSid)
      ndx++
    null

  # Get previous key with given sid
  getPrevKeyWith: (keys, fullSid, ndx) ->
    ndx = (if ndx >= 0 then ndx else ndx + keys.length)
    while ndx >= 0
      key = keys[ndx]
      return key  if key.hasTarget(fullSid)
      ndx--
    null


  Shader = (type, effect) ->
    @type = type
    @effect = effect
    @material = null
  Surface = (effect) ->
    @effect = effect
    @init_from = null
    @format = null
  Sampler2D = (effect) ->
    @effect = effect
    @source = null
    @wrap_s = null
    @wrap_t = null
    @minfilter = null
    @magfilter = null
    @mipfilter = null
  Effect = ->
    @id = ""
    @name = ""
    @shader = null
    @surface = null
    @sampler = null
  InstanceEffect = ->
    @url = ""
  Animation = ->
    @id = ""
    @name = ""
    @source = {}
    @sampler = []
    @channel = []
  Channel = (animation) ->
    @animation = animation
    @source = ""
    @target = ""
    @fullSid = null
    @sid = null
    @dotSyntax = null
    @arrSyntax = null
    @arrIndices = null
    @member = null
  Sampler = (animation) ->
    @id = ""
    @animation = animation
    @inputs = []
    @input = null
    @output = null
    @strideOut = null
    @interpolation = null
    @startTime = null
    @endTime = null
    @duration = 0
  Key = (time) ->
    @targets = []
    @time = time
  Camera = ->
    @id = ""
    @name = ""
    @technique = ""
  InstanceCamera = ->
    @url = ""
  _source = (element) ->
    id = element.getAttribute("id")
    return sources[id]  unless sources[id] is `undefined`
    sources[id] = (new Source(id)).parse(element)
    sources[id]
  _nsResolver = (nsPrefix) ->
    return "http://www.collada.org/2005/11/COLLADASchema"  if nsPrefix is "dae"
    null
  _bools = (str) ->
    raw = _strings(str)
    data = []
    i = 0
    l = raw.length

    while i < l
      data.push (if (raw[i] is "true" or raw[i] is "1") then true else false)
      i++
    data
  _floats = (str) ->
    raw = _strings(str)
    data = []
    i = 0
    l = raw.length

    while i < l
      data.push parseFloat(raw[i])
      i++
    data
  _ints = (str) ->
    raw = _strings(str)
    data = []
    i = 0
    l = raw.length

    while i < l
      data.push parseInt(raw[i], 10)
      i++
    data
  _strings = (str) ->
    (if (str.length > 0) then _trimString(str).split(/\s+/) else [])
  _trimString = (str) ->
    str.replace(/^\s+/, "").replace /\s+$/, ""
  _attr_as_float = (element, name, defaultValue) ->
    if element.hasAttribute(name)
      parseFloat element.getAttribute(name)
    else
      defaultValue
  _attr_as_int = (element, name, defaultValue) ->
    if element.hasAttribute(name)
      parseInt element.getAttribute(name), 10
    else
      defaultValue
  _attr_as_string = (element, name, defaultValue) ->
    if element.hasAttribute(name)
      element.getAttribute name
    else
      defaultValue
  _format_float = (f, num) ->
    if f is `undefined`
      s = "0."
      s += "0"  while s.length < num + 2
      return s
    num = num or 2
    parts = f.toString().split(".")
    parts[1] = (if parts.length > 1 then parts[1].substr(0, num) else "0")
    parts[1] += "0"  while parts[1].length < num
    parts.join "."
  evaluateXPath = (node, query) ->
    instances = COLLADA.evaluate(query, node, _nsResolver, XPathResult.ORDERED_NODE_ITERATOR_TYPE, null)
    inst = instances.iterateNext()
    result = []
    while inst
      result.push inst
      inst = instances.iterateNext()
    result
    
  # Up axis conversion
  setUpConversion = ->
    if not options.convertUpAxis or colladaUp is options.upAxis
      upConversion = null
    else
      switch colladaUp
        when "X"
          upConversion = (if options.upAxis is "Y" then "XtoY" else "XtoZ")
        when "Y"
          upConversion = (if options.upAxis is "X" then "YtoX" else "YtoZ")
        when "Z"
          upConversion = (if options.upAxis is "X" then "ZtoX" else "ZtoY")
  fixCoords = (data, sign) ->
    return  if not options.convertUpAxis or colladaUp is options.upAxis
    switch upConversion
      when "XtoY"
        tmp = data[0]
        data[0] = sign * data[1]
        data[1] = tmp
      when "XtoZ"
        tmp = data[2]
        data[2] = data[1]
        data[1] = data[0]
        data[0] = tmp
      when "YtoX"
        tmp = data[0]
        data[0] = data[1]
        data[1] = sign * tmp
      when "YtoZ"
        tmp = data[1]
        data[1] = sign * data[2]
        data[2] = tmp
      when "ZtoX"
        tmp = data[0]
        data[0] = data[1]
        data[1] = data[2]
        data[2] = tmp
      when "ZtoY"
        tmp = data[1]
        data[1] = data[2]
        data[2] = sign * tmp
  getConvertedVec3 = (data, offset) ->
    arr = [ data[offset], data[offset + 1], data[offset + 2] ]
    fixCoords arr, -1
    new THREE.Vector3(arr[0], arr[1], arr[2])
  
  getConvertedMat4 = (data) ->
    if options.convertUpAxis
      
      # First fix rotation and scale
      # Columns first
      arr = [ data[0], data[4], data[8] ]
      fixCoords arr, -1
      data[0] = arr[0]
      data[4] = arr[1]
      data[8] = arr[2]
      arr = [ data[1], data[5], data[9] ]
      fixCoords arr, -1
      data[1] = arr[0]
      data[5] = arr[1]
      data[9] = arr[2]
      arr = [ data[2], data[6], data[10] ]
      fixCoords arr, -1
      data[2] = arr[0]
      data[6] = arr[1]
      data[10] = arr[2]
      
      # Rows second
      arr = [ data[0], data[1], data[2] ]
      fixCoords arr, -1
      data[0] = arr[0]
      data[1] = arr[1]
      data[2] = arr[2]
      arr = [ data[4], data[5], data[6] ]
      fixCoords arr, -1
      data[4] = arr[0]
      data[5] = arr[1]
      data[6] = arr[2]
      arr = [ data[8], data[9], data[10] ]
      fixCoords arr, -1
      data[8] = arr[0]
      data[9] = arr[1]
      data[10] = arr[2]
      
      # Now fix translation
      arr = [ data[3], data[7], data[11] ]
      fixCoords arr, -1
      data[3] = arr[0]
      data[7] = arr[1]
      data[11] = arr[2]
    new THREE.Matrix4(data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7], data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15])
  getConvertedIndex = (index) ->
    if index > -1 and index < 3
      members = [ "X", "Y", "Z" ]
      indices =
        X: 0
        Y: 1
        Z: 2

      index = getConvertedMember(members[index])
      index = indices[index]
    index
  getConvertedMember = (member) ->
    if options.convertUpAxis
      switch member
        when "X"
          switch upConversion
            when "XtoY", "XtoZ"
          , "YtoX"
              member = "Y"
            when "ZtoX"
              member = "Z"
        when "Y"
          switch upConversion
            when "XtoY", "YtoX"
          , "ZtoX"
              member = "X"
            when "XtoZ", "YtoZ"
          , "ZtoY"
              member = "Z"
        when "Z"
          switch upConversion
            when "XtoZ"
              member = "X"
            when "YtoZ", "ZtoX"
          , "ZtoY"
              member = "Y"
    member
  COLLADA = null
  scene = null
  daeScene = undefined
  readyCallbackFunc = null
  sources = {}
  images = {}
  animations = {}
  controllers = {}
  geometries = {}
  materials = {}
  effects = {}
  cameras = {}
  animData = undefined
  visualScenes = undefined
  baseUrl = undefined
  morphs = undefined
  skins = undefined
  flip_uv = true
  preferredShading = THREE.SmoothShading
  
  # Force Geometry to always be centered at the local origin of the containing Mesh
  options =
    centerGeometry: false
    
    # Axis conversion is done for geometries, animations, and controllers.
    # If we ever pull cameras or lights out of the COLLADA file, they'll
    # need extra work.
    convertUpAxis: false
    subdivideFaces: true
    upAxis: "Y"

  # TODO: support unit conversion as well
  colladaUnit = 1.0
  colladaUp = "Y"
  upConversion = null
  TO_RADIANS = Math.PI / 180

  Shader::parse = (element) ->
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "ambient", "emission"
      , "diffuse"
      , "specular"
      , "transparent"
          this[child.nodeName] = (new ColorOrTexture()).parse(child)
        when "shininess", "reflectivity"
      , "transparency"
          f = evaluateXPath(child, ".//dae:float")
          this[child.nodeName] = parseFloat(f[0].textContent)  if f.length > 0
        else
      i++
    @create()
    this

  Shader::create = ->
    props = {}
    transparent = (this["transparency"] isnt `undefined` and this["transparency"] < 1.0)
    for prop of this
      switch prop
        when "ambient", "emission"
      , "diffuse"
      , "specular"
          cot = this[prop]
          if cot instanceof ColorOrTexture
            if cot.isTexture()
              if @effect.sampler and @effect.surface
                if @effect.sampler.source is @effect.surface.sid
                  image = images[@effect.surface.init_from]
                  if image
                    texture = THREE.ImageUtils.loadTexture(baseUrl + image.init_from)
                    texture.wrapS = (if cot.texOpts.wrapU then THREE.RepeatWrapping else THREE.ClampToEdgeWrapping)
                    texture.wrapT = (if cot.texOpts.wrapV then THREE.RepeatWrapping else THREE.ClampToEdgeWrapping)
                    texture.offset.x = cot.texOpts.offsetU
                    texture.offset.y = cot.texOpts.offsetV
                    texture.repeat.x = cot.texOpts.repeatU
                    texture.repeat.y = cot.texOpts.repeatV
                    props["map"] = texture
                    
                    # Texture with baked lighting?
                    props["emissive"] = 0xffffff  if prop is "emission"
            else if prop is "diffuse" or not transparent
              if prop is "emission"
                props["emissive"] = cot.color.getHex()
              else
                props[prop] = cot.color.getHex()
        when "shininess", "reflectivity"
          props[prop] = this[prop]
        when "transparency"
          if transparent
            props["transparent"] = true
            props["opacity"] = this[prop]
            transparent = true
        else
    props["shading"] = preferredShading
    switch @type
      when "constant"
        props.color = props.emission
        @material = new THREE.MeshBasicMaterial(props)
      when "phong", "blinn"
        props.color = props.diffuse
        @material = new THREE.MeshPhongMaterial(props)
      when "lambert"
      else
        props.color = props.diffuse
        @material = new THREE.MeshLambertMaterial(props)
    @material

  Surface::parse = (element) ->
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "init_from"
          @init_from = child.textContent
        when "format"
          @format = child.textContent
        else
          console.log "unhandled Surface prop: " + child.nodeName
      i++
    this

  Sampler2D::parse = (element) ->
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "source"
          @source = child.textContent
        when "minfilter"
          @minfilter = child.textContent
        when "magfilter"
          @magfilter = child.textContent
        when "mipfilter"
          @mipfilter = child.textContent
        when "wrap_s"
          @wrap_s = child.textContent
        when "wrap_t"
          @wrap_t = child.textContent
        else
          console.log "unhandled Sampler2D prop: " + child.nodeName
      i++
    this

  Effect::create = ->
    null  unless @shader?

  Effect::parse = (element) ->
    @id = element.getAttribute("id")
    @name = element.getAttribute("name")
    @shader = null
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "profile_COMMON"
          @parseTechnique @parseProfileCOMMON(child)
        else
      i++
    this

  Effect::parseNewparam = (element) ->
    sid = element.getAttribute("sid")
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "surface"
          @surface = (new Surface(this)).parse(child)
          @surface.sid = sid
        when "sampler2D"
          @sampler = (new Sampler2D(this)).parse(child)
          @sampler.sid = sid
        when "extra"
        else
          console.log child.nodeName
      i++

  Effect::parseProfileCOMMON = (element) ->
    technique = undefined
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "profile_COMMON"
          @parseProfileCOMMON child
        when "technique"
          technique = child
        when "newparam"
          @parseNewparam child
        when "image"
          _image = (new _Image()).parse(child)
          images[_image.id] = _image
        when "extra"
        else
          console.log child.nodeName
      i++
    technique

  Effect::parseTechnique = (element) ->
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "constant", "lambert"
      , "blinn"
      , "phong"
          @shader = (new Shader(child.nodeName, this)).parse(child)
        else
      i++

  InstanceEffect::parse = (element) ->
    @url = element.getAttribute("url").replace(/^#/, "")
    this

  Animation::parse = (element) ->
    @id = element.getAttribute("id")
    @name = element.getAttribute("name")
    @source = {}
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "animation"
          anim = (new Animation()).parse(child)
          for src of anim.source
            @source[src] = anim.source[src]
          j = 0

          while j < anim.channel.length
            @channel.push anim.channel[j]
            @sampler.push anim.sampler[j]
            j++
        when "source"
          src = (new Source()).parse(child)
          @source[src.id] = src
        when "sampler"
          @sampler.push (new Sampler(this)).parse(child)
        when "channel"
          @channel.push (new Channel(this)).parse(child)
        else
      i++
    this

  Channel::parse = (element) ->
    @source = element.getAttribute("source").replace(/^#/, "")
    @target = element.getAttribute("target")
    parts = @target.split("/")
    id = parts.shift()
    sid = parts.shift()
    dotSyntax = (sid.indexOf(".") >= 0)
    arrSyntax = (sid.indexOf("(") >= 0)
    if dotSyntax
      parts = sid.split(".")
      @sid = parts.shift()
      @member = parts.shift()
    else if arrSyntax
      arrIndices = sid.split("(")
      @sid = arrIndices.shift()
      j = 0

      while j < arrIndices.length
        arrIndices[j] = parseInt(arrIndices[j].replace(/\)/, ""))
        j++
      @arrIndices = arrIndices
    else
      @sid = sid
    @fullSid = sid
    @dotSyntax = dotSyntax
    @arrSyntax = arrSyntax
    this

  Sampler::parse = (element) ->
    @id = element.getAttribute("id")
    @inputs = []
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "input"
          @inputs.push (new Input()).parse(child)
        else
      i++
    this

  Sampler::create = ->
    i = 0

    while i < @inputs.length
      input = @inputs[i]
      source = @animation.source[input.source]
      switch input.semantic
        when "INPUT"
          @input = source.read()
        when "OUTPUT"
          @output = source.read()
          @strideOut = source.accessor.stride
        when "INTERPOLATION"
          @interpolation = source.read()
        when "IN_TANGENT", "OUT_TANGENT"
        else
          console.log input.semantic
      i++
    @startTime = 0
    @endTime = 0
    @duration = 0
    if @input.length
      @startTime = 100000000
      @endTime = -100000000
      i = 0

      while i < @input.length
        @startTime = Math.min(@startTime, @input[i])
        @endTime = Math.max(@endTime, @input[i])
        i++
      @duration = @endTime - @startTime

  Sampler::getData = (type, ndx) ->
    data = undefined
    if type is "matrix" and @strideOut is 16
      data = @output[ndx]
    else if @strideOut > 1
      data = []
      ndx *= @strideOut
      i = 0

      while i < @strideOut
        data[i] = @output[ndx + i]
        ++i
      if @strideOut is 3
        switch type
          when "rotate", "translate"
            fixCoords data, -1
          when "scale"
            fixCoords data, 1
      else fixCoords data, -1  if @strideOut is 4 and type is "matrix"
    else
      data = @output[ndx]
    data

  Key::addTarget = (fullSid, transform, member, data) ->
    @targets.push
      sid: fullSid
      member: member
      transform: transform
      data: data

  Key::apply = (opt_sid) ->
    i = 0

    while i < @targets.length
      target = @targets[i]
      target.transform.update target.data, target.member  if not opt_sid or target.sid is opt_sid
      ++i

  Key::getTarget = (fullSid) ->
    i = 0

    while i < @targets.length
      return @targets[i]  if @targets[i].sid is fullSid
      ++i
    null

  Key::hasTarget = (fullSid) ->
    i = 0

    while i < @targets.length
      return true  if @targets[i].sid is fullSid
      ++i
    false

  # TODO: Currently only doing linear interpolation. Should support full COLLADA spec
  Key::interpolate = (nextKey, time) ->
    i = 0

    while i < @targets.length
      target = @targets[i]
      nextTarget = nextKey.getTarget(target.sid)
      data = undefined
      if target.transform.type isnt "matrix" and nextTarget
        scale = (time - @time) / (nextKey.time - @time)
        nextData = nextTarget.data
        prevData = target.data
        
        # check scale error
        if scale < 0 or scale > 1
          console.log "Key.interpolate: Warning! Scale out of bounds:" + scale
          scale = (if scale < 0 then 0 else 1)
        if prevData.length
          data = []
          j = 0

          while j < prevData.length
            data[j] = prevData[j] + (nextData[j] - prevData[j]) * scale
            ++j
        else
          data = prevData + (nextData - prevData) * scale
      else
        data = target.data
      target.transform.update data, target.member
      ++i

  Camera::parse = (element) ->
    @id = element.getAttribute("id")
    @name = element.getAttribute("name")
    i = 0

    while i < element.childNodes.length
      child = element.childNodes[i]
      continue  unless child.nodeType is 1
      switch child.nodeName
        when "optics"
          @parseOptics child
        else
      i++
    this

  Camera::parseOptics = (element) ->
    i = 0

    while i < element.childNodes.length
      if element.childNodes[i].nodeName is "technique_common"
        technique = element.childNodes[i]
        j = 0

        while j < technique.childNodes.length
          @technique = technique.childNodes[j].nodeName
          if @technique is "perspective"
            perspective = technique.childNodes[j]
            k = 0

            while k < perspective.childNodes.length
              param = perspective.childNodes[k]
              switch param.nodeName
                when "yfov"
                  @yfov = param.textContent
                when "xfov"
                  @xfov = param.textContent
                when "znear"
                  @znear = param.textContent
                when "zfar"
                  @zfar = param.textContent
                when "aspect_ratio"
                  @aspect_ratio = param.textContent
              k++
          else if @technique is "orthographic"
            orthographic = technique.childNodes[j]
            k = 0

            while k < orthographic.childNodes.length
              param = orthographic.childNodes[k]
              switch param.nodeName
                when "xmag"
                  @xmag = param.textContent
                when "ymag"
                  @ymag = param.textContent
                when "znear"
                  @znear = param.textContent
                when "zfar"
                  @zfar = param.textContent
                when "aspect_ratio"
                  @aspect_ratio = param.textContent
              k++
          j++
      i++
    this

  InstanceCamera::parse = (element) ->
    @url = element.getAttribute("url").replace(/^#/, "")
    this

  load: load
  parse: parse
  setPreferredShading: setPreferredShading
  applySkin: applySkin
  geometries: geometries
  options: options

								

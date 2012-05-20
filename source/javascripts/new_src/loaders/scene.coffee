# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/loader
#= require new_src/loaders/binary
#= require new_src/loaders/json
#= require new_src/core/color
#= require new_src/core/geometry
#= require new_src/core/vector_3
#= require new_src/core/object_3d
#= require new_src/cameras/orthographic
#= require new_src/cameras/perspective
#= require new_src/lights/ambient
#= require new_src/lights/directional
#= require new_src/lights/point

class SceneLoader extends THREE.Loader
  constructor: ->
    @onLoadStart = ->
    @onLoadProgress = ->
    @onLoadComplete = ->
    @callbackSync = ->
    @callbackProgress = ->

  load: (url, callbackFinished) ->
    context = this
    xhr = new XMLHttpRequest()
    xhr.onreadystatechange = ->
      if xhr.readyState is 4
        if xhr.status is 200 or xhr.status is 0
          json = JSON.parse(xhr.responseText)
          context.createScene json, callbackFinished, url
        else
          console.error "THREE.SceneLoader: Couldn't load [" + url + "] [" + xhr.status + "]"
  
    xhr.open "GET", url, true
    xhr.overrideMimeType "text/plain; charset=x-user-defined"  if xhr.overrideMimeType
    xhr.setRequestHeader "Content-Type", "text/plain"
    xhr.send null

  createScene: (json, callbackFinished, url) ->
    scene = new SceneModel json, url, this, callbackFinished
    
class SceneModel extends THREE.Geometry
  constructor: (json, url, sceneLoader, callbackFinished) ->
    @data             = json
    @sceneLoader      = sceneLoader
    @urlBase          = @sceneLoader.extractUrlBase url
    @callbackFinished = callbackFinished
    
    @binaryLoader = new THREE.BinaryLoader()
    @jsonLoader   = new THREE.JSONLoader()
    
    @counter_models   = 0
    @counter_textures = 0
    
    @result =
      scene:      new THREE.Scene()
      geometries: {}
      materials:  {}
      textures:   {}
      objects:    {}
      cameras:    {}
      lights:     {}
      fogs:       {}
      empties:    {}
  
    if @data.transform
      position  = @data.transform.position
      rotation  = @data.transform.rotation
      scale     = @data.transform.scale
      
      if position
        @result.scene.position.set position[0],  position[1],  position[2]
      if rotation
        @result.scene.rotation.set rotation[0],  rotation[1],  rotation[2]
      if scale
        @result.scene.scale.set    scale[0],     scale[1],     scale[2]
      
      if position or rotation or scale
        @result.scene.updateMatrix()
        @result.scene.updateMatrixWorld()
  
    # first go synchronous elements
    # cameras
    for dc of @data.cameras
      c = @data.cameras[dc]
      if c.type is "perspective"
        camera = new THREE.PerspectiveCamera c.fov, c.aspect, c.near, c.far
      else if c.type is "ortho"
        camera = new THREE.OrthographicCamera c.left, c.right, c.top, c.bottom, c.near, c.far

      p = c.position
      t = c.target
      u = c.up

      camera.position.set p[0], p[1], p[2]
      camera.target = new THREE.Vector3 t[0], t[1], t[2]
      camera.up.set u[0], u[1], u[2] if u
      @result.cameras[dc] = camera
    
    # lights
    for dl of @data.lights
      current_light = @data.lights[dl]
      
      if current_light.color isnt undefined
        hex = current_light.color
      else
        hex = 0xffffff

      if current_light.intensity isnt undefined
        intensity = current_light.intensity
      else 
        intensity = 1 
      
      if current_light.type is "directional"
        p = current_light.direction
        light = new THREE.DirectionalLight hex, intensity
        light.position.set p[0], p[1], p[2]
        light.position.normalize()
      else if current_light.type is "point"
        p = current_light.position
        d = current_light.distance
        light = new THREE.PointLight hex, intensity, d
        light.position.set p[0], p[1], p[2]
      else if current_light.type is "ambient"
        light = new THREE.AmbientLight hex

      @result.scene.add light
      @result.lights[dl] = light
      
    # fogs
    for df of @data.fogs
      current_fog = @data.fogs[df]
      if current_fog.type is "linear"
        fog = new THREE.Fog 0x000000, current_fog.near, current_fog.far
      else if current_fog.type is "exp2"
        fog = new THREE.FogExp2 0x000000, current_fog.density

      c = current_fog.color
      fog.color.setRGB c[0], c[1], c[2]
      @result.fogs[df] = fog
      
    # defaults
    if @result.cameras and @data.defaults.camera
      @result.currentCamera = @result.cameras[@data.defaults.camera]
    if @result.fogs and @data.defaults.fog
      @result.scene.fog = @result.fogs[@data.defaults.fog]

    c = @data.defaults.bgcolor
    @result.bgColor = new THREE.Color()
    @result.bgColor.setRGB c[0], c[1], c[2]
    @result.bgColorAlpha = @data.defaults.bgalpha
    
    for dg of @data.geometries
      g = @data.geometries[dg]
      if g.type is "bin_mesh" or g.type is "ascii_mesh"
        @counter_models += 1
        @sceneLoader.onLoadStart()
    @total_models = @counter_models
    
    # now come potentially asynchronous elements
    # geometries
    # count how many models will be loaded asynchronously
    for dg of @data.geometries
      g = @data.geometries[dg]
      
      if g.type is "cube"
        geometry = new THREE.CubeGeometry g.width, g.height, g.depth, g.segmentsWidth, g.segmentsHeight, g.segmentsDepth, null, g.flipped, g.sides
        @result.geometries[dg] = geometry
      else if g.type is "plane"
        geometry = new THREE.PlaneGeometry g.width, g.height, g.segmentsWidth, g.segmentsHeight
        @result.geometries[dg] = geometry
      else if g.type is "sphere"
        geometry = new THREE.SphereGeometry g.radius, g.segmentsWidth, g.segmentsHeight
        @result.geometries[dg] = geometry
      else if g.type is "cylinder"
        geometry = new THREE.CylinderGeometry g.topRad, g.botRad, g.height, g.radSegs, g.heightSegs
        @result.geometries[dg] = geometry
      else if g.type is "torus"
        geometry = new THREE.TorusGeometry g.radius, g.tube, g.segmentsR, g.segmentsT
        @result.geometries[dg] = geometry
      else if g.type is "icosahedron"
        geometry = new THREE.IcosahedronGeometry g.radius, g.subdivisions
        @result.geometries[dg] = geometry
      else if g.type is "bin_mesh"
        @binaryLoader.load  @get_url(g.url, @data.urlBaseType), @create_callback(dg)
      else if g.type is "ascii_mesh"
        @jsonLoader.load    @get_url(g.url, @data.urlBaseType), @create_callback(dg)
      else if g.type is "embedded_mesh"
        modelJson     = @data.embeds[g.id]
        texture_path  = ""
        
        # Pass metadata along to jsonLoader so it knows the format version
        modelJson.metadata = @data.metadata
        @jsonLoader.createModel modelJson, @create_callback_embed(dg), texture_path if modelJson
        
    # textures
    # count how many textures will be loaded asynchronously
    for dt of @data.textures
      tt = @data.textures[dt]
      if tt.url instanceof Array
        tt_length = tt.url.length
        @counter_textures += tt_length
        for n in [0...tt_length]
          @sceneLoader.onLoadStart()
      else
        @counter_textures += 1
        @sceneLoader.onLoadStart()

    @total_textures = @counter_textures
    for dt of @data.textures
      tt = @data.textures[dt]
      if tt.mapping isnt undefined and THREE[tt.mapping] isnt undefined
        tt.mapping = new THREE[tt.mapping]()

      if tt.url instanceof Array
        url_array = []
        tt_length = tt.url.length
        for i in [0...tt_length]
          url_array[i] = @get_url tt.url[i], @data.urlBaseType
        texture = THREE.ImageUtils.loadTextureCube url_array, tt.mapping, @callbackTexture()
      else
        texture = THREE.ImageUtils.loadTexture @get_url(tt.url, @data.urlBaseType), tt.mapping, @callbackTexture()
        unless THREE[tt.minFilter] is undefined
          texture.minFilter = THREE[tt.minFilter]
        unless THREE[tt.magFilter] is undefined
          texture.magFilter = THREE[tt.magFilter]
        if tt.repeat
          texture.repeat.set tt.repeat[0], tt.repeat[1]
          unless tt.repeat[0] is 1
            texture.wrapS = THREE.RepeatWrapping
          unless tt.repeat[1] is 1
            texture.wrapT = THREE.RepeatWrapping

        texture.offset.set tt.offset[0], tt.offset[1] if tt.offset
        if tt.wrap
          wrapMap =
            repeat: THREE.RepeatWrapping
            mirror: THREE.MirroredRepeatWrapping
          if wrapMap[tt.wrap[0]] isnt undefined
            texture.wrapS = wrapMap[tt.wrap[0]]
          if wrapMap[tt.wrap[1]] isnt undefined
            texture.wrapT = wrapMap[tt.wrap[1]]

      @result.textures[dt] = texture
      
    # materials
    for dm of @data.materials
      m = @data.materials[dm]
      for pp of m.parameters
        if pp is "envMap" or pp is "map" or pp is "lightMap"
          m.parameters[pp] = @result.textures[m.parameters[pp]]
        else if pp is "shading"
          if m.parameters[pp] is "flat"
            m.parameters[pp] = THREE.FlatShading
          else
            m.parameters[pp] = THREE.SmoothShading
        else if pp is "blending"
          if THREE[m.parameters[pp]]
            m.parameters[pp] = THREE[m.parameters[pp]]
          else
            m.parameters[pp] = THREE.NormalBlending
        else if pp is "combine"
          if m.parameters[pp] is "MixOperation"
            m.parameters[pp] = THREE.MixOperation
          else
            m.parameters[pp] = THREE.MultiplyOperation
        else if pp is "vertexColors"
          if m.parameters[pp] is "face"
            m.parameters[pp] = THREE.FaceColors
          else if m.parameters[pp]
            m.parameters[pp] = THREE.VertexColors

      if m.parameters.opacity isnt undefined and m.parameters.opacity < 1.0
        m.parameters.transparent = true
      if m.parameters.normalMap
        shader    = THREE.ShaderUtils.lib["normal"]
        uniforms  = THREE.UniformsUtils.clone shader.uniforms
        diffuse   = m.parameters.color
        specular  = m.parameters.specular
        ambient   = m.parameters.ambient
        shininess = m.parameters.shininess
        
        uniforms["tNormal"].texture     = @result.textures[m.parameters.normalMap]
        uniforms["uNormalScale"].value  = m.parameters.normalMapFactor if m.parameters.normalMapFactor
        if m.parameters.map
          uniforms["tDiffuse"].texture    = m.parameters.map
          uniforms["enableDiffuse"].value = true
        if m.parameters.lightMap
          uniforms["tAO"].texture     = m.parameters.lightMap
          uniforms["enableAO"].value  = true
        if m.parameters.specularMap
          uniforms["tSpecular"].texture     = @result.textures[m.parameters.specularMap]
          uniforms["enableSpecular"].value  = true

        uniforms["uDiffuseColor"].value.setHex  diffuse
        uniforms["uSpecularColor"].value.setHex specular
        uniforms["uAmbientColor"].value.setHex  ambient
        uniforms["uShininess"].value  = shininess
        uniforms["uOpacity"].value    = m.parameters.opacity  if m.parameters.opacity
        parameters =
          fragmentShader: shader.fragmentShader
          vertexShader:   shader.vertexShader
          uniforms:       uniforms
          lights:         true
          fog:            true
  
        material = new THREE.ShaderMaterial parameters
      else
        material = new THREE[m.type](m.parameters)

      @result.materials[dm] = material
    
    # objects synchronous init of procedural primitives
    @handle_objects()
    
    # synchronous callback
    @sceneLoader.callbackSync @result
    
    # just in case there are no async elements
    @async_callback_gate()
    
    @sceneLoader.callbackProgress progress, @result
    @sceneLoader.onLoadProgress()
  
  get_url: (source_url, url_type) ->
    if url_type is "relativeToHTML"
      source_url
    else
      @urlBase + "/" + source_url

  handle_objects: ->
    for dd of @data.objects
      unless @result.objects[dd]
        o = @data.objects[dd]
        if o.geometry isnt undefined
          geometry = @result.geometries[o.geometry]
          
          # geometry already loaded
          if geometry
            hasNormals = false
            
            # not anymore support for multiple materials
            # shouldn't really be array
            material    = @result.materials[o.materials[0]]
            hasNormals  = material instanceof THREE.ShaderMaterial
            geometry.computeTangents() if hasNormals
            p = o.position
            r = o.rotation
            q = o.quaternion
            s = o.scale
            m = o.matrix
            
            # turn off quaternions, for the moment
            q = 0
            material = new THREE.MeshFaceMaterial() if o.materials.length is 0
            
            # dirty hack to handle meshes with multiple materials
            # just use face materials defined in model
            material    = new THREE.MeshFaceMaterial() if o.materials.length > 1
            object      = new THREE.Mesh(geometry, material)
            object.name = dd
            
            if m
              object.matrixAutoUpdate = false
              object.matrix.set m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8], m[9], m[10], m[11], m[12], m[13], m[14], m[15]
            else
              object.position.set p[0], p[1], p[2]
              if q
                object.quaternion.set q[0], q[1], q[2], q[3]
                object.useQuaternion = true
              else
                object.rotation.set r[0], r[1], r[2]
              object.scale.set s[0], s[1], s[2]

            object.visible        = o.visible
            object.doubleSided    = o.doubleSided
            object.castShadow     = o.castShadow
            object.receiveShadow  = o.receiveShadow
            
            @result.scene.add object
            @result.objects[dd] = object
        else
          # pure Object3D
          p = o.position
          r = o.rotation
          q = o.quaternion
          s = o.scale
          
          # turn off quaternions, for the moment
          q = 0
          object      = new THREE.Object3D()
          object.name = dd
          object.position.set p[0], p[1], p[2]
          if q
            object.quaternion.set q[0], q[1], q[2], q[3]
            object.useQuaternion = true
          else
            object.rotation.set r[0], r[1], r[2]

          object.scale.set s[0], s[1], s[2]
          if o.visible isnt undefined
            object.visible = o.visible
          else
            object.visible = false
          
          @result.scene.add object
          @result.objects[dd] = object
          @result.empties[dd] = object
          
  callbackTexture: ->
    (images) =>
      @counter_textures -= 1
      @async_callback_gate()
      @sceneLoader.onLoadComplete()
    
  async_callback_gate: ->
    progress =
      totalModels:    @total_models
      totalTextures:  @total_textures
      loadedModels:   @total_models    - @counter_models
      loadedTextures: @total_textures  - @counter_textures
      
    if @counter_models is 0 and @counter_textures is 0
      @callbackFinished @result
  
  handle_mesh: (geo, id) ->
    @result.geometries[id] = geo
    @handle_objects()

  create_callback: (id) ->
    (geo) =>
      @handle_mesh geo, id
      @counter_models -= 1
      @sceneLoader.onLoadComplete()
      @async_callback_gate()

  create_callback_embed: (id) ->
    (geo) =>
      @result.geometries[id] = geo

namespace "THREE", (exports) ->
  exports.SceneLoader = SceneLoader
  exports.SceneModel  = SceneModel
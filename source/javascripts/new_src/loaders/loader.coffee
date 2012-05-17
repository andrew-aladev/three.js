# @author alteredq / http://alteredqualia.com/
# @author aladjev.andrew@gmail.com

class Loader
  constructor: (showStatus) ->
    @showStatus = showStatus
    @statusDomElement = (if showStatus then @addStatusElement() else null)
    @onLoadStart    = ->
    @onLoadProgress = ->
    @onLoadComplete = ->
    @crossOrigin = "anonymous"
    
  @addStatusElement: ->
    e = document.createElement "div"
    e.style.position = "absolute"
    e.style.right = "0px"
    e.style.top = "0px"
    e.style.fontSize = "0.8em"
    e.style.textAlign = "left"
    e.style.background = "rgba(0,0,0,0.25)"
    e.style.color = "#fff"
    e.style.width = "120px"
    e.style.padding = "0.5em 0.5em 0.5em 0.5em"
    e.style.zIndex = 1000
    e.innerHTML = "Loading ..."
    e

  updateProgress: (progress) ->
    message = "Loaded "
    if progress.total
      message += (100 * progress.loaded / progress.total).toFixed(0) + "%"
    else
      message += (progress.loaded / 1000).toFixed(2) + " KB"
    @statusDomElement.innerHTML = message

  extractUrlBase: (url) ->
    parts = url.split "/"
    parts.pop()
    (if parts.length < 1 then "." else parts.join("/")) + "/"

  initMaterials: (scope, materials, texturePath) ->
    scope.materials = []
    i = 0

    while i < materials.length
      scope.materials[i] = @createMaterial(materials[i], texturePath)
      ++i

  hasNormals: (scope) ->
    m = undefined
    i = undefined
    il = scope.materials.length
    i = 0
    while i < il
      m = scope.materials[i]
      return true  if m instanceof THREE.ShaderMaterial
      i++
    false

  createMaterial: (m, texturePath) ->
    is_pow2 = (n) ->
      l = Math.log(n) / Math.LN2
      Math.floor(l) is l
    nearest_pow2 = (n) ->
      l = Math.log(n) / Math.LN2
      Math.pow 2, Math.round(l)
    load_image = (where, url) ->
      image = new Image()
      image.onload = ->
        if not is_pow2(@width) or not is_pow2(@height)
          width = nearest_pow2(@width)
          height = nearest_pow2(@height)
          where.image.width = width
          where.image.height = height
          where.image.getContext("2d").drawImage this, 0, 0, width, height
        else
          where.image = this
        where.needsUpdate = true

      image.crossOrigin = _this.crossOrigin
      image.src = url
    create_texture = (where, name, sourceFile, repeat, offset, wrap) ->
      texture = document.createElement("canvas")
      where[name] = new THREE.Texture(texture)
      where[name].sourceFile = sourceFile
      if repeat
        where[name].repeat.set repeat[0], repeat[1]
        where[name].wrapS = THREE.RepeatWrapping  unless repeat[0] is 1
        where[name].wrapT = THREE.RepeatWrapping  unless repeat[1] is 1
      where[name].offset.set offset[0], offset[1]  if offset
      if wrap
        wrapMap =
          repeat: THREE.RepeatWrapping
          mirror: THREE.MirroredRepeatWrapping

        where[name].wrapS = wrapMap[wrap[0]]  if wrapMap[wrap[0]] isnt undefined
        where[name].wrapT = wrapMap[wrap[1]]  if wrapMap[wrap[1]] isnt undefined
      load_image where[name], texturePath + "/" + sourceFile
    rgb2hex = (rgb) ->
      (rgb[0] * 255 << 16) + (rgb[1] * 255 << 8) + rgb[2] * 255
    _this = this
    
    # defaults
    mtype = "MeshLambertMaterial"
    mpars =
      color: 0xeeeeee
      opacity: 1.0
      map: null
      lightMap: null
      normalMap: null
      wireframe: m.wireframe

    # parameters from model file
    if m.shading
      shading = m.shading.toLowerCase()
      if shading is "phong"
        mtype = "MeshPhongMaterial"
      else mtype = "MeshBasicMaterial"  if shading is "basic"
    mpars.blending = THREE[m.blending]  if m.blending isnt undefined and THREE[m.blending] isnt undefined
    mpars.transparent = m.transparent  if m.transparent isnt undefined or m.opacity < 1.0
    mpars.depthTest = m.depthTest  if m.depthTest isnt undefined
    mpars.depthWrite = m.depthWrite  if m.depthWrite isnt undefined
    if m.vertexColors isnt undefined
      if m.vertexColors is "face"
        mpars.vertexColors = THREE.FaceColors
      else mpars.vertexColors = THREE.VertexColors  if m.vertexColors
      
    # colors
    if m.colorDiffuse
      mpars.color = rgb2hex(m.colorDiffuse)
    else mpars.color = m.DbgColor  if m.DbgColor
    mpars.specular = rgb2hex(m.colorSpecular)  if m.colorSpecular
    mpars.ambient = rgb2hex(m.colorAmbient)  if m.colorAmbient
    
    # modifiers
    mpars.opacity = m.transparency  if m.transparency
    mpars.shininess = m.specularCoef  if m.specularCoef
    
    # textures
    create_texture mpars, "map", m.mapDiffuse, m.mapDiffuseRepeat, m.mapDiffuseOffset, m.mapDiffuseWrap  if m.mapDiffuse and texturePath
    create_texture mpars, "lightMap", m.mapLight, m.mapLightRepeat, m.mapLightOffset, m.mapLightWrap  if m.mapLight and texturePath
    create_texture mpars, "normalMap", m.mapNormal, m.mapNormalRepeat, m.mapNormalOffset, m.mapNormalWrap  if m.mapNormal and texturePath
    create_texture mpars, "specularMap", m.mapSpecular, m.mapSpecularRepeat, m.mapSpecularOffset, m.mapSpecularWrap  if m.mapSpecular and texturePath
    
    # special case for normal mapped material
    if m.mapNormal
      shader = THREE.ShaderUtils.lib["normal"]
      uniforms = THREE.UniformsUtils.clone(shader.uniforms)
      uniforms["tNormal"].texture = mpars.normalMap
      uniforms["uNormalScale"].value = m.mapNormalFactor  if m.mapNormalFactor
      if mpars.map
        uniforms["tDiffuse"].texture = mpars.map
        uniforms["enableDiffuse"].value = true
      if mpars.specularMap
        uniforms["tSpecular"].texture = mpars.specularMap
        uniforms["enableSpecular"].value = true
      if mpars.lightMap
        uniforms["tAO"].texture = mpars.lightMap
        uniforms["enableAO"].value = true
        
      # for the moment don't handle displacement texture
      uniforms["uDiffuseColor"].value.setHex mpars.color
      uniforms["uSpecularColor"].value.setHex mpars.specular
      uniforms["uAmbientColor"].value.setHex mpars.ambient
      uniforms["uShininess"].value = mpars.shininess
      uniforms["uOpacity"].value = mpars.opacity  if mpars.opacity isnt undefined
      parameters =
        fragmentShader: shader.fragmentShader
        vertexShader: shader.vertexShader
        uniforms: uniforms
        lights: true
        fog: true

      material = new THREE.ShaderMaterial(parameters)
    else
      material = new THREE[mtype](mpars)
    material.name = m.DbgName  if m.DbgName isnt undefined
    material
    
namespace "THREE", (exports) ->
  exports.Loader = Loader
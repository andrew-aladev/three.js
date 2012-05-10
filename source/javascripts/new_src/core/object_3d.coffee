# @author mr.doob / http://mrdoob.com/
# @author mikael emtinger / http://gomo.se/
# @author alteredq / http://alteredqualia.com/
# @autor aladjev.andrew@gmail.com

class window.Three::Object3D
  constructor: ->
    @id           = Three::object_3d_count++
    @name         = ""
    @parent       = undefined
    @children     = []
    @up           = new Three::Vector3 0, 1, 0
    @position     = new Three::Vector3()
    @rotation     = new Three::Vector3()
    @euler_order  = "XYZ"
    @scale        = new Three::Vector3 1, 1, 1
    @double_sided = false
    @flip_sided   = false
    @render_depth = null
    
    @rotation_auto_update       = true
    @matrix                     = new Three::Matrix4()
    @matrix_world               = new Three::Matrix4()
    @matrix_rotation_world      = new Three::Matrix4()
    @matrix_auto_update         = true
    @matrix_world_needs_update  = true
    @quaternion                 = new Three::Quaternion()
    @use_quaternion             = false
    
    @bound_radius               = 0.0
    @bound_radius_scale         = 1.0
    @visible                    = true
    @cast_shadow                = false
    @receive_shadow             = false
    @frustum_culled             = true
    @_vector                    = new Three::Vector3()

  apply_matrix: (matrix) ->
    @matrix.multiply matrix, @matrix
    @scale.get_scale_from_matrix @matrix
    @rotation.get_rotation_from_matrix @matrix, @scale
    @position.get_position_from_matrix @matrix

  translate: (distance, axis) ->
    @matrix.rotate_axis axis
    @position.add_self axis.multiply_scalar(distance)

  translate_x: (distance) ->
    @translate distance, @_vector.set(1, 0, 0)

  translate_y: (distance) ->
    @translate distance, @_vector.set(0, 1, 0)

  translate_z: (distance) ->
    @translate distance, @_vector.set(0, 0, 1)

  look_at: (vector) ->
    # TODO: Add hierarchy support
    @matrix.look_at vector, @position, @up
    @rotation.get_rotation_from_matrix @matrix  if @rotation_auto_update

  add: (object) ->
    if object is this
      console.warn "Three::Object3D.add: An object can't be added as a child of itself."
      return
    if object instanceof Three::Object3D
      object.parent.remove object if object.parent isnt undefined
      object.parent = this
      @children.push object
      
      # add to scene
      scene = this
      scene = scene.parent  while scene.parent isnt undefined
      scene.__add_object object  if scene isnt undefined and scene instanceof Three::Scene

  remove: (object) ->
    index = @children.indexOf object
    if index isnt -1
      object.parent = undefined
      @children.splice index, 1
      
      # remove from scene
      scene = this
      scene = scene.parent  while scene.parent isnt undefined
      scene.__remove_object object  if scene isnt undefined and scene instanceof Three::Scene

  get_child_by_name: (name, recursive) ->
    cl    = undefined
    child = undefined
    c     = 0
    cl    = @children.length

    while c < cl
      child = @children[c]
      return child if child.name is name
      if recursive
        child = child.get_child_by_name name, recursive
        return child if child isnt undefined
      c++
    undefined

  update_matrix: ->
    @matrix.set_position @position
    if @use_quaternion
      @matrix.set_rotation_from_quaternion @quaternion
    else
      @matrix.set_rotation_from_euler @rotation, @euler_order
    if @scale.x isnt 1 or @scale.y isnt 1 or @scale.z isnt 1
      @matrix.scale @scale
      @bound_radius_scale = Math.max @scale.x, Math.max(@scale.y, @scale.z)
    @matrix_world_needs_update = true

  update_matrix_world: (force) ->
    @matrix_auto_update and @update_matrix()
    
    # update matrixWorld
    if @matrix_world_needs_update or force
      if @parent
        @matrix_world.multiply @parent.matrix_world, @matrix
      else
        @matrix_world.copy @matrix
      @matrix_world_needs_update = false
      force = true
    
    # update children
    length = @children.length
    for i in [0...length]
      @children[i].update_matrix_world force

Three::object_3d_count = 0
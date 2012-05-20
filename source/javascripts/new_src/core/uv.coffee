# @author mr.doob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

class UV
  constructor: (u, v) ->
    @u = u or 0
    @v = v or 0

  set: (u, v) ->
    @u = u
    @v = v
    this

  copy: (uv) ->
    @u = uv.u
    @v = uv.v
    this

  lerpSelf: (uv, alpha) ->
    @u += (uv.u - @u) * alpha
    @v += (uv.v - @v) * alpha
    this

  clone: ->
    new UV @u, @v
    
namespace "THREE", (exports) ->
  exports.UV = UV
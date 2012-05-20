# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class Key
  constructor: (time) ->
    @targets  = []
    @time     = time

  addTarget: (fullSid, transform, member, data) ->
    @targets.push
      sid:        fullSid
      member:     member
      transform:  transform
      data:       data

  apply: (opt_sid) ->
    length = @targets.length
    for i in [0...length]
      target = @targets[i]
      if not opt_sid or target.sid is opt_sid
        target.transform.update target.data, target.member

  getTarget: (fullSid) ->
    length = @targets.length
    for i in [0...length]
      if @targets[i].sid is fullSid
        return @targets[i]
    null

  hasTarget: (fullSid) ->
    length = @targets.length
    for i in [0...length]
      if @targets[i].sid is fullSid
        return true
    false

  # TODO: Currently only doing linear interpolation. Should support full COLLADA spec
  interpolate: (nextKey, time) ->
    length = @targets.length
    for i in [0...length]
      target      = @targets[i]
      nextTarget  = nextKey.getTarget target.sid
      
      if target.transform.type isnt "matrix" and nextTarget
        scale     = (time - @time) / (nextKey.time - @time)
        nextData  = nextTarget.data
        prevData  = target.data
        
        # check scale error
        if scale < 0 or scale > 1
          console.warn "Key.interpolate: Warning! Scale out of bounds:", scale
          if scale < 0
            scale = 0
          else
            scale = 1

        if prevData.length
          data = []
          prev_length = prevData.length
          for j in [0...prev_length]
            data[j] = prevData[j] + (nextData[j] - prevData[j]) * scale
        else
          data = prevData + (nextData - prevData) * scale
      else
        data = target.data
      target.transform.update data, target.member

namespace "THREE.Collada", (exports) ->
  exports.Key = Key
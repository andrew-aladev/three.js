# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/core/vector_3

class Transform
  constructor: (loader) ->
    @sid    = ""
    @type   = ""
    @data   = []
    @obj    = null
    @loader = loader
    
  parse: (element) ->
    @sid  = element.getAttribute "sid"
    @type = element.nodeName
    @data = THREE.ColladaLoader._floats element.textContent
    @convert()
    this

  convert: ->
    switch @type
      when "matrix"
        @obj = @loader.getConvertedMat4 @data
      when "rotate"
        @angle = @data[3] * TO_RADIANS
      when "translate"
        fixCoords @data, -1
        @obj = new THREE.Vector3 @data[0], @data[1], @data[2]
      when "scale"
        fixCoords @data, 1
        @obj = new THREE.Vector3 @data[0], @data[1], @data[2]
      else
        console.warn "Can not convert Transform of type ", @type

  apply: (matrix) ->
    switch @type
      when "matrix"
        matrix.multiplySelf @obj
      when "translate"
        matrix.translate    @obj
      when "rotate"
        matrix.rotateByAxis @obj, @angle
      when "scale"
        matrix.scale @obj

  update: (data, member) ->
    members = ["X", "Y", "Z", "ANGLE"]

    switch @type
      when "matrix"
        unless member
          @obj.copy data

        else if member.length is 1
          switch member[0]
            when 0
              @obj.n11 = data[0]
              @obj.n21 = data[1]
              @obj.n31 = data[2]
              @obj.n41 = data[3]
            when 1
              @obj.n12 = data[0]
              @obj.n22 = data[1]
              @obj.n32 = data[2]
              @obj.n42 = data[3]
            when 2
              @obj.n13 = data[0]
              @obj.n23 = data[1]
              @obj.n33 = data[2]
              @obj.n43 = data[3]
            when 3
              @obj.n14 = data[0]
              @obj.n24 = data[1]
              @obj.n34 = data[2]
              @obj.n44 = data[3]

        else if member.length is 2
          propName = "n" + (member[0] + 1) + (member[1] + 1)
          @obj[propName] = data

        else
          console.warn "Incorrect addressing of matrix in transform."

      when "translate", "scale"
        if Object::toString.call(member) is "[object Array]"
          member = members[member[0]]

        switch member
          when "X"
            @obj.x = data
          when "Y"
            @obj.y = data
          when "Z"
            @obj.z = data
          else
            @obj.x = data[0]
            @obj.y = data[1]
            @obj.z = data[2]

      when "rotate"
        if Object::toString.call(member) is "[object Array]"
          member = members[member[0]]

        switch member
          when "X"
            @obj.x = data
          when "Y"
            @obj.y = data
          when "Z"
            @obj.z = data
          when "ANGLE"
            @angle = data * TO_RADIANS
          else
            @obj.x = data[0]
            @obj.y = data[1]
            @obj.z = data[2]
            @angle = data[3] * TO_RADIANS

namespace "THREE.Collada", (exports) ->
  exports.Transform = Transform
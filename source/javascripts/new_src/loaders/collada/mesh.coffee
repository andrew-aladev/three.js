# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/collada/vertices
#= require new_src/loaders/collada/triangles
#= require new_src/loaders/collada/polygons
#= require new_src/loaders/collada/polylist
#= require new_src/core/geometry
#= require new_src/core/uv
#= require new_src/core/color
#= require new_src/core/face_3
#= require new_src/core/face_4

class Mesh
  constructor: (loader, geometry) ->
    @geometry     = geometry.id
    @primitives   = []
    @vertices     = null
    @geometry3js  = null
    @loader       = loader
    
  parse: (element) ->
    @primitives = []
    length = element.childNodes.length
    for i in [0...length]
      child = element.childNodes[i]
      switch child.nodeName
        when "source"
          @loader._source child
        when "vertices"
          @vertices = new THREE.Collada.Verticles().parse child
        when "triangles"
          @primitives.push new THREE.Collada.Triangles().parse(child)
        when "polygons"
          @primitives.push new THREE.Collada.Polygons().parse(child)
        when "polylist"
          @primitives.push new THREE.Collada.Polylist().parse(child)

    @geometry3js  = new THREE.Geometry()
    vertexData    = @loader.sources[@vertices.input["POSITION"].source].data

    length = vertexData.length
    for i in [0...length] by 3
      @geometry3js.vertices.push @loader.getConvertedVec3(vertexData, i).clone()

    length = @primitives.length
    for i in [0...length]
      primitive = @primitives[i]
      primitive.setVertices @vertices
      @handlePrimitive primitive, @geometry3js

    @geometry3js.computeCentroids()
    @geometry3js.computeFaceNormals()
    if @geometry3js.calcNormals
      @geometry3js.computeVertexNormals()
      delete @geometry3js.calcNormals
    @geometry3js.computeBoundingBox()
    this

  handlePrimitive: (primitive, geom) ->
    pList         = primitive.p
    inputs        = primitive.inputs
    vcIndex       = 0
    vcount        = 3
    maxOffset     = 0
    texture_sets  = []

    length = inputs.length
    for j in [0...length]
      input   = inputs[j]
      offset  = input.offset + 1
      if maxOffset < offset
        maxOffset = offset
      switch input.semantic
        when "TEXCOORD"
          texture_sets.push input.set

    length = pList.length
    for pCount in [0...length]
      p = pList[pCount]

      p_length = p.length
      i = 0
      while i < p_length
        vs = []
        ns = []
        ts = null
        cs = []

        if primitive.vcount
          if primitive.vcount.length
            vcount = primitive.vcount[vcIndex++]
          else
            vcount = primitive.vcount
        else
          vcount = p_length / maxOffset

        for j in [0...vcount]

          inputs_length = inputs.length
          for k in [0...inputs_length]
            input     = inputs[k]
            source    = @loader.sources[input.source]
            index     = p[i + j * maxOffset + input.offset]
            numParams = source.accessor.params.length
            idx32     = index * numParams

            switch input.semantic
              when "VERTEX"
                vs.push index
              when "NORMAL"
                ns.push @loader.getConvertedVec3(source.data, idx32)
              when "TEXCOORD"
                ts = ts or {}
                if ts[input.set] is undefined
                  ts[input.set] = []
                # invert the V
                ts[input.set].push new THREE.UV(source.data[idx32], 1.0 - source.data[idx32 + 1])
              when "COLOR"
                cs.push new THREE.Color().setRGB(source.data[idx32], source.data[idx32 + 1], source.data[idx32 + 2])

        if ns.length is 0
          # check the vertices inputs
          input = @vertices.input.NORMAL
          if input
            source    = @loader.sources[input.source]
            numParams = source.accessor.params.length
            
            vs_length = vs.length
            for ndx in [0...vs_length]
              ns.push @loader.getConvertedVec3(source.data, vs[ndx] * numParams)
          else
            geom.calcNormals = true

        unless ts
          ts = {}

          # check the vertices inputs
          input = @vertices.input.TEXCOORD
          if input
            texture_sets.push input.set
            source    = @loader.sources[input.source]
            numParams = source.accessor.params.length

            vs_length = vs.length
            for ndx in [0...vs_length]
              idx32 = vs[ndx] * numParams
              if ts[input.set] is undefined
                ts[input.set] = []
              # invert the V
              ts[input.set].push new THREE.UV(source.data[idx32], 1.0 - source.data[idx32 + 1])

        if cs.length is 0

          # check the vertices inputs
          input = @vertices.input.COLOR
          if input
            source    = @loader.sources[input.source]
            numParams = source.accessor.params.length

            vs_length = vs.length
            for ndx in [0...vs_length]
              idx32 = vs[ndx] * numParams
              cs.push new THREE.Color().setRGB(source.data[idx32], source.data[idx32 + 1], source.data[idx32 + 2])

        faces = []
        if vcount is 3
          faces.push new THREE.Face3(vs[0], vs[1], vs[2], ns, (if cs.length then cs else new THREE.Color()))
        else if vcount is 4
          faces.push new THREE.Face4(vs[0], vs[1], vs[2], vs[3], ns, (if cs.length then cs else new THREE.Color()))
        else if vcount > 4 and options.subdivideFaces
          if cs.length
            clr = cs
          else
            clr = new THREE.Color()

          # subdivide into multiple Face3s
          vcount_1 = vcount - 1
          for k in [1...vcount_1]
            # FIXME: normals don't seem to be quite right
            faces.push new THREE.Face3(vs[0], vs[k], vs[k + 1], [ ns[0], ns[k], ns[k] ], clr)

        if faces.length
          length = faces.length
          for ndx in [0...length]
            face = faces[ndx]
            face.daeMaterial = primitive.material
            geom.faces.push face

            textures_length = texture_sets.length
            for k in [0...textures_length]
              uv = ts[texture_sets[k]]
              if vcount > 4
                # Grab the right UVs for the vertices in this face
                uvArr = [uv[0], uv[ndx + 1], uv[ndx + 2]]
              else if vcount is 4
                uvArr = [uv[0], uv[1], uv[2], uv[3]]
              else
                uvArr = [uv[0], uv[1], uv[2]]
              unless geom.faceVertexUvs[k]
                geom.faceVertexUvs[k] = []
              geom.faceVertexUvs[k].push uvArr
        else
          console.warn "dropped face with vcount ", vcount, " for geometry with id: ", geom.id
        i += maxOffset * vcount
    
namespace "THREE.Collada", (exports) ->
  exports.Mesh = Mesh
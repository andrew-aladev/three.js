# @author Tim Knip / http://www.floorplanner.com/ / tim at floorplanner.com
# @author aladjev.andrew@gmail.com

class Channel
  constructor: (animation) ->
    @animation  = animation
    @source     = ""
    @target     = ""
    @fullSid    = null
    @sid        = null
    @dotSyntax  = null
    @arrSyntax  = null
    @arrIndices = null
    @member     = null
    
  parse: (element) ->
    @source = element.getAttribute("source").replace /^#/, ""
    @target = element.getAttribute "target"
    parts   = @target.split("/")
    id      = parts.shift()
    sid     = parts.shift()
    
    dotSyntax = sid.indexOf(".") >= 0
    arrSyntax = sid.indexOf("(") >= 0
    if dotSyntax
      parts = sid.split "."
      @sid = parts.shift()
      @member = parts.shift()
    else if arrSyntax
      arrIndices  = sid.split "("
      @sid        = arrIndices.shift()

      arr_length = arrIndices.length
      for j in [0...arr_length]
        arrIndices[j] = parseInt arrIndices[j].replace(/\)/, "")
      @arrIndices = arrIndices
    else
      @sid = sid

    @fullSid    = sid
    @dotSyntax  = dotSyntax
    @arrSyntax  = arrSyntax
    this
    
namespace "THREE.Collada", (exports) ->
  exports.Channel = Channel
# @author mrdoob / http://mrdoob.com/
# @author aladjev.andrew@gmail.com

#= require new_src/loaders/loader

class ImageLoader extends THREE.Loader

  load: (url, callback) ->
    image = new Image()
    image.onload = =>
      callback image
      @onLoadComplete()
  
    image.crossOrigin = @crossOrigin
    image.src = path
    @onLoadStart()
    
namespace "THREE", (exports) ->
  exports.ImageLoader = ImageLoader
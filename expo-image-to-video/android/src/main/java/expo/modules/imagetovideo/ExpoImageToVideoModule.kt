package expo.modules.imagetovideo

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import expo.modules.kotlin.records.Field    
import expo.modules.kotlin.records.Record   
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.net.URL

class ExpoImageToVideoModule : Module() {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  override fun definition() = ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoImageToVideo')` in JavaScript.
    Name("ExpoImageToVideo")

    // Defines constant property on the module.
    Constant("PI") {
      Math.PI
    }

    // Defines event names that the module can send to JavaScript.
    Events("onChange")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("hello") {
      "Hello world! 👋"
    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("setValueAsync") { value: String ->
      // Send an event to JavaScript.
      sendEvent("onChange", mapOf(
        "value" to value
      ))
    }

    // The 'options' argument will now automatically map to the VideoOptions class below
        AsyncFunction("generateVideo") { options: VideoOptions, promise: expo.modules.kotlin.Promise ->
            val context = appContext.reactContext ?: throw Exception("Context not found")
            
            CoroutineScope(Dispatchers.IO).launch {
                try {
                    val outputFile = if (options.outputPath != null) {
                        File(options.outputPath!!)
                    } else {
                        File(context.cacheDir, "video_${System.currentTimeMillis()}.mp4")
                    }

                    // Ensure defaults are handled if 0 or null
                    val finalBitrate = options.bitrate ?: 2500000 
                    
                    val encoder = VideoEncoder(
                        outputFile,
                        options.width,
                        options.height,
                        options.fps,
                        finalBitrate
                    )

                    encoder.start()

                    options.images.forEach { uri ->
                        // Load bitmap with the fixed width/height
                        val bitmap = ImageUtils.loadBitmap(context, uri, options.width, options.height)
                        
                        if (bitmap != null) {
                            encoder.encodeFrame(bitmap)
                            bitmap.recycle()
                        } else {
                            // Optional: Log warning for failed image load
                            println("ExpoImageToVideo: Failed to load $uri")
                        }
                    }

                    encoder.stop()
                    promise.resolve(outputFile.absolutePath)
                } catch (e: Exception) {
                    promise.reject("ERR_VIDEO_ENCODING", e.message, e)
                }
            }
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of
    // the view definition: Prop, Events.
    View(ExpoImageToVideoView::class) {
      // Defines a setter for the `url` prop.
      Prop("url") { view: ExpoImageToVideoView, url: URL ->
        view.webView.loadUrl(url.toString())
      }
      // Defines an event that the view can send to JavaScript.
      Events("onLoad")
    }
  }
}

// Data class for Expo Module auto-serialization
// 1. Must implement 'Record'
// 2. Must use 'var' (mutable) properties
// 3. Must use '@Field' annotation
class VideoOptions : Record {
    @Field
    var images: List<String> = emptyList()

    @Field
    var fps: Int = 30

    @Field
    var width: Int = 1280

    @Field
    var height: Int = 720

    @Field
    var bitrate: Int? = null

    @Field
    var outputPath: String? = null
}
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

        AsyncFunction("generateVideo") { options: VideoOptions, promise: expo.modules.kotlin.Promise ->
            val context = appContext.reactContext ?: run {
                promise.reject("ERR_CONTEXT", "React Context not found", null)
                return@AsyncFunction
            }
            
            CoroutineScope(Dispatchers.IO).launch {
                var encoder: VideoEncoder? = null
                try {
                    val outputFile = if (!options.outputPath.isNullOrEmpty()) {
                        File(options.outputPath!!)
                    } else {
                        File(context.cacheDir, "export_${System.currentTimeMillis()}.mp4")
                    }

                    // For High Quality 1080p, we recommend 5-8Mbps
                    val bitrate = options.bitrate ?: 5000000 
                    
                    encoder = VideoEncoder(
                        outputFile,
                        options.width,
                        options.height,
                        options.fps,
                        bitrate
                    )

                    encoder.start()

                    options.images.forEachIndexed { index, uri ->
                        // Using ImageUtils to load bitmap with memory-safe scaling
                        val bitmap = ImageUtils.loadBitmap(context, uri, options.width, options.height)
                        if (bitmap != null) {
                            encoder.encodeFrame(bitmap)
                            bitmap.recycle()
                        } else {
                            // Professional error logging without crashing
                            System.err.println("ExpoImageToVideo: Skipping invalid frame at index $index")
                        }
                    }

                    encoder.stop()
                    promise.resolve(outputFile.absolutePath)
                } catch (e: Exception) {
                    encoder?.stop()
                    promise.reject("ERR_VIDEO_ENCODING", e.localizedMessage, e)
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
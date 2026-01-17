import ExpoModulesCore
import AVFoundation

public class ExpoImageToVideoModule: Module {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.
  public func definition() -> ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoImageToVideo')` in JavaScript.
    Name("ExpoImageToVideo")

    // Defines constant property on the module.
    Constant("PI") {
      Double.pi
    }

    // Defines event names that the module can send to JavaScript.
    Events("onChange")

    // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
    Function("hello") {
      return "Hello world! 👋"
    }

    // Defines a JavaScript function that always returns a Promise and whose native code
    // is by default dispatched on the different thread than the JavaScript runtime runs on.
    AsyncFunction("setValueAsync") { (value: String) in
      // Send an event to JavaScript.
      self.sendEvent("onChange", [
        "value": value
      ])
    }

    AsyncFunction("generateVideo") { (options: VideoOptions, promise: Promise) in
      // Move to background thread to avoid blocking the JS/UI threads
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let outputURL = options.outputPath != nil 
            ? URL(fileURLWithPath: options.outputPath!) 
            : URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("video_\(UUID().uuidString).mp4")

          // Delete existing file if it exists (AVAssetWriter will fail otherwise)
          if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
          }

          let encoder = try VideoEncoder(
            outputURL: outputURL,
            width: options.width,
            height: options.height,
            fps: options.fps,
            bitrate: options.bitrate ?? 2_500_000
          )

          for (index, imageUri) in options.images.enumerated() {
            // Use autoreleasepool to prevent memory spikes during high-res processing
            try autoreleasepool {
              guard let url = URL(string: imageUri),
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) else {
                throw NSError(domain: "ExpoImageToVideo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image at \(imageUri)"])
              }

              let frameTime = CMTime(value: Int64(index), timescale: Int32(options.fps))
              try encoder.addFrame(image: image, at: frameTime)
            }
          }

          encoder.finish { success in
            if success {
              promise.resolve(outputURL.path)
            } else {
              promise.reject("ERR_VIDEO_FINALIZATION", "Could not finalize MP4 file")
            }
          }
        } catch {
          promise.reject("ERR_VIDEO_ENCODING", error.localizedDescription)
        }
      }
    }

    // Enables the module to be used as a native view. Definition components that are accepted as part of the
    // view definition: Prop, Events.
    View(ExpoImageToVideoView.self) {
      // Defines a setter for the `url` prop.
      Prop("url") { (view: ExpoImageToVideoView, url: URL) in
        if view.webView.url != url {
          view.webView.load(URLRequest(url: url))
        }
      }

      Events("onLoad")
    }
  }
}


// Structure to map the JS options object
struct VideoOptions: Record {
  @Field var images: [String] = []
  @Field var fps: Int = 30
  @Field var width: Int = 1280
  @Field var height: Int = 720
  @Field var bitrate: Int? = nil
  @Field var outputPath: String? = nil
}

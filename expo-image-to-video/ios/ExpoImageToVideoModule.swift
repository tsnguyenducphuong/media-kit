import ExpoModulesCore
import AVFoundation
import UIKit 
import ImageIO // Necessary for CGImageSource

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

    // The 'options' argument automatically maps to the VideoOptions struct below
    AsyncFunction("generateVideo") { (options: VideoOptions, promise: Promise) in
      // Use [weak self] to prevent memory leaks during long encoding tasks
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else { return }
        var encoder: VideoEncoder?
        
        do {
          let outputURL = options.outputPath != nil 
            ? URL(fileURLWithPath: options.outputPath!) 
            : URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("h_res_export_\(UUID().uuidString).mp4")

          if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
          }

          // Default to 5Mbps for 1080p high-quality content
          let bitrate = options.bitrate ?? 5_000_000

          encoder = try VideoEncoder(
            outputURL: outputURL,
            width: options.width,
            height: options.height,
            fps: options.fps,
            bitrate: bitrate
          )

          for (index, imageUri) in options.images.enumerated() {
            try autoreleasepool {
              guard let url = URL(string: imageUri) else { return }
              
              // Downsample using CGImageSource for memory efficiency and EXIF correction
              let image = self.loadDownsampledImage(at: url, for: CGSize(width: CGFloat(options.width), height: CGFloat(options.height)))
              
              if let validImage = image {
                let frameTime = CMTime(value: Int64(index), timescale: Int32(options.fps))
                try encoder?.addFrame(image: validImage, at: frameTime)
              }
            }
          }

          encoder?.finish { success in
            if success {
              promise.resolve(outputURL.path)
            } else {
              promise.reject("ERR_VIDEO_FINALIZATION", "AVAssetWriter failed to finalize")
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

// Helper: Efficiently loads and downsamples image without decoding full resolution first
  private func loadDownsampledImage(at url: URL, for size: CGSize) -> UIImage? {
    let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true, // Respects EXIF orientation
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height)
    ]
    
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
        return nil
    }
    return UIImage(cgImage: cgImage)
}

}

 


// Structure to map the JS options object
// Must inherit from 'Record' and use '@Field'
struct VideoOptions: Record {
  @Field
  var images: [String] = []

  @Field
  var fps: Int = 30

  @Field
  var width: Int = 1280

  @Field
  var height: Int = 720

  @Field
  var bitrate: Int? = nil

  @Field
  var outputPath: String? = nil
}

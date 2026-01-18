import AVFoundation
import UIKit

class VideoEncoder {
    private let assetWriter: AVAssetWriter
    private let input: AVAssetWriterInput
    private let adaptor: AVAssetWriterInputPixelBufferAdaptor
    private let width: Int
    private let height: Int

    init(outputURL: URL, width: Int, height: Int, fps: Int, bitrate: Int) throws {
        self.width = width
        self.height = height
        
        assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        // --- HIGH QUALITY COMPRESSION SETTINGS ---
        let compressionProperties: [String: Any] = [
            AVVideoAverageBitRateKey: bitrate,
            AVVideoExpectedSourceFrameRateKey: fps,
            AVVideoMaxKeyFrameIntervalKey: fps * 2, // I-Frame every 2 seconds
            AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel, // High Profile
            AVVideoAllowFrameReorderingKey: true // Enables B-Frames for better quality/size ratio
        ]
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: compressionProperties
        ]
        
        input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = false
        
        let bufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input, 
            sourcePixelBufferAttributes: bufferAttributes
        )
        
        assetWriter.add(input)
        assetWriter.startWriting()
        assetWriter.startSession(atSourceTime: .zero)
    }

    func addFrame(image: UIImage, at time: CMTime) throws {
        while !input.isReadyForMoreMediaData {
            Thread.sleep(forTimeInterval: 0.005) // Tighter polling for performance
        }
        
        guard let pixelBuffer = createPixelBuffer(from: image) else {
            throw NSError(domain: "VideoEncoder", code: 2, userInfo: [NSLocalizedDescriptionKey: "PixelBuffer creation failed"])
        }
        
        if !adaptor.append(pixelBuffer, withPresentationTime: time) {
            throw assetWriter.error ?? NSError(domain: "VideoEncoder", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to append pixel buffer"])
        }
    }

    private func createPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, adaptor.pixelBufferPool!, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        let data = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        
        // --- HIGH QUALITY SCALING ---
        context?.interpolationQuality = .high // Ensures sharp scaling
        context?.setShouldAntialias(true)
        context?.setAllowsAntialiasing(true)
        
        if let cgImage = image.cgImage {
            // Calculate aspect fill rect to avoid stretching
            let imageSize = image.size
            let targetSize = CGSize(width: width, height: height)
            let rect = AVMakeRect(aspectRatio: imageSize, insideRect: CGRect(origin: .zero, size: targetSize))
            
            context?.clear(CGRect(x: 0, y: 0, width: width, height: height))
            context?.draw(cgImage, in: rect)
        }
        
        return buffer
    }

    func finish(completion: @escaping (Bool) -> Void) {
        input.markAsFinished()
        assetWriter.finishWriting {
            completion(self.assetWriter.status == .completed)
        }
    }
}
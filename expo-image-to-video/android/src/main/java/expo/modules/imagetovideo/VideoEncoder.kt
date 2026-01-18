package expo.modules.imagetovideo

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaFormat
import android.media.MediaMuxer
import android.view.Surface
import java.io.File

class VideoEncoder(
    private val outputFile: File,
    private val width: Int,
    private val height: Int,
    private val fps: Int,
    private val bitrate: Int
) {
    private var encoder: MediaCodec? = null
    private var muxer: MediaMuxer? = null
    private var inputSurface: Surface? = null
    private var trackIndex = -1
    private var frameDurationUs = 1000000L / fps
    private var frameCount = 0

    // High-quality paint for scaling bitmaps
    private val paint = Paint().apply {
        isAntiAlias = true
        isFilterBitmap = true
        isDither = true
    }

    fun start() {
        val format = MediaFormat.createVideoFormat(MediaFormat.MIMETYPE_VIDEO_AVC, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2) // I-frame every 2 seconds for better seekability/quality
            
            // --- HIGH QUALITY OPTIMIZATIONS ---
            // Use Variable Bitrate (VBR) to prioritize quality in complex frames
            setInteger(MediaFormat.KEY_BITRATE_MODE, MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR)
            // Use High Profile for better compression efficiency (if supported)
            setInteger(MediaFormat.KEY_PROFILE, MediaCodecInfo.CodecProfileLevel.AVCProfileHigh)
            setInteger(MediaFormat.KEY_LEVEL, MediaCodecInfo.CodecProfileLevel.AVCLevel4)
        }

        encoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_VIDEO_AVC).apply {
            configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            inputSurface = createInputSurface()
            start()
        }

        muxer = MediaMuxer(outputFile.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
    }

    fun encodeFrame(bitmap: Bitmap) {
        val canvas = inputSurface?.lockCanvas(null) ?: return
        try {
            // High-quality drawing to the surface
            val destRect = Rect(0, 0, width, height)
            canvas.drawBitmap(bitmap, null, destRect, paint)
        } finally {
            val pts = frameCount * frameDurationUs
            inputSurface?.unlockCanvasAndPost(canvas)
            drainEncoder(false, pts)
            frameCount++
        }
    }

    private fun drainEncoder(endOfStream: Boolean, pts: Long) {
        val bufferInfo = MediaCodec.BufferInfo()
        val encoder = encoder ?: return

        if (endOfStream) {
            encoder.signalEndOfInputStream()
        }

        while (true) {
            val outputBufferIndex = encoder.dequeueOutputBuffer(bufferInfo, 10000)
            if (outputBufferIndex == MediaCodec.INFO_TRY_AGAIN_LATER) {
                if (!endOfStream) break
            } else if (outputBufferIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                if (trackIndex == -1) {
                    trackIndex = muxer?.addTrack(encoder.outputFormat) ?: -1
                    muxer?.start()
                }
            } else if (outputBufferIndex >= 0) {
                val encodedData = encoder.getOutputBuffer(outputBufferIndex) ?: continue
                
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                    bufferInfo.size = 0
                }

                if (bufferInfo.size != 0 && trackIndex != -1) {
                    encodedData.position(bufferInfo.offset)
                    encodedData.limit(bufferInfo.offset + bufferInfo.size)
                    bufferInfo.presentationTimeUs = pts
                    muxer?.writeSampleData(trackIndex, encodedData, bufferInfo)
                }

                encoder.releaseOutputBuffer(outputBufferIndex, false)
                if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) break
            }
        }
    }

    fun stop() {
        try {
            drainEncoder(true, frameCount * frameDurationUs)
            encoder?.stop()
        } finally {
            encoder?.release()
            muxer?.stop()
            muxer?.release()
            inputSurface?.release()
            encoder = null
            muxer = null
            inputSurface = null
        }
    }
}
import ExpoImageToVideoModule from './ExpoImageToVideoModule';
import { VideoOptions } from './ExpoImageToVideo.types';

/**
 * Converts a sequence of images into an MP4 video.
 * * @param options Configuration object for video generation.
 * @returns A Promise that resolves to the file URI of the generated video.
 */
export async function generateVideo(options: VideoOptions): Promise<string> {
  // 1. Validate Image List
  if (!options.images || options.images.length === 0) {
    throw new Error(
      "[ExpoImageToVideo] The 'images' array cannot be empty. Please provide at least one image URI."
    );
  }

  // 2. Validate Dimensions
  if (options.width <= 0 || options.height <= 0) {
    throw new Error(
      `[ExpoImageToVideo] Invalid dimensions: ${options.width}x${options.height}. Width and height must be positive integers.`
    );
  }

  // 3. Validate FPS
  if (options.fps <= 0) {
    throw new Error(
      `[ExpoImageToVideo] Invalid FPS: ${options.fps}. Frames per second must be greater than 0.`
    );
  }

  // 4. Call Native Module
  return await ExpoImageToVideoModule.generateVideo(options);
}

export { VideoOptions };
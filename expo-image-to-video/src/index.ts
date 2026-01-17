// Reexport the native module. On web, it will be resolved to ExpoImageToVideoModule.web.ts
// and on native platforms to ExpoImageToVideoModule.ts
// export { default } from './ExpoImageToVideoModule';
export { default as ExpoImageToVideoView } from './ExpoImageToVideoView';
// export * from  './ExpoImageToVideo.types';

import ExpoImageToVideoModule from './ExpoImageToVideoModule';
import { VideoOptions } from './ExpoImageToVideo.types';


/**
 * Converts a list of images to an MP4 video file using native hardware encoders.
 * @param options Configuration for the video encoding process.
 * @returns A promise that resolves to the local URI of the generated .mp4 file.
 */
export async function generateVideo(options: VideoOptions): Promise<string> {
  // Validate basic requirements before hitting native code
  if (options.images.length === 0) {
    throw new Error("At least one image is required to generate a video.");
  }
  
  return await ExpoImageToVideoModule.generateVideo(options);
}

export * from './ExpoImageToVideo.types';
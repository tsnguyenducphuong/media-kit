import type { StyleProp, ViewStyle } from 'react-native';

export type OnLoadEventPayload = {
  url: string;
};

export type ExpoImageToVideoModuleEvents = {
  onChange: (params: ChangeEventPayload) => void;
};

export type ChangeEventPayload = {
  value: string;
};

export type ExpoImageToVideoViewProps = {
  url: string;
  onLoad: (event: { nativeEvent: OnLoadEventPayload }) => void;
  style?: StyleProp<ViewStyle>;
};

export interface VideoOptions {
  /**
   * An array of local file URIs (file://...) to images.
   * At least one image is required.
   */
  images: string[];

  /**
   * Frames per second for the output video.
   * Recommended: 30 or 60.
   */
  fps: number;

  /**
   * Width of the output video in pixels.
   * Example: 1920 (for 1080p), 1280 (for 720p).
   */
  width: number;

  /**
   * Height of the output video in pixels.
   * Example: 1080 (for 1080p), 720 (for 720p).
   */
  height: number;

  /**
   * Optional bitrate in bits per second.
   * Higher values = better quality but larger file size.
   * Default: 2,500,000 (2.5 Mbps).
   */
  bitrate?: number;

  /**
   * Optional full path to the output file.
   * If not provided, a temporary file is created in the cache directory.
   */
  outputPath?: string;
}

export type VideoModuleEvents = {
  // You could add onProgress here later if needed
};
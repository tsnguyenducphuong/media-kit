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
  /** Array of local file URIs (e.g., from expo-image-picker or expo-file-system) */
  images: string[];
  /** Frames per second (e.g., 30 or 60) */
  fps: number;
  /** Final video width (pixels) */
  width: number;
  /** Final video height (pixels) */
  height: number;
  /** Target bitrate in bits per second. Default is 2.5Mbps (2,500,000) */
  bitrate?: number;
  /** Optional custom output path. If not provided, a temp file is created */
  outputPath?: string;
}

export type VideoModuleEvents = {
  // You could add onProgress here later if needed
};
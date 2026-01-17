import { NativeModule, requireNativeModule } from 'expo';

import { ExpoImageToVideoModuleEvents, VideoOptions } from './ExpoImageToVideo.types';

declare class ExpoImageToVideoModule extends NativeModule<ExpoImageToVideoModuleEvents> {
  PI: number;
  hello(): string;
  setValueAsync(value: string): Promise<void>;
  generateVideo(options: VideoOptions): Promise<string>;
}

// This call loads the native module object from the JSI.
export default requireNativeModule<ExpoImageToVideoModule>('ExpoImageToVideo');

// // This links directly to the 'Name("ExpoImageToVideo")' defined in Swift/Kotlin
// export default requireNativeModule('ExpoImageToVideo');
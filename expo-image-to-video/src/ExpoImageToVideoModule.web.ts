import { registerWebModule, NativeModule } from 'expo';

import { ExpoImageToVideoModuleEvents } from './ExpoImageToVideo.types';

class ExpoImageToVideoModule extends NativeModule<ExpoImageToVideoModuleEvents> {
  PI = Math.PI;
  async setValueAsync(value: string): Promise<void> {
    this.emit('onChange', { value });
  }
  hello() {
    return 'Hello world! 👋';
  }
}

export default registerWebModule(ExpoImageToVideoModule, 'ExpoImageToVideoModule');

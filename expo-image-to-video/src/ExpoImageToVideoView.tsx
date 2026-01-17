import { requireNativeView } from 'expo';
import * as React from 'react';

import { ExpoImageToVideoViewProps } from './ExpoImageToVideo.types';

const NativeView: React.ComponentType<ExpoImageToVideoViewProps> =
  requireNativeView('ExpoImageToVideo');

export default function ExpoImageToVideoView(props: ExpoImageToVideoViewProps) {
  return <NativeView {...props} />;
}

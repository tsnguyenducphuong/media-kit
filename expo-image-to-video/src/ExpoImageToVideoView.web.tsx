import * as React from 'react';

import { ExpoImageToVideoViewProps } from './ExpoImageToVideo.types';

export default function ExpoImageToVideoView(props: ExpoImageToVideoViewProps) {
  return (
    <div>
      <iframe
        style={{ flex: 1 }}
        src={props.url}
        onLoad={() => props.onLoad({ nativeEvent: { url: props.url } })}
      />
    </div>
  );
}

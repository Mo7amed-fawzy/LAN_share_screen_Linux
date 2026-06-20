import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class VideoRenderer extends StatelessWidget {
  final lk.VideoTrack track;
  final lk.VideoViewMirrorMode mirrorMode;

  const VideoRenderer({
    super.key,
    required this.track,
    this.mirrorMode = lk.VideoViewMirrorMode.auto,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: lk.VideoTrackRenderer(
        track,
        fit: lk.VideoViewFit.cover,
        mirrorMode: mirrorMode,
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../core/error/error_handler.dart';
import 'capture_config.dart';

class CaptureService {
  lk.LocalVideoTrack? _track;
  rtc.MediaStream? _capturedStream;
  String? _publishedSid;

  lk.LocalVideoTrack? get screenTrack => _track;
  bool get isCapturing => _track != null;
  String? get publishedSid => _publishedSid;

  void markPublished(String sid) {
    _publishedSid = sid;
  }

  void clearPublished() {
    _publishedSid = null;
  }

  Future<lk.LocalVideoTrack> startCapture({
    CaptureConfig config = const CaptureConfig(),
  }) async {
    try {
      debugPrint('[CaptureService] startCapture');
      stopCapture();

      debugPrint('[CaptureService] enumerating screen sources...');
      final sources = await rtc.desktopCapturer.getSources(
        types: [rtc.SourceType.Screen],
      );

      if (sources.isEmpty) {
        throw Exception(
          'No screen sources found. Ensure PipeWire and xdg-desktop-portal are running.',
        );
      }

      final source = sources.first;
      debugPrint('[CaptureService] using source: ${source.id} ${source.name}');

      final stream = await rtc.navigator.mediaDevices.getDisplayMedia({
        'video': {
          'deviceId': {'exact': source.id},
          'mandatory': {'frameRate': config.frameRate},
        },
      });

      _capturedStream = stream;
      final videoTrack = stream.getVideoTracks().first;
      debugPrint('[CaptureService] captured video track: ${videoTrack.id}');

      _track = lk.LocalVideoTrack(
        lk.TrackSource.screenShareVideo,
        stream,
        videoTrack,
        const lk.ScreenShareCaptureOptions(),
      );

      debugPrint('[CaptureService] LiveKit track created');
      return _track!;
    } catch (e, s) {
      debugPrint('[CaptureService] startCapture FAILED: $e\n$s');
      throw handleError(e, s);
    }
  }

  void stopCapture() {
    if (_track != null) {
      debugPrint('[CaptureService] stopCapture');
      _track!.stop();
      _track!.dispose();
      _track = null;
    }
    if (_capturedStream != null) {
      _capturedStream!.dispose();
      _capturedStream = null;
    }
    _publishedSid = null;
  }

  void dispose() {
    stopCapture();
  }
}

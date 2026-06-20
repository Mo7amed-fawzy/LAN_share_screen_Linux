import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/capture_service.dart';
import '../../domain/capture_config.dart';

final captureServiceProvider = Provider<CaptureService>((ref) {
  final service = CaptureService();
  ref.onDispose(() => service.dispose());
  return service;
});

final isCapturingProvider = StateProvider<bool>((ref) => false);

final captureStateProvider = Provider<CaptureService>((ref) {
  return ref.watch(captureServiceProvider);
});

class CaptureActions {
  final CaptureService service;

  CaptureActions(this.service);

  Future<void> start({CaptureConfig config = const CaptureConfig()}) async {
    debugPrint('[CaptureActions] start');
    await service.startCapture(config: config);
    debugPrint('[CaptureActions] start done, isCapturing=${service.isCapturing}');
  }

  void stop() {
    debugPrint('[CaptureActions] stop');
    service.stopCapture();
  }
}

final captureActionsProvider = Provider<CaptureActions>((ref) {
  final service = ref.watch(captureServiceProvider);
  return CaptureActions(service);
});

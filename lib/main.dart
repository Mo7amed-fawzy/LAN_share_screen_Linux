import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/network/connection/connection_provider.dart';
import 'core/utils/logger.dart';
import 'features/room/presentation/providers/room_provider.dart';
import 'features/participant/presentation/providers/participants_provider.dart';
import 'features/remote_control/presentation/providers/remote_control_provider.dart';
import 'features/screen_capture/presentation/providers/capture_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLogging();
  final autoTest = const bool.fromEnvironment('AUTO_TEST', defaultValue: false);
  runApp(
    ProviderScope(
      child: autoTest
          ? const _AutoTestWrapper(child: ScreenShareApp())
          : const ScreenShareApp(),
    ),
  );
}

class _AutoTestWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _AutoTestWrapper({required this.child});

  @override
  ConsumerState<_AutoTestWrapper> createState() => _AutoTestWrapperState();
}

class _AutoTestWrapperState extends ConsumerState<_AutoTestWrapper> {
  bool _shared = false;
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _initConnection();
  }

  void _initConnection() {
    final manager = ref.read(connectionManagerProvider);
    manager.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(isNetworkConnectedProvider);
    final participants = ref.watch(participantsProvider).valueOrNull ?? [];
    final state = ref.watch(remoteControlStateProvider).valueOrNull;

    if (isConnected && !_shared) {
      _shared = true;
      WidgetsBinding.instance.addPostFrameCallback((duration) => _autoShare());
    }

    if (isConnected && !_requested) {
      final remote =
          participants.where((p) => !p.isLocal && p.hasVideo).firstOrNull;
      if (remote != null && (state?.isIdle ?? false)) {
        _requested = true;
        WidgetsBinding.instance.addPostFrameCallback((duration) {
          _autoRequestControl(remote.identity);
        });
      }
    }

    return widget.child;
  }

  Future<void> _autoShare() async {
    try {
      final captureService = ref.read(captureServiceProvider);
      final roomService = ref.read(roomServiceProvider);
      await captureService.startCapture();
      final track = captureService.screenTrack;
      if (track != null) {
        final publication = await roomService.publishScreenTrack(track);
        captureService.markPublished(publication.sid);
        ref.read(isCapturingProvider.notifier).state = true;
        debugPrint('[AutoTest] Screen sharing started');
      }
    } catch (e) {
      debugPrint('[AutoTest] Auto share failed: $e');
    }
  }

  Future<void> _autoRequestControl(String identity) async {
    try {
      final service = ref.read(remoteControlServiceProvider);
      await service.requestControl(identity);
      debugPrint('[AutoTest] Requested control from $identity');
    } catch (e) {
      debugPrint('[AutoTest] Request control failed: $e');
    }
  }
}

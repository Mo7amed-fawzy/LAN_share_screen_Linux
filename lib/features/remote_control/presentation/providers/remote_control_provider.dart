import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connection/connection_provider.dart';
import '../../domain/remote_control_service.dart';
import '../../domain/remote_control_state.dart';

final remoteControlServiceProvider = Provider<RemoteControlService>((ref) {
  final manager = ref.watch(connectionManagerProvider);
  final service = RemoteControlService(
    liveKitClient: manager.liveKitClient,
    connectionManager: manager,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final remoteControlStateProvider = StreamProvider<RemoteControlState>((ref) {
  return ref.watch(remoteControlServiceProvider).stateStream;
});

final incomingControlRequestProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(remoteControlServiceProvider);
  return service.requestFromStream.map((id) => id);
});

final isControllingProvider = Provider<bool>((ref) {
  final state = ref.watch(remoteControlStateProvider).valueOrNull;
  return state?.phase == RemoteControlPhase.controlling;
});

final isRequestingProvider = Provider<bool>((ref) {
  final state = ref.watch(remoteControlStateProvider).valueOrNull;
  return state?.phase == RemoteControlPhase.requesting;
});

final isBeingControlledProvider = Provider<bool>((ref) {
  final state = ref.watch(remoteControlStateProvider).valueOrNull;
  return state?.phase == RemoteControlPhase.beingControlled;
});

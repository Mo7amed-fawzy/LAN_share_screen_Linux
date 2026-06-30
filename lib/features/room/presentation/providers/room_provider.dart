import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connection/connection_provider.dart';
import '../../data/room_repository.dart';
import '../../domain/room_service.dart';
import '../../domain/room_state.dart';
import 'room_state_notifier.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final liveKit = ref.watch(liveKitClientProvider);
  final repo = RoomRepository(liveKitClient: liveKit);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final roomServiceProvider = Provider<RoomService>((ref) {
  final repo = ref.watch(roomRepositoryProvider);
  return RoomService(repo);
});

final roomStateNotifierProvider =
    StateNotifierProvider<RoomStateNotifier, RoomConnectionState>((ref) {
  final service = ref.watch(roomServiceProvider);
  final connectionManager = ref.watch(connectionManagerProvider);
  final notifier = RoomStateNotifier(service, connectionManager);
  return notifier;
});

final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(isNetworkConnectedProvider);
});

final hostStatusProvider = Provider<bool>((ref) {
  return ref.watch(isHostProvider);
});

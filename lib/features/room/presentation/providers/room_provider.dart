import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/room_repository.dart';
import '../../domain/room_service.dart';
import '../../domain/room_state.dart';
import 'room_state_notifier.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final repo = RoomRepository();
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
  final notifier = RoomStateNotifier(service);
  notifier.autoJoin();
  return notifier;
});

final isConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(roomStateNotifierProvider);
  return state == RoomConnectionState.connected;
});

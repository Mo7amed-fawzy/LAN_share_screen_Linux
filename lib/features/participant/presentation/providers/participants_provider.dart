import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../room/presentation/providers/room_provider.dart';
import '../../data/participant_repo.dart';
import '../../domain/participant_service.dart';
import '../../domain/participant_entity.dart';

final _participantRepoProvider = Provider<ParticipantRepository>((ref) {
  final roomRepo = ref.watch(roomRepositoryProvider);
  final repo = ParticipantRepository(roomRepo);
  ref.onDispose(() => repo.dispose());
  return repo;
});

final participantServiceProvider = Provider<ParticipantService>((ref) {
  final repo = ref.watch(_participantRepoProvider);
  return ParticipantService(repo);
});

final participantsProvider = StreamProvider<List<ParticipantEntity>>((ref) {
  final service = ref.watch(participantServiceProvider);
  return service.participantsStream;
});

final remoteParticipantsProvider = Provider<List<ParticipantEntity>>((ref) {
  final participants = ref.watch(participantsProvider).valueOrNull ?? [];
  return participants.where((p) => !p.isLocal).toList();
});

final localParticipantProvider = Provider<ParticipantEntity?>((ref) {
  final participants = ref.watch(participantsProvider).valueOrNull ?? [];
  return participants.where((p) => p.isLocal).firstOrNull;
});

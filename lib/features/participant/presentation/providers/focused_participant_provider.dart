import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/participant_entity.dart';

final focusedParticipantProvider =
    StateProvider<ParticipantEntity?>((ref) => null);

final focusedParticipantIdentityProvider = StateProvider<String?>((ref) => null);

final hasFocusedParticipantProvider = Provider<bool>((ref) {
  return ref.watch(focusedParticipantProvider) != null;
});

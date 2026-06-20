import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../core/error/error_handler.dart';
import '../data/participant_repo.dart';
import 'participant_entity.dart';

class ParticipantService {
  final ParticipantRepository _repository;

  ParticipantService(this._repository);

  List<ParticipantEntity> getAllParticipants() {
    return _repository.getAllParticipants();
  }

  ParticipantEntity? getParticipant(String identity) {
    return _repository.getParticipant(identity);
  }

  Stream<List<ParticipantEntity>> get participantsStream =>
      _repository.participantsStream;

  Future<void> setTrackQuality({
    required String participantIdentity,
    required lk.VideoQuality quality,
  }) async {
    try {
      await _repository.setTrackQuality(
        participantIdentity: participantIdentity,
        quality: quality,
      );
    } catch (e, s) {
      throw handleError(e, s);
    }
  }

  void dispose() {
    _repository.dispose();
  }
}

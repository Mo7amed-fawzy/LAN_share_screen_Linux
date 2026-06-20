import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../core/error/error_handler.dart';
import '../data/room_repository.dart';
import 'room_state.dart';

class RoomService {
  final RoomRepository _repository;

  RoomService(this._repository);

  Stream<RoomConnectionState> get connectionStateStream =>
      _repository.connectionStateStream;

  lk.Room? get room => _repository.room;

  Future<void> joinRoom({
    required String url,
    required String token,
  }) async {
    try {
      await _repository.connect(url, token);
    } catch (e, s) {
      throw handleError(e, s);
    }
  }

  Future<void> leaveRoom() async {
    try {
      await _repository.disconnect();
    } catch (e, s) {
      logError('Error leaving room', e, s);
    }
  }

  Future<lk.LocalTrackPublication<lk.LocalVideoTrack>> publishScreenTrack(
    lk.LocalVideoTrack track,
  ) async {
    try {
      return await _repository.publishScreenTrack(track);
    } catch (e, s) {
      throw handleError(e, s);
    }
  }

  Future<void> unpublishScreenTrack(String trackSid) async {
    try {
      await _repository.unpublishTrack(trackSid);
    } catch (e, s) {
      logError('Error unpublishing track', e, s);
    }
  }

  List<lk.RemoteParticipant> get remoteParticipants =>
      _repository.remoteParticipants;

  lk.LocalParticipant? get localParticipant => _repository.localParticipant;

  void dispose() {
    _repository.dispose();
  }
}

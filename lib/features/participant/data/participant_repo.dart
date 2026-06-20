import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../room/data/room_repository.dart';
import '../../room/domain/room_state.dart';
import '../domain/participant_entity.dart';
import 'participant_mapper.dart';

class ParticipantRepository {
  final RoomRepository _roomRepository;
  final _participantsController =
      StreamController<List<ParticipantEntity>>.broadcast();
  StreamSubscription? _connectionSubscription;
  bool _listening = false;

  ParticipantRepository(this._roomRepository) {
    debugPrint('[ParticipantRepository] init');
    _connectionSubscription = _roomRepository.connectionStateStream.listen(
      _onConnectionStateChanged,
    );
  }

  void _onConnectionStateChanged(RoomConnectionState state) {
    if (state == RoomConnectionState.connected) {
      if (_listening) return;
      final room = _roomRepository.room;
      if (room != null) {
        debugPrint('[ParticipantRepository] adding room listener');
        room.addListener(_onParticipantsChanged);
        _listening = true;
        _emitParticipants();
      }
    } else if (state == RoomConnectionState.disconnected) {
      final room = _roomRepository.room;
      if (room != null && _listening) {
        room.removeListener(_onParticipantsChanged);
        _listening = false;
      }
      _participantsController.add([]);
    }
  }

  void _emitParticipants() {
    final participants = getAllParticipants();
    debugPrint('[ParticipantRepository] emitting ${participants.length} participants');
    _participantsController.add(participants);
  }

  Stream<List<ParticipantEntity>> get participantsStream =>
      _participantsController.stream;

  List<ParticipantEntity> getAllParticipants() {
    final participants = <ParticipantEntity>[];

    final local = _roomRepository.localParticipant;
    if (local != null) {
      participants.add(ParticipantMapper.fromLocalParticipant(local));
    }

    for (final remote in _roomRepository.remoteParticipants) {
      final entity = ParticipantMapper.fromRemoteParticipant(remote);
      participants.add(entity);
      debugPrint('[ParticipantRepository] remote: ${remote.identity} screenTrack=${entity.screenTrack != null}');
    }

    return participants;
  }

  ParticipantEntity? getParticipant(String identity) {
    return getAllParticipants().where((p) => p.identity == identity).firstOrNull;
  }

  Future<void> setTrackQuality({
    required String participantIdentity,
    required lk.VideoQuality quality,
  }) async {
    final remote =
        _roomRepository.room?.remoteParticipants[participantIdentity];
    if (remote == null) return;

    for (final publication in remote.videoTrackPublications) {
      if (publication.source == lk.TrackSource.screenShareVideo &&
          publication.subscribed) {
        await publication.setVideoQuality(quality);
      }
    }
  }

  void _onParticipantsChanged() {
    debugPrint('[ParticipantRepository] room listeners notified');
    _emitParticipants();
  }

  void dispose() {
    _connectionSubscription?.cancel();
    _roomRepository.room?.removeListener(_onParticipantsChanged);
    _participantsController.close();
  }
}

import 'dart:async';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/livekit_client.dart';
import 'room_mapper.dart';
import '../domain/room_state.dart';

class RoomRepository {
  final LiveKitClient _liveKitClient;
  StreamSubscription<lk.ConnectionState>? _connectionSub;
  final _connectionStateController =
      StreamController<RoomConnectionState>.broadcast();

  Stream<RoomConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  RoomRepository({required LiveKitClient liveKitClient})
      : _liveKitClient = liveKitClient {
    _connectionSub = _liveKitClient.connectionStateStream.listen((state) {
      _connectionStateController.add(RoomMapper.connectionStateFrom(state));
    });
  }

  lk.Room? get room => _liveKitClient.isConnected ? _liveKitClient.room : null;

  lk.LocalParticipant? get localParticipant => room?.localParticipant;

  List<lk.RemoteParticipant> get remoteParticipants {
    final r = room;
    if (r == null) return [];
    return r.remoteParticipants.values.toList();
  }

  Future<lk.LocalTrackPublication<lk.LocalVideoTrack>> publishScreenTrack(
    lk.LocalVideoTrack track,
  ) async {
    final r = room;
    if (r == null) {
      throw ConnectionFailure('Room not connected');
    }

    final local = r.localParticipant;
    if (local == null) {
      throw ConnectionFailure('Local participant not available');
    }

    return local.publishVideoTrack(
      track,
      publishOptions: lk.VideoPublishOptions(
        simulcast: true,
        videoCodec: 'H264',
        videoEncoding: const lk.VideoEncoding(
          maxBitrate: AppConstants.focusedMaxBitrate,
          maxFramerate: AppConstants.focusedFps,
        ),
      ),
    );
  }

  Future<void> unpublishTrack(String trackSid) async {
    await room?.localParticipant?.removePublishedTrack(trackSid);
  }

  void dispose() {
    _connectionSub?.cancel();
    _connectionStateController.close();
  }
}

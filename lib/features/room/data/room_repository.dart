import 'dart:async';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../core/constants/app_constants.dart';
import '../../../core/error/failures.dart';
import 'room_mapper.dart';
import '../domain/room_state.dart';

class RoomRepository {
  lk.Room? _room;
  final _connectionStateController =
      StreamController<RoomConnectionState>.broadcast();

  Stream<RoomConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  lk.Room? get room => _room;

  lk.LocalParticipant? get localParticipant => _room?.localParticipant;

  List<lk.RemoteParticipant> get remoteParticipants {
    if (_room == null) return [];
    return _room!.remoteParticipants.values.toList();
  }

  Future<void> connect(String url, String token) async {
    await lk.LiveKitClient.initialize();

    _room = lk.Room(
      roomOptions: const lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );

    _room!.addListener(_onRoomUpdate);

    _connectionStateController.add(
      RoomMapper.connectionStateFrom(lk.ConnectionState.connecting),
    );

    try {
      await _room!.connect(
        url,
        token,
        connectOptions: const lk.ConnectOptions(
          autoSubscribe: true,
        ),
      );
    } catch (e) {
      _connectionStateController.add(RoomConnectionState.failed);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      await _room?.disconnect();
    } finally {
      _room?.removeListener(_onRoomUpdate);
      unawaited(_room?.dispose());
      _room = null;
      _connectionStateController.add(RoomConnectionState.disconnected);
    }
  }

  Future<lk.LocalTrackPublication<lk.LocalVideoTrack>> publishScreenTrack(
    lk.LocalVideoTrack track,
  ) async {
    if (_room == null) {
      throw ConnectionFailure('Room not connected');
    }

    final local = _room!.localParticipant;
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
    await _room?.localParticipant?.removePublishedTrack(trackSid);
  }

  void _onRoomUpdate() {
    if (_room == null) return;
    _connectionStateController.add(
      RoomMapper.connectionStateFrom(_room!.connectionState),
    );
  }

  void dispose() {
    _room?.removeListener(_onRoomUpdate);
    _room?.dispose();
    _room = null;
    _connectionStateController.close();
  }
}

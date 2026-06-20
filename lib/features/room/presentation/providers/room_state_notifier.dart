import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/environment.dart';
import '../../../../core/network/jwt_token.dart';
import '../../domain/room_service.dart';
import '../../domain/room_state.dart';

class RoomStateNotifier extends StateNotifier<RoomConnectionState> {
  final RoomService _roomService;

  RoomStateNotifier(this._roomService) : super(RoomConnectionState.disconnected) {
    debugPrint('[RoomStateNotifier] init, listening to connectionStateStream');
    _roomService.connectionStateStream.listen((newState) {
      debugPrint('[RoomStateNotifier] stream -> $newState');
      state = newState;
    });
  }

  Future<void> joinRoom({
    required String roomName,
    required String participantIdentity,
  }) async {
    try {
      debugPrint('[RoomStateNotifier] joinRoom: room=$roomName identity=$participantIdentity');
      state = RoomConnectionState.connecting;

      final token = JwtToken.create(
        roomName: roomName,
        participantIdentity: participantIdentity,
      );
      debugPrint('[RoomStateNotifier] token created: $token');

      debugPrint('[RoomStateNotifier] calling _roomService.joinRoom(${Environment.liveKitUrl})');
      await _roomService.joinRoom(
        url: Environment.liveKitUrl,
        token: token,
      );
      debugPrint('[RoomStateNotifier] joinRoom completed successfully');
    } catch (e, s) {
      debugPrint('[RoomStateNotifier] joinRoom FAILED: $e\n$s');
      state = RoomConnectionState.failed;
    }
  }

  Future<void> leaveRoom() async {
    debugPrint('[RoomStateNotifier] leaveRoom');
    await _roomService.leaveRoom();
    state = RoomConnectionState.disconnected;
  }

  Future<void> autoJoin() async {
    final rand = Random().nextInt(999999);
    debugPrint('[RoomStateNotifier] autoJoin');
    await joinRoom(
      roomName: 'screen_share',
      participantIdentity: 'user_$rand',
    );
  }
}

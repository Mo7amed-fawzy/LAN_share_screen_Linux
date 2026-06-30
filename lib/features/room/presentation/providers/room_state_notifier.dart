import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connection/connection_manager.dart';
import '../../../../core/network/connection/connection_state.dart';
import '../../domain/room_service.dart';
import '../../domain/room_state.dart';

class RoomStateNotifier extends StateNotifier<RoomConnectionState> {
  final RoomService _roomService;
  final ConnectionManager _connectionManager;
  StreamSubscription<ConnectionState>? _connectionSub;

  RoomStateNotifier(
    this._roomService,
    this._connectionManager,
  ) : super(RoomConnectionState.disconnected) {
    _connectionSub = _connectionManager.stateStream.listen((connState) {
      _onConnectionStateChanged(connState);
    });
  }

  void _onConnectionStateChanged(ConnectionState connState) {
    switch (connState.phase) {
      case ConnectionPhase.discovering:
      case ConnectionPhase.initializing:
        state = RoomConnectionState.connecting;
      case ConnectionPhase.connecting:
      case ConnectionPhase.electing:
      case ConnectionPhase.startingHost:
        state = RoomConnectionState.connecting;
      case ConnectionPhase.connected:
      case ConnectionPhase.hostReady:
        state = RoomConnectionState.connected;
      case ConnectionPhase.reconnecting:
        state = RoomConnectionState.reconnecting;
      case ConnectionPhase.failed:
        state = RoomConnectionState.failed;
    }
  }

  Future<void> leaveRoom() async {
    debugPrint('[RoomStateNotifier] leaveRoom');
    await _roomService.leaveRoom();
    state = RoomConnectionState.disconnected;
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    super.dispose();
  }
}

enum RoomConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

extension RoomConnectionStateX on RoomConnectionState {
  bool get isActive =>
      this == RoomConnectionState.connected ||
      this == RoomConnectionState.reconnecting;
  bool get isDisconnected =>
      this == RoomConnectionState.disconnected ||
      this == RoomConnectionState.failed;

  String get label {
    switch (this) {
      case RoomConnectionState.disconnected:
        return 'Disconnected';
      case RoomConnectionState.connecting:
        return 'Connecting...';
      case RoomConnectionState.connected:
        return 'Connected';
      case RoomConnectionState.reconnecting:
        return 'Reconnecting...';
      case RoomConnectionState.failed:
        return 'Connection Failed';
    }
  }
}

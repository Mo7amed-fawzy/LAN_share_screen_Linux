import 'package:livekit_client/livekit_client.dart' as lk;
import '../domain/room_state.dart';

class RoomMapper {
  static RoomConnectionState connectionStateFrom(lk.ConnectionState state) {
    switch (state) {
      case lk.ConnectionState.disconnected:
        return RoomConnectionState.disconnected;
      case lk.ConnectionState.connecting:
      case lk.ConnectionState.reconnecting:
        return RoomConnectionState.connecting;
      case lk.ConnectionState.connected:
        return RoomConnectionState.connected;
    }
  }
}

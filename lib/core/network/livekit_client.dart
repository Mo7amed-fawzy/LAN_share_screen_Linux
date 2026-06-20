import 'dart:async';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../error/failures.dart';
import '../error/error_handler.dart';

class LiveKitClient {
  lk.Room? _room;

  lk.Room get room {
    if (_room == null) {
      throw ConnectionFailure('Not connected to any room');
    }
    return _room!;
  }

  bool get isConnected =>
      _room != null && _room!.connectionState == lk.ConnectionState.connected;

  Future<lk.Room> connect(
    String url,
    String token, {
    lk.ConnectOptions? connectOptions,
    lk.FastConnectOptions? fastConnectOptions,
  }) async {
    await lk.LiveKitClient.initialize();

    _room = lk.Room(
      roomOptions: const lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );

    try {
      await _room!.connect(
        url,
        token,
        connectOptions: connectOptions ??
            const lk.ConnectOptions(
              autoSubscribe: true,
            ),
        fastConnectOptions: fastConnectOptions,
      );
      return _room!;
    } catch (e, s) {
      unawaited(_room?.dispose());
      _room = null;
      throw handleError(e, s);
    }
  }

  Future<void> disconnect() async {
    try {
      await _room?.disconnect();
    } catch (e, s) {
      logError('Error disconnecting', e, s);
    } finally {
      unawaited(_room?.dispose());
      _room = null;
    }
  }

  void dispose() {
    unawaited(_room?.dispose());
    _room = null;
  }
}

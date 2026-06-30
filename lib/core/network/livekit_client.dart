import 'dart:async';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../error/failures.dart';
import '../error/error_handler.dart';

class LiveKitClient {
  lk.Room? _room;
  final _connectionStateController =
      StreamController<lk.ConnectionState>.broadcast();

  Stream<lk.ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

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

    _room!.addListener(_onRoomUpdate);
    _connectionStateController.add(lk.ConnectionState.connecting);

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
      _room?.removeListener(_onRoomUpdate);
      unawaited(_room?.dispose());
      _room = null;
      _connectionStateController.add(lk.ConnectionState.disconnected);
      throw handleError(e, s);
    }
  }

  void _onRoomUpdate() {
    if (_room == null) return;
    _connectionStateController.add(_room!.connectionState);
  }

  Future<void> disconnect() async {
    try {
      await _room?.disconnect();
    } catch (e, s) {
      logError('Error disconnecting', e, s);
    } finally {
      _room?.removeListener(_onRoomUpdate);
      unawaited(_room?.dispose());
      _room = null;
      _connectionStateController.add(lk.ConnectionState.disconnected);
    }
  }

  void dispose() {
    _room?.removeListener(_onRoomUpdate);
    unawaited(_room?.dispose());
    _room = null;
    _connectionStateController.close();
  }
}

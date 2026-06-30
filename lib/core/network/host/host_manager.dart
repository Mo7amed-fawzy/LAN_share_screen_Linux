import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import '../../error/failures.dart';
import '../config/network_config.dart';
import '../errors/network_failures.dart';
import '../models/server_info.dart';
import 'host_advertiser.dart';

class HostManager {
  final Logger _log = Logger('HostManager');
  final NetworkConfig _config;
  final HostAdvertiser _advertiser;

  Process? _liveKitProcess;
  bool _isHosting = false;
  String? _serverId;

  final _stateController = StreamController<HostState>.broadcast();
  final _errorController = StreamController<Failure>.broadcast();

  Stream<HostState> get stateStream => _stateController.stream;
  Stream<Failure> get errors => _errorController.stream;
  bool get isHosting => _isHosting;
  String? get serverId => _serverId;

  HostManager({
    required NetworkConfig config,
    required HostAdvertiser advertiser,
  })  : _config = config,
        _advertiser = advertiser;

  Future<bool> canHost() async {
    try {
      final result = await Process.run('which', ['livekit-server']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> startHosting(String serverId) async {
    if (_isHosting) return;
    _serverId = serverId;

    _log.info('Starting as host (serverId: $serverId)');
    _emitState(HostState.starting);

    try {
      if (!await _isPortAvailable(_config.liveKitPort)) {
        throw PortInUseFailure(
          'Port ${_config.liveKitPort} is already in use',
        );
      }

      _liveKitProcess = await Process.start(
        'livekit-server',
        [
          '--dev',
          '--bind',
          '0.0.0.0',
          '--port',
          '${_config.liveKitPort}',
        ],
        mode: ProcessStartMode.normal,
      );

      _log.info('LiveKit server started (PID: ${_liveKitProcess!.pid})');

      _liveKitProcess!.stdout.listen((data) {
        _log.fine('[livekit] ${utf8.decode(data).trim()}');
      });
      _liveKitProcess!.stderr.listen((data) {
        _log.fine('[livekit:err] ${utf8.decode(data).trim()}');
      });

      unawaited(_liveKitProcess!.exitCode.then((code) {
        _log.warning('LiveKit server (PID ${_liveKitProcess?.pid}) exited with code $code');
        if (_isHosting) {
          _emitState(HostState.failed);
          _stopHostingInternal();
        }
      }));

      await Future.delayed(const Duration(seconds: 2));

      if (!_isProcessAlive(_liveKitProcess)) {
        _log.severe('LiveKit server failed to start — process died after 2s');
        throw HostStartFailure('LiveKit server exited prematurely');
      }

      _isHosting = true;
      _advertiser.startAdvertising(serverId, _config.liveKitPort);
      _emitState(HostState.ready);
      _log.info('Host ready on port ${_config.liveKitPort}');
    } on Failure {
      _emitState(HostState.failed);
      rethrow;
    } catch (e, s) {
      _log.severe('Failed to start hosting', e, s);
      _emitState(HostState.failed);
      throw HostStartFailure('Failed to start LiveKit server: $e');
    }
  }

  Future<ServerInfo> createServerInfo(String serverId) async {
    final interfaces = await NetworkInterface.list();
    final ip = interfaces
        .expand((i) => i.addresses)
        .where((a) =>
            a.type == InternetAddressType.IPv4 &&
            !a.isLoopback &&
            !a.isLinkLocal)
        .map((a) => a.address)
        .firstOrNull ?? '127.0.0.1';

    return ServerInfo(
      serverId: serverId,
      hostName: Platform.localHostname,
      ip: ip,
      port: _config.liveKitPort,
      protocolVersion: _config.protocolVersion,
      hostPriority: 1000,
      lastSeen: DateTime.now(),
      liveKitVersion: '1.13',
    );
  }

  Future<bool> _isPortAvailable(int port) async {
    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
      );
      socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _stopHostingInternal() {
    _isHosting = false;
    _advertiser.stopAdvertising();
    _liveKitProcess?.kill();
    _liveKitProcess = null;
  }

  Future<void> stopHosting() async {
    _log.info('Stopping host');
    _emitState(HostState.stopped);
    _stopHostingInternal();
  }

  bool _isProcessAlive(Process? process) {
    if (process == null) return false;
    try {
      final result = Process.runSync('kill', ['-0', '${process.pid}']);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  void _emitState(HostState state) {
    _stateController.add(state);
  }

  void dispose() {
    stopHosting();
    _stateController.close();
    _errorController.close();
  }
}

enum HostState {
  idle,
  starting,
  ready,
  failed,
  stopped,
}

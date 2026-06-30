import 'dart:async';
import 'package:logging/logging.dart';
import '../../error/failures.dart';
import '../config/network_config.dart';
import '../discovery/discovery_service.dart';
import '../models/discovery_packet.dart';
import '../errors/network_failures.dart';

class HeartbeatService {
  final Logger _log = Logger('HeartbeatService');
  final DiscoveryService _discovery;
  final NetworkConfig _config;

  Timer? _heartbeatTimer;
  Timer? _healthCheckTimer;
  String? _nodeId;
  bool _isRunning = false;

  final _hostLostController = StreamController<void>.broadcast();
  final _heartbeatReceivedController = StreamController<String>.broadcast();
  final _errorController = StreamController<Failure>.broadcast();

  Stream<void> get hostLost => _hostLostController.stream;
  Stream<String> get heartbeatReceived => _heartbeatReceivedController.stream;
  Stream<Failure> get errors => _errorController.stream;
  bool get isRunning => _isRunning;

  HeartbeatService({
    required DiscoveryService discovery,
    required NetworkConfig config,
  })  : _discovery = discovery,
        _config = config;

  HeartbeatState _state = const HeartbeatState();

  HeartbeatState get state => _state;

  void start({
    required String nodeId,
    required bool isHost,
  }) {
    if (_isRunning) return;
    _isRunning = true;
    _nodeId = nodeId;
    _state = const HeartbeatState();

    if (isHost) {
      _heartbeatTimer = Timer.periodic(
        Duration(milliseconds: _config.heartbeatIntervalMs),
        (_) => _sendHeartbeat(),
      );
    } else {
      _healthCheckTimer = Timer.periodic(
        Duration(milliseconds: _config.heartbeatIntervalMs),
        (_) => _checkHealth(),
      );
    }
  }

  void _sendHeartbeat() {
    if (_nodeId == null) return;
    final packet = DiscoveryPacket(
      type: PacketType.heartbeat,
      nodeId: _nodeId!,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {'role': 'host'},
    );
    _discovery.sendPacket(packet);
  }

  void _checkHealth() {
    if (_state.lastHeartbeat == null) return;

    final elapsed = DateTime.now().difference(_state.lastHeartbeat!);
    if (elapsed.inMilliseconds > _config.heartbeatTimeoutMs) {
      if (_state.healthy) {
        _log.warning('Heartbeat timeout: no server contact for ${elapsed.inMilliseconds}ms');
        _state = _state.copyWith(healthy: false);
        _hostLostController.add(null);
        _errorController.add(HeartbeatLossFailure(
          'No heartbeat from server for ${elapsed.inMilliseconds}ms',
        ));
      }
      _log.fine('Still no heartbeat after ${elapsed.inMilliseconds}ms');
    }
  }

  void recordHeartbeat(String serverId) {
    _state = _state.copyWith(
      lastHeartbeat: DateTime.now(),
      lastServerId: serverId,
      healthy: true,
    );
    _heartbeatReceivedController.add(serverId);
  }

  void markHealthy() {
    _state = _state.copyWith(healthy: true);
  }

  Future<void> stop() async {
    _isRunning = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  void dispose() {
    stop();
    _hostLostController.close();
    _heartbeatReceivedController.close();
    _errorController.close();
  }
}

class HeartbeatState {
  final DateTime? lastHeartbeat;
  final String? lastServerId;
  final bool healthy;

  const HeartbeatState({
    this.lastHeartbeat,
    this.lastServerId,
    this.healthy = true,
  });

  HeartbeatState copyWith({
    DateTime? lastHeartbeat,
    String? lastServerId,
    bool? healthy,
  }) =>
      HeartbeatState(
        lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
        lastServerId: lastServerId ?? this.lastServerId,
        healthy: healthy ?? this.healthy,
      );
}

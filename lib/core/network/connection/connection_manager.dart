import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../error/failures.dart';
import '../../network/jwt_token.dart';
import '../../network/livekit_client.dart';
import '../config/network_config.dart';
import '../discovery/discovery_service.dart';
import '../election/leader_election.dart';
import '../heartbeat/heartbeat_service.dart';
import '../host/host_manager.dart';
import '../host/host_advertiser.dart';
import '../models/server_info.dart';
import '../models/node_info.dart';
import '../models/discovery_packet.dart';
import '../reconnection/reconnection_service.dart';
import 'connection_state.dart';

class ConnectionManager {
  final Logger _log = Logger('ConnectionManager');
  final NetworkConfig _config;
  final DiscoveryService _discovery;
  final LeaderElection _election;
  final HeartbeatService _heartbeat;
  final HostManager _hostManager;
  final HostAdvertiser _hostAdvertiser;
  final ReconnectionService _reconnector;
  final LiveKitClient _liveKitClient;

  NodeInfo? _nodeInfo;
  ServerInfo? _connectedServer;
  final _stateController = StreamController<ConnectionState>.broadcast();
  final _errorController = StreamController<Failure>.broadcast();

  bool _initialized = false;
  bool _disposed = false;
  StreamSubscription? _discoverySub;
  StreamSubscription? _discoveryCompleteSub;
  StreamSubscription? _discoveryErrorSub;
  StreamSubscription? _discoveryPacketSub;
  StreamSubscription? _hostSub;
  StreamSubscription? _hostErrorSub;
  StreamSubscription? _heartbeatSub;
  StreamSubscription? _heartbeatErrorSub;
  StreamSubscription? _electionSub;
  StreamSubscription? _electionErrorSub;
  StreamSubscription? _reconnectSub;
  StreamSubscription? _maxAttemptsSub;

  ConnectionState _state = const ConnectionState(phase: ConnectionPhase.initializing);

  Stream<ConnectionState> get stateStream => _stateController.stream;
  Stream<Failure> get errors => _errorController.stream;
  ConnectionState get currentState => _state;
  ServerInfo? get connectedServer => _connectedServer;
  NodeInfo? get nodeInfo => _nodeInfo;
  bool get isConnected => _state.isConnected;
  bool get isHosting => _state.phase == ConnectionPhase.hostReady;
  LiveKitClient get liveKitClient => _liveKitClient;

  ConnectionManager({
    required NetworkConfig config,
    required DiscoveryService discovery,
    required LeaderElection election,
    required HeartbeatService heartbeat,
    required HostManager hostManager,
    required HostAdvertiser hostAdvertiser,
    required ReconnectionService reconnector,
    required LiveKitClient liveKitClient,
  })  : _config = config,
        _discovery = discovery,
        _election = election,
        _heartbeat = heartbeat,
        _hostManager = hostManager,
        _hostAdvertiser = hostAdvertiser,
        _reconnector = reconnector,
        _liveKitClient = liveKitClient;

  Future<void> initialize({
    NodeInfo? nodeInfo,
  }) async {
    if (_initialized) return;
    _initialized = true;

    _nodeInfo = nodeInfo ?? await NodeInfo.create(
      nodeId: 'user_${Random().nextInt(999999)}',
    );

    _hostAdvertiser.attachDiscovery(_discovery);
    _configureElection();

    _setupSubscriptions();

    _reconnector.start();
    _emitState(const ConnectionState(phase: ConnectionPhase.initializing));

    await _startDiscovery();
  }

  void _configureElection() {
    _election.configure(
      nodeId: _nodeInfo!.nodeId,
      priority: _nodeInfo!.priority,
    );

    _electionSub = _election.results.listen(_onElectionResult);
    _electionErrorSub = _election.errors.listen((e) {
      _errorController.add(e);
    });
  }

  void _setupSubscriptions() {
    _discoverySub = _discovery.serverFound.listen(_onServerFound);
    _discoveryCompleteSub = _discovery.discoveryComplete.listen((_) {
      _onDiscoveryComplete();
    });
    _discoveryErrorSub = _discovery.errors.listen((e) {
      _errorController.add(e);
    });
    _discoveryPacketSub = _discovery.onPacket.listen(_onDiscoveryPacket);

    _hostSub = _hostManager.stateStream.listen(_onHostState);
    _hostErrorSub = _hostManager.errors.listen((e) {
      _errorController.add(e);
    });

    _heartbeatSub = _heartbeat.hostLost.listen((_) {
      _onHostLost();
    });
    _heartbeatErrorSub = _heartbeat.errors.listen((e) {
      _errorController.add(e);
    });

    _reconnectSub = _reconnector.reconnectTriggered.listen((_) {
      _onReconnectTriggered();
    });
    _maxAttemptsSub = _reconnector.maxAttemptsReached.listen((_) {
      _onMaxReconnectAttempts();
    });
  }

  Future<void> _startDiscovery() async {
    _emitState(const ConnectionState(phase: ConnectionPhase.discovering));
    await _discovery.startDiscovery();
  }

  Timer? _discoveryTimer;

  void _onDiscoveryPacket(DiscoveryPacket packet) {
    switch (packet.type) {
      case PacketType.election:
      case PacketType.electionAck:
      case PacketType.coordinator:
        handleDiscoveryPacket(packet);
      case PacketType.heartbeat:
        _heartbeat.recordHeartbeat(packet.nodeId);
      case PacketType.advertisement:
        break;
      case PacketType.query:
        break;
    }
  }

  void _onServerFound(ServerInfo server) {
    if (_state.isConnected || _state.phase == ConnectionPhase.connecting) return;

    _log.info('Server found: ${server.hostName} at ${server.url}');
    _connectedServer = server;
    _discoveryTimer?.cancel();
    _election.reset();

    _connectToServer(server);
  }

  void _onDiscoveryComplete() {
    if (_state.isConnected) return;

    _log.info('Discovery timed out — no server found, starting election');
    _emitState(const ConnectionState(phase: ConnectionPhase.electing));
    _startElection();
  }

  Future<void> _connectToServer(ServerInfo server) async {
    _emitState(const ConnectionState(phase: ConnectionPhase.connecting));

    try {
      final token = JwtToken.create(
        roomName: _config.defaultRoomName,
        participantIdentity: _nodeInfo!.nodeId,
      );

      await _liveKitClient.connect(
        server.url,
        token,
      );

      _connectedServer = server;
      _reconnector.reset();

      _heartbeat.start(
        nodeId: _nodeInfo!.nodeId,
        isHost: false,
      );

      _emitState(ConnectionState(
        phase: ConnectionPhase.connected,
        lastConnectedAt: DateTime.now(),
      ));

      _log.info('Connected to LiveKit server at ${server.url}');
    } catch (e) {
      _log.severe('Failed to connect to server', e);
      _connectedServer = null;

      if (e is Failure) {
        _errorController.add(e);
      }

      _onServerConnectionFailed();
    }
  }

  void _onServerConnectionFailed() {
    _emitState(const ConnectionState(
      phase: ConnectionPhase.failed,
      lastError: 'Connection failed',
    ));
    _reconnector.scheduleReconnect();
  }

  void _onReconnectTriggered() {
    _log.info('Reconnect triggered, restarting discovery');
    _emitState(ConnectionState(
      phase: ConnectionPhase.discovering,
      attemptCount: _reconnector.attemptCount,
    ));
    _discovery.restartDiscovery();
  }

  void _onMaxReconnectAttempts() {
    _log.severe('Max reconnect attempts reached');
    _emitState(ConnectionState(
      phase: ConnectionPhase.failed,
      lastError: 'Max reconnection attempts (${_config.maxReconnectionAttempts}) reached',
    ));
    _errorController.add(ConnectionFailure(
      'Failed to reconnect after ${_config.maxReconnectionAttempts} attempts',
    ));
  }

  Future<void> _startElection() async {
    final canHost = await _hostManager.canHost();
    if (!canHost) {
      _log.warning('Cannot host — participating with priority 0');
      _election.configure(
        nodeId: _nodeInfo!.nodeId,
        priority: 0,
      );
    }

    _election.electLeader().then((elected) {
      if (elected) {
        if (canHost) {
          _onElectedAsHost();
        } else {
          _log.severe('Cannot host and no host-capable node found');
          _emitState(ConnectionState(
            phase: ConnectionPhase.failed,
            lastError: 'No host-capable node available on the network',
          ));
        }
      } else {
        _onElectionLost();
      }
    });
  }

  void _onElectionResult(ElectionResult result) {
    if (_state.phase == ConnectionPhase.startingHost ||
        _state.phase == ConnectionPhase.hostReady) {
      return;
    }
    _log.info('Election result: winner=${result.winnerId} isSelf=${result.isSelf}');
    if (result.isSelf) {
      _onElectedAsHost();
    } else {
      _onElectionLost();
    }
  }

  void _onElectedAsHost() async {
    _emitState(const ConnectionState(phase: ConnectionPhase.startingHost));

    try {
      await _hostManager.startHosting(_nodeInfo!.nodeId);

      final token = JwtToken.create(
        roomName: _config.defaultRoomName,
        participantIdentity: _nodeInfo!.nodeId,
      );

      await _liveKitClient.connect(
        'ws://127.0.0.1:${_config.liveKitPort}',
        token,
      );

      _heartbeat.start(nodeId: _nodeInfo!.nodeId, isHost: true);

      _emitState(ConnectionState(
        phase: ConnectionPhase.hostReady,
        lastConnectedAt: DateTime.now(),
      ));

      _log.info('Host ready — server running and connected');
    } catch (e, s) {
      _log.severe('Failed to become host', e, s);
      _emitState(ConnectionState(
        phase: ConnectionPhase.failed,
        lastError: 'Failed to become host: $e',
      ));
      if (e is Failure) _errorController.add(e);
    }
  }

  void _onElectionLost() {
    _log.info('Lost election — waiting for coordinator/advertisement');
    _emitState(const ConnectionState(phase: ConnectionPhase.discovering));
  }

  void _onHostState(HostState hostState) {
    switch (hostState) {
      case HostState.failed:
        _onHostFailed();
      case HostState.stopped:
        if (_state.phase == ConnectionPhase.hostReady) {
          _onHostLost();
        }
      default:
        break;
    }
  }

  void _onHostFailed() {
    _log.severe('Host failed — restarting discovery');
    _emitState(const ConnectionState(phase: ConnectionPhase.failed, lastError: 'Host failed'));
    _reconnector.scheduleReconnect();
  }

  void _onHostLost() {
    _log.warning('Host lost — restarting discovery');
    _heartbeat.stop();
    _liveKitClient.disconnect();

    if (isHosting) {
      _hostManager.stopHosting();
    }

    _emitState(const ConnectionState(phase: ConnectionPhase.discovering));
    _reconnector.reset();
    _discovery.restartDiscovery();
  }

  Future<lk.Room?> connectToServer(ServerInfo server) async {
    final token = JwtToken.create(
      roomName: _config.defaultRoomName,
      participantIdentity: _nodeInfo!.nodeId,
    );
    try {
      return await _liveKitClient.connect(server.url, token);
    } catch (e) {
      _errorController.add(ConnectionFailure('Failed to connect: $e'));
      return null;
    }
  }

  void handleDiscoveryPacket(DiscoveryPacket packet) {
    switch (packet.type) {
      case PacketType.election:
        _election.handleElection(packet);
      case PacketType.electionAck:
        _election.handleElectionAck(packet);
      case PacketType.coordinator:
        _election.handleCoordinator(packet);
      default:
        break;
    }
  }

  Future<void> disconnect() async {
    _log.info('Disconnecting');
    await _heartbeat.stop();
    await _reconnector.stop();
    await _liveKitClient.disconnect();
    await _hostManager.stopHosting();
    await _discovery.stopDiscovery();
    _emitState(const ConnectionState(phase: ConnectionPhase.initializing));
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await disconnect();

    await _discoverySub?.cancel();
    await _discoveryCompleteSub?.cancel();
    await _discoveryErrorSub?.cancel();
    await _discoveryPacketSub?.cancel();
    await _hostSub?.cancel();
    await _hostErrorSub?.cancel();
    await _heartbeatSub?.cancel();
    await _heartbeatErrorSub?.cancel();
    await _electionSub?.cancel();
    await _electionErrorSub?.cancel();
    await _reconnectSub?.cancel();
    await _maxAttemptsSub?.cancel();

    _discoveryTimer?.cancel();

    _discovery.dispose();
    _election.dispose();
    _heartbeat.dispose();
    _hostManager.dispose();
    _reconnector.dispose();

    _stateController.close();
    _errorController.close();
  }

  void _emitState(ConnectionState state) {
    _state = state;
    if (!_disposed) {
      _stateController.add(state);
    }
  }
}

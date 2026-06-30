import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import '../../error/failures.dart';
import '../config/network_config.dart';
import '../models/discovery_packet.dart';
import '../models/server_info.dart';
import '../errors/network_failures.dart';

class DiscoveryService {
  final Logger _log = Logger('DiscoveryService');
  final NetworkConfig _config;

  RawDatagramSocket? _socket;
  StreamSubscription<RawSocketEvent>? _subscription;
  Timer? _advertisementTimer;
  Timer? _discoveryTimer;

  final _serverController = StreamController<ServerInfo>.broadcast();
  final _discoveryCompleteController = StreamController<void>.broadcast();
  final _errorController = StreamController<Failure>.broadcast();
  final _packetController = StreamController<DiscoveryPacket>.broadcast();

  bool _isRunning = false;
  bool _discoveryTimedOut = false;

  Stream<ServerInfo> get serverFound => _serverController.stream;
  Stream<void> get discoveryComplete => _discoveryCompleteController.stream;
  Stream<Failure> get errors => _errorController.stream;
  Stream<DiscoveryPacket> get onPacket => _packetController.stream;
  bool get isRunning => _isRunning;
  bool get discoveryTimedOut => _discoveryTimedOut;

  DiscoveryService({NetworkConfig? config})
      : _config = config ?? NetworkConfig.production;

  Future<void> startDiscovery() async {
    if (_isRunning) return;
    _isRunning = true;
    _discoveryTimedOut = false;

    _log.info('Binding UDP socket on port ${_config.multicastPort}');

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        _config.multicastPort,
        reuseAddress: true,
        reusePort: true,
      );

      _socket!.joinMulticast(_config.multicastAddress);
      _socket!.broadcastEnabled = true;

      _log.info('Socket bound, joined multicast ${_config.multicastGroup}');

      _subscription = _socket!.listen(_onPacket);

      _sendQuery();

      _log.info('Discovery started, timeout=${_config.discoveryTimeoutMs}ms');

      _discoveryTimer = Timer(
        Duration(milliseconds: _config.discoveryTimeoutMs),
        _onDiscoveryTimeout,
      );
    } catch (e, s) {
      _isRunning = false;
      _log.severe('Failed to start discovery', e, s);
      _errorController.add(DiscoveryFailure('Failed to bind socket: $e'));
    }
  }

  void _onPacket(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;

    try {
      final json = jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
      final packet = DiscoveryPacket.fromJson(json);

      _log.info('Received ${packet.type} from ${datagram.address.address}:${datagram.port}');

      switch (packet.type) {
        case PacketType.query:
          break;
        case PacketType.advertisement:
          _onAdvertisement(packet, datagram.address);
          break;
        case PacketType.heartbeat:
        case PacketType.election:
        case PacketType.coordinator:
        case PacketType.electionAck:
          break;
      }

      if (packet.type != PacketType.query) {
        _packetController.add(packet);
      }
    } catch (e) {
      _log.fine('Ignoring malformed discovery packet from ${datagram.address.address}: $e');
    }
  }

  void _onAdvertisement(DiscoveryPacket packet, InternetAddress source) {
    final data = packet.dataMap;
    final version = data['protocolVersion'] as String? ?? '';
    final serverId = data['serverId'] as String? ?? packet.nodeId;

    if (version != _config.protocolVersion) {
      _errorController.add(ProtocolVersionMismatch(
        expected: _config.protocolVersion,
        received: version,
      ));
      return;
    }

    final server = ServerInfo(
      serverId: serverId,
      hostName: data['hostName'] as String? ?? source.address,
      ip: source.address,
      port: (data['port'] as num?)?.toInt() ?? _config.liveKitPort,
      protocolVersion: version,
      hostPriority: (data['hostPriority'] as num?)?.toInt() ?? 0,
      lastSeen: DateTime.now(),
      liveKitVersion: data['liveKitVersion'] as String?,
    );

    _serverController.add(server);
  }

  void _onDiscoveryTimeout() {
    _discoveryTimedOut = true;
    _discoveryCompleteController.add(null);
  }

  void sendAdvertisement(ServerInfo server) {
    final packet = DiscoveryPacket(
      type: PacketType.advertisement,
      nodeId: server.serverId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {
        'data': {
          'serverId': server.serverId,
          'hostName': server.hostName,
          'port': server.port,
          'protocolVersion': server.protocolVersion,
          'hostPriority': server.hostPriority,
          'liveKitVersion': server.liveKitVersion,
        },
      },
    );
    _sendPacket(packet);
  }

  void _sendQuery() {
    final packet = DiscoveryPacket(
      type: PacketType.query,
      nodeId: 'discoverer',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    _sendPacket(packet);
  }

  void sendPacket(DiscoveryPacket packet) {
    _sendPacket(packet);
  }

  void _sendPacket(DiscoveryPacket packet) {
    if (_socket == null) return;
    try {
      final data = utf8.encode(jsonEncode(packet.toJson()));
      _socket!.send(data, _config.multicastAddress, _config.multicastPort);
      _socket!.send(data, InternetAddress('127.0.0.1'), _config.multicastPort);
    } catch (e) {
      _log.fine('Failed to send packet: $e');
    }
  }

  Future<void> stopDiscovery() async {
    _isRunning = false;
    _discoveryTimedOut = false;
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _advertisementTimer?.cancel();
    _advertisementTimer = null;
    _subscription?.cancel();
    _subscription = null;
    _socket?.close();
    _socket = null;
  }

  Future<void> restartDiscovery() async {
    await stopDiscovery();
    await startDiscovery();
  }

  void dispose() {
    stopDiscovery();
    _serverController.close();
    _discoveryCompleteController.close();
    _errorController.close();
    _packetController.close();
  }
}

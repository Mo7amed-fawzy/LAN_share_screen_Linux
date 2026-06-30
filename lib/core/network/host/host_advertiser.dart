import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import '../config/network_config.dart';
import '../discovery/discovery_service.dart';
import '../models/server_info.dart';

class HostAdvertiser {
  final Logger _log = Logger('HostAdvertiser');
  final NetworkConfig _config;
  String? _localIp;
  bool _ipResolved = false;
  DiscoveryService? _discovery;

  Timer? _advertisementTimer;
  bool _isAdvertising = false;

  bool get isAdvertising => _isAdvertising;

  HostAdvertiser({required NetworkConfig config}) : _config = config;

  void attachDiscovery(DiscoveryService discovery) {
    _discovery = discovery;
  }

  void startAdvertising(String serverId, int port) {
    if (_isAdvertising) return;
    _isAdvertising = true;

    _resolveLocalIp();

    final serverName = Platform.localHostname;

    _advertisementTimer = Timer.periodic(
      Duration(milliseconds: _config.advertisementIntervalMs),
      (_) {
        if (_discovery == null) return;
        final effectiveIp = _localIp ?? '127.0.0.1';
        final server = ServerInfo(
          serverId: serverId,
          hostName: serverName,
          ip: effectiveIp,
          port: port,
          protocolVersion: _config.protocolVersion,
          hostPriority: 1000,
          lastSeen: DateTime.now(),
        );
        _discovery!.sendAdvertisement(server);
      },
    );

    _log.info('Started advertising server $serverId every ${_config.advertisementIntervalMs}ms');
  }

  void stopAdvertising() {
    _isAdvertising = false;
    _advertisementTimer?.cancel();
    _advertisementTimer = null;
  }

  Future<void> _resolveLocalIp() async {
    if (_ipResolved) return;
    _ipResolved = true;
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              !addr.isLinkLocal) {
            _localIp = addr.address;
            return;
          }
        }
      }
    } catch (_) {
      _localIp = '127.0.0.1';
    }
  }
}

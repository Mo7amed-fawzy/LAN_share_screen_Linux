import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/core/network/config/network_config.dart';

void main() {
  group('NetworkConfig', () {
    test('production config has expected defaults', () {
      final config = NetworkConfig.production;

      expect(config.multicastGroup, '239.255.100.100');
      expect(config.multicastPort, 57000);
      expect(config.discoveryTimeoutMs, 5000);
      expect(config.discoveryIntervalMs, 2000);
      expect(config.advertisementIntervalMs, 3000);
      expect(config.heartbeatIntervalMs, 2000);
      expect(config.heartbeatTimeoutMs, 8000);
      expect(config.electionTimeoutMs, 3000);
      expect(config.electionJitterMaxMs, 2000);
      expect(config.maxReconnectionAttempts, 10);
      expect(config.liveKitPort, 7880);
      expect(config.defaultRoomName, 'screen_share');
      expect(config.protocolVersion, '1.0');
      expect(config.packetTtl, 1);
    });

    test('copyWith overrides specified fields', () {
      final original = NetworkConfig.production;
      final modified = original.copyWith(
        discoveryTimeoutMs: 10000,
        heartbeatIntervalMs: 5000,
        maxReconnectionAttempts: 5,
      );

      expect(modified.discoveryTimeoutMs, 10000);
      expect(modified.heartbeatIntervalMs, 5000);
      expect(modified.maxReconnectionAttempts, 5);
      expect(modified.multicastPort, original.multicastPort);
      expect(modified.liveKitPort, original.liveKitPort);
    });

    test('multicastAddress returns InternetAddress', () {
      final config = NetworkConfig.production;
      final addr = config.multicastAddress;
      expect(addr.address, '239.255.100.100');
    });

    test('toString includes key config values', () {
      final config = NetworkConfig.production;
      final str = config.toString();
      expect(str, contains('239.255.100.100'));
      expect(str, contains('57000'));
      expect(str, contains('5000ms'));
    });
  });
}

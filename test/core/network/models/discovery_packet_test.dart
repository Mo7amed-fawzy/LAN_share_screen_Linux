import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/core/network/models/discovery_packet.dart';

void main() {
  group('DiscoveryPacket', () {
    test('toJson produces correct map', () {
      final packet = DiscoveryPacket(
        type: PacketType.advertisement,
        nodeId: 'node-1',
        timestamp: 1234567890,
        payload: {
          'data': {
            'serverId': 'server-1',
            'port': 7880,
          },
        },
      );

      final json = packet.toJson();

      expect(json['type'], 'advertisement');
      expect(json['nodeId'], 'node-1');
      expect(json['timestamp'], 1234567890);
      expect(json['data']['serverId'], 'server-1');
    });

    test('fromJson parses correctly', () {
      final json = {
        'type': 'heartbeat',
        'nodeId': 'node-2',
        'timestamp': 987654321,
        'role': 'host',
      };

      final packet = DiscoveryPacket.fromJson(json);

      expect(packet.type, PacketType.heartbeat);
      expect(packet.nodeId, 'node-2');
      expect(packet.timestamp, 987654321);
      expect(packet.stringField, null);
    });

    test('fromJson defaults to query for unknown type', () {
      final json = {
        'type': 'unknown_type',
        'nodeId': 'node-3',
        'timestamp': 0,
      };

      final packet = DiscoveryPacket.fromJson(json);

      expect(packet.type, PacketType.query);
    });

    test('dataMap extracts nested data', () {
      final packet = DiscoveryPacket(
        type: PacketType.advertisement,
        nodeId: 'node-4',
        timestamp: 0,
        payload: {
          'data': {
            'serverId': 'srv-1',
            'port': 7880,
          },
        },
      );

      expect(packet.dataMap['serverId'], 'srv-1');
      expect(packet.dataMap['port'], 7880);
    });

    test('round-trip serialization preserves fields', () {
      final original = DiscoveryPacket(
        type: PacketType.coordinator,
        nodeId: 'coordinator-1',
        timestamp: 12345,
        payload: {
          'coordinatorId': 'coordinator-1',
          'data': {'hostName': 'test-machine'},
        },
      );

      final json = original.toJson();
      final restored = DiscoveryPacket.fromJson(json);

      expect(restored.type, original.type);
      expect(restored.nodeId, original.nodeId);
      expect(restored.timestamp, original.timestamp);
      expect(restored.dataMap['hostName'], 'test-machine');
    });
  });
}

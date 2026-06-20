import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/features/room/domain/room_state.dart';

void main() {
  group('RoomConnectionState', () {
    test('isActive returns true for connected', () {
      expect(RoomConnectionState.connected.isActive, isTrue);
    });

    test('isActive returns true for reconnecting', () {
      expect(RoomConnectionState.reconnecting.isActive, isTrue);
    });

    test('isActive returns false for disconnected', () {
      expect(RoomConnectionState.disconnected.isActive, isFalse);
    });

    test('isActive returns false for failed', () {
      expect(RoomConnectionState.failed.isActive, isFalse);
    });

    test('isDisconnected returns true for failed', () {
      expect(RoomConnectionState.failed.isDisconnected, isTrue);
    });

    test('labels are not empty', () {
      for (final state in RoomConnectionState.values) {
        expect(state.label.isNotEmpty, isTrue);
      }
    });
  });
}

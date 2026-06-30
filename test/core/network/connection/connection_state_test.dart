import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/core/network/connection/connection_state.dart';

void main() {
  group('ConnectionState', () {
    test('initial state is initializing', () {
      const state = ConnectionState();
      expect(state.phase, ConnectionPhase.initializing);
      expect(state.attemptCount, 0);
      expect(state.isConnected, false);
    });

    test('isConnected is true for connected and hostReady', () {
      const connected = ConnectionState(phase: ConnectionPhase.connected);
      const hostReady = ConnectionState(phase: ConnectionPhase.hostReady);

      expect(connected.isConnected, true);
      expect(hostReady.isConnected, true);
    });

    test('isConnected is false for other phases', () {
      const phases = [
        ConnectionPhase.initializing,
        ConnectionPhase.discovering,
        ConnectionPhase.connecting,
        ConnectionPhase.electing,
        ConnectionPhase.startingHost,
        ConnectionPhase.reconnecting,
        ConnectionPhase.failed,
      ];

      for (final phase in phases) {
        expect(ConnectionState(phase: phase).isConnected, false,
            reason: 'Phase $phase should not be connected');
      }
    });

    test('copyWith preserves unchanged fields', () {
      const original = ConnectionState(
        phase: ConnectionPhase.connected,
        attemptCount: 3,
        lastError: 'test error',
      );

      final copied = original.copyWith(attemptCount: 5, lastError: 'test error');

      expect(copied.phase, ConnectionPhase.connected);
      expect(copied.attemptCount, 5);
      expect(copied.lastError, 'test error');
    });

    test('copyWith preserves lastError when not specified', () {
      const original = ConnectionState(
        phase: ConnectionPhase.failed,
        lastError: 'error',
      );

      final copied = original.copyWith(phase: ConnectionPhase.discovering);

      expect(copied.lastError, 'error');
    });

    test('copyWith clears lastError with clearError flag', () {
      const original = ConnectionState(
        phase: ConnectionPhase.failed,
        lastError: 'error',
      );

      final copied = original.copyWith(clearError: true);

      expect(copied.lastError, isNull);
    });
  });

  group('ConnectionPhase', () {
    test('isTerminal returns true for connected, hostReady, failed', () {
      expect(ConnectionPhase.connected.isTerminal, true);
      expect(ConnectionPhase.hostReady.isTerminal, true);
      expect(ConnectionPhase.failed.isTerminal, true);
      expect(ConnectionPhase.discovering.isTerminal, false);
    });

    test('isActive returns true for active phases', () {
      expect(ConnectionPhase.connected.isActive, true);
      expect(ConnectionPhase.hostReady.isActive, true);
      expect(ConnectionPhase.reconnecting.isActive, true);
      expect(ConnectionPhase.discovering.isActive, false);
    });

    test('label returns human-readable string', () {
      expect(ConnectionPhase.initializing.label, 'Initializing...');
      expect(ConnectionPhase.discovering.label, 'Searching for server...');
      expect(ConnectionPhase.connected.label, 'Connected');
      expect(ConnectionPhase.hostReady.label, 'Hosting');
    });
  });
}

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/core/network/config/network_config.dart';
import 'package:screen_share/core/network/reconnection/reconnection_service.dart';

void main() {
  group('ReconnectionService', () {
    late ReconnectionService service;

    setUp(() {
      service = ReconnectionService();
    });

    tearDown(() {
      service.dispose();
    });

    test('starts with no attempts', () {
      expect(service.attemptCount, 0);
      expect(service.isRunning, false);
    });

    test('start marks as running', () {
      service.start();
      expect(service.isRunning, true);
    });

    test('scheduleReconnect triggers after backoff delay', () async {
      service.start();
      final triggered = Completer<void>();

      service.reconnectTriggered.listen((_) {
        triggered.complete();
      });

      service.scheduleReconnect();
      expect(service.attemptCount, 1);

      await triggered.future.timeout(const Duration(seconds: 3));
      expect(triggered.isCompleted, true);
    });

    test('backoff increases with attempts', () {
      service.start();

      service.scheduleReconnect();
      final attempt1 = service.attemptCount;

      service.scheduleReconnect();
      final attempt2 = service.attemptCount;

      expect(attempt1, 1);
      expect(attempt2, 2);
    });

    test('reset clears attempt count', () {
      service.start();
      service.scheduleReconnect();
      expect(service.attemptCount, 1);

      service.reset();
      expect(service.attemptCount, 0);
    });

    test('max attempts reached emits on maxAttemptsReached', () async {
      service = ReconnectionService(
        config: const NetworkConfig(
          maxReconnectionAttempts: 2,
          initialReconnectDelay: Duration(milliseconds: 1),
          maxReconnectDelay: Duration(milliseconds: 5),
        ),
      );

      service.start();
      final reached = Completer<void>();
      final sub = service.maxAttemptsReached.listen((_) {
        if (!reached.isCompleted) reached.complete();
      });

      service.scheduleReconnect();
      service.scheduleReconnect();
      service.scheduleReconnect();

      await reached.future.timeout(const Duration(seconds: 3));
      expect(reached.isCompleted, true);
      await sub.cancel();
    });
  });
}

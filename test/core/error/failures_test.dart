import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/core/error/failures.dart';

void main() {
  group('Failure', () {
    test('NetworkFailure has correct message', () {
      final failure = NetworkFailure('test error');
      expect(failure.message, 'test error');
      expect(failure, isA<Failure>());
    });

    test('ConnectionFailure provides default message', () {
      final failure = ConnectionFailure();
      expect(failure.message, 'Failed to connect to room');
      expect(failure, isA<NetworkFailure>());
    });

    test('ScreenSourceFailure provides default message', () {
      final failure = ScreenSourceFailure();
      expect(failure.message, contains('screen source'));
    });

    test('UnknownFailure provides default message', () {
      final failure = UnknownFailure();
      expect(failure.message, 'An unknown error occurred');
    });

    test('Failure is typed correctly', () {
      final failure = NetworkFailure('error');
      expect(failure.message, 'error');
      expect(failure, isA<NetworkFailure>());
      expect(failure, isA<Failure>());
    });
  });
}

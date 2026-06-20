import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/core/error/error_handler.dart';
import 'package:screen_share/core/error/failures.dart';

void main() {
  group('handleError', () {
    test('returns Failure directly', () {
      final failure = ConnectionFailure();
      expect(handleError(failure), same(failure));
    });

    test('maps connection errors to ConnectionFailure', () {
      final result = handleError(Exception('connection refused'));
      expect(result, isA<ConnectionFailure>());
    });

    test('maps token errors to TokenFailure', () {
      final result = handleError(Exception('token expired'));
      expect(result, isA<TokenFailure>());
    });

    test('maps capture errors to ScreenSourceFailure', () {
      final result = handleError(Exception('capture failed'));
      expect(result, isA<ScreenSourceFailure>());
    });

    test('maps unknown errors to UnknownFailure', () {
      final result = handleError(Exception('something else'));
      expect(result, isA<UnknownFailure>());
    });
  });
}

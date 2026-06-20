import 'package:logging/logging.dart';
import 'failures.dart';

final Logger _log = Logger('ErrorHandler');

Failure handleError(Object error, [StackTrace? stack]) {
  _log.severe('Handling error: $error', error, stack);

  if (error is Failure) return error;

  final message = error.toString();

  if (message.contains('connection') || message.contains('connect')) {
    return ConnectionFailure(message);
  }
  if (message.contains('token') || message.contains('unauthorized')) {
    return TokenFailure(message);
  }
  if (message.contains('capture') || message.contains('source')) {
    return ScreenSourceFailure(message);
  }
  if (message.contains('publish') || message.contains('track')) {
    return PublishFailure(message);
  }
  if (message.contains('subscribe')) {
    return SubscribeFailure(message);
  }

  return UnknownFailure(message);
}

void logError(String message, [Object? error, StackTrace? stack]) {
  _log.severe(message, error, stack);
}

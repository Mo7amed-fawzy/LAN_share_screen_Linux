import 'package:logging/logging.dart';
import 'failures.dart';
import '../network/errors/network_failures.dart';

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
  if (message.contains('discovery') || message.contains('multicast')) {
    return DiscoveryFailure(message);
  }
  if (message.contains('host') || message.contains('server')) {
    return HostStartFailure(message);
  }
  if (message.contains('heartbeat') || message.contains('keepalive')) {
    return HeartbeatLossFailure(message);
  }
  if (message.contains('election')) {
    return ElectionFailure(message);
  }
  if (message.contains('port')) {
    return PortInUseFailure(message);
  }
  if (message.contains('protocol') || message.contains('version')) {
    return ProtocolVersionMismatch(expected: '', received: message);
  }

  return UnknownFailure(message);
}

void logError(String message, [Object? error, StackTrace? stack]) {
  _log.severe(message, error, stack);
}

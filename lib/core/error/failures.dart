sealed class Failure {
  final String message;

  const Failure(this.message);

  @override
  String toString() => 'Failure: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ConnectionFailure extends NetworkFailure {
  const ConnectionFailure([String message = 'Failed to connect to room'])
      : super(message);
}

class DisconnectionFailure extends NetworkFailure {
  const DisconnectionFailure(
      [String message = 'Unexpected disconnection from room'])
      : super(message);
}

class TokenFailure extends NetworkFailure {
  const TokenFailure([String message = 'Failed to obtain access token'])
      : super(message);
}

class CaptureFailure extends Failure {
  const CaptureFailure(super.message);
}

class ScreenSourceFailure extends CaptureFailure {
  const ScreenSourceFailure(
      [String message = 'No screen source available or permission denied'])
      : super(message);
}

class TrackFailure extends Failure {
  const TrackFailure(super.message);
}

class PublishFailure extends TrackFailure {
  const PublishFailure([String message = 'Failed to publish video track'])
      : super(message);
}

class SubscribeFailure extends TrackFailure {
  const SubscribeFailure([String message = 'Failed to subscribe to track'])
      : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'An unknown error occurred'])
      : super(message);
}

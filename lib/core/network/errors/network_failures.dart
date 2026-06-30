import '../../error/failures.dart';

class DiscoveryFailure extends NetworkFailure {
  const DiscoveryFailure([String message = 'Server discovery failed'])
      : super(message);
}

class HostStartFailure extends NetworkFailure {
  const HostStartFailure([String message = 'Failed to start local server'])
      : super(message);
}

class ElectionFailure extends NetworkFailure {
  const ElectionFailure([String message = 'Leader election failed'])
      : super(message);
}

class HeartbeatLossFailure extends DisconnectionFailure {
  const HeartbeatLossFailure(
      [String message = 'Host heartbeat lost - connection timed out'])
      : super(message);
}

class ProtocolVersionMismatch extends NetworkFailure {
  final String expected;
  final String received;

  const ProtocolVersionMismatch({
    required this.expected,
    required this.received,
    String? message,
  }) : super(message ?? 'Protocol version mismatch: expected $expected, got $received');
}

class DuplicateServerFailure extends NetworkFailure {
  const DuplicateServerFailure(
      [String message = 'Duplicate server detected on network'])
      : super(message);
}

class PortInUseFailure extends HostStartFailure {
  const PortInUseFailure([String message = 'Port already in use'])
      : super(message);
}

class InvalidAdvertisementFailure extends NetworkFailure {
  const InvalidAdvertisementFailure(
      [String message = 'Received malformed server advertisement'])
      : super(message);
}

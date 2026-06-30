enum ConnectionPhase {
  initializing,
  discovering,
  connecting,
  connected,
  electing,
  startingHost,
  hostReady,
  reconnecting,
  failed,
}

extension ConnectionPhaseX on ConnectionPhase {
  bool get isTerminal =>
      this == ConnectionPhase.connected ||
      this == ConnectionPhase.hostReady ||
      this == ConnectionPhase.failed;

  bool get isActive =>
      this == ConnectionPhase.connected ||
      this == ConnectionPhase.hostReady ||
      this == ConnectionPhase.reconnecting;

  String get label {
    switch (this) {
      case ConnectionPhase.initializing:
        return 'Initializing...';
      case ConnectionPhase.discovering:
        return 'Searching for server...';
      case ConnectionPhase.connecting:
        return 'Connecting...';
      case ConnectionPhase.connected:
        return 'Connected';
      case ConnectionPhase.electing:
        return 'Electing host...';
      case ConnectionPhase.startingHost:
        return 'Starting local server...';
      case ConnectionPhase.hostReady:
        return 'Hosting';
      case ConnectionPhase.reconnecting:
        return 'Reconnecting...';
      case ConnectionPhase.failed:
        return 'Connection Failed';
    }
  }
}

class ConnectionState {
  final ConnectionPhase phase;
  final int attemptCount;
  final String? lastError;
  final DateTime? lastConnectedAt;

  const ConnectionState({
    this.phase = ConnectionPhase.initializing,
    this.attemptCount = 0,
    this.lastError,
    this.lastConnectedAt,
  });

  bool get isConnected =>
      phase == ConnectionPhase.connected ||
      phase == ConnectionPhase.hostReady;

  ConnectionState copyWith({
    ConnectionPhase? phase,
    int? attemptCount,
    String? lastError,
    bool clearError = false,
    DateTime? lastConnectedAt,
  }) =>
      ConnectionState(
        phase: phase ?? this.phase,
        attemptCount: attemptCount ?? this.attemptCount,
        lastError: clearError ? null : (lastError ?? this.lastError),
        lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      );

  @override
  String toString() => 'ConnectionState(${phase.name}, attempt=$attemptCount)';
}

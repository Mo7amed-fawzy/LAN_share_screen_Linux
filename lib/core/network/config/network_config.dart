import 'dart:io';

class NetworkConfig {
  final String multicastGroup;
  final int multicastPort;
  final int discoveryTimeoutMs;
  final int discoveryIntervalMs;
  final int advertisementIntervalMs;
  final int heartbeatIntervalMs;
  final int heartbeatTimeoutMs;
  final int electionTimeoutMs;
  final int electionJitterMaxMs;
  final int maxReconnectionAttempts;
  final Duration initialReconnectDelay;
  final Duration maxReconnectDelay;
  final int liveKitPort;
  final String defaultRoomName;
  final String protocolVersion;
  final int packetTtl;

  const NetworkConfig({
    this.multicastGroup = '239.255.100.100',
    this.multicastPort = 57000,
    this.discoveryTimeoutMs = 5000,
    this.discoveryIntervalMs = 2000,
    this.advertisementIntervalMs = 3000,
    this.heartbeatIntervalMs = 2000,
    this.heartbeatTimeoutMs = 8000,
    this.electionTimeoutMs = 3000,
    this.electionJitterMaxMs = 2000,
    this.maxReconnectionAttempts = 10,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 30),
    this.liveKitPort = 7880,
    this.defaultRoomName = 'screen_share',
    this.protocolVersion = '1.0',
    this.packetTtl = 1,
  });

  InternetAddress get multicastAddress => InternetAddress(multicastGroup);

  static final NetworkConfig production = const NetworkConfig();

  NetworkConfig copyWith({
    String? multicastGroup,
    int? multicastPort,
    int? discoveryTimeoutMs,
    int? discoveryIntervalMs,
    int? advertisementIntervalMs,
    int? heartbeatIntervalMs,
    int? heartbeatTimeoutMs,
    int? electionTimeoutMs,
    int? electionJitterMaxMs,
    int? maxReconnectionAttempts,
    Duration? initialReconnectDelay,
    Duration? maxReconnectDelay,
    int? liveKitPort,
    String? defaultRoomName,
    String? protocolVersion,
    int? packetTtl,
  }) =>
      NetworkConfig(
        multicastGroup: multicastGroup ?? this.multicastGroup,
        multicastPort: multicastPort ?? this.multicastPort,
        discoveryTimeoutMs: discoveryTimeoutMs ?? this.discoveryTimeoutMs,
        discoveryIntervalMs: discoveryIntervalMs ?? this.discoveryIntervalMs,
        advertisementIntervalMs:
            advertisementIntervalMs ?? this.advertisementIntervalMs,
        heartbeatIntervalMs: heartbeatIntervalMs ?? this.heartbeatIntervalMs,
        heartbeatTimeoutMs: heartbeatTimeoutMs ?? this.heartbeatTimeoutMs,
        electionTimeoutMs: electionTimeoutMs ?? this.electionTimeoutMs,
        electionJitterMaxMs: electionJitterMaxMs ?? this.electionJitterMaxMs,
        maxReconnectionAttempts:
            maxReconnectionAttempts ?? this.maxReconnectionAttempts,
        initialReconnectDelay:
            initialReconnectDelay ?? this.initialReconnectDelay,
        maxReconnectDelay: maxReconnectDelay ?? this.maxReconnectDelay,
        liveKitPort: liveKitPort ?? this.liveKitPort,
        defaultRoomName: defaultRoomName ?? this.defaultRoomName,
        protocolVersion: protocolVersion ?? this.protocolVersion,
        packetTtl: packetTtl ?? this.packetTtl,
      );

  @override
  String toString() =>
      'NetworkConfig(multicast=$multicastGroup:$multicastPort, '
      'discoveryTimeout=${discoveryTimeoutMs}ms, '
      'heartbeatInterval=${heartbeatIntervalMs}ms, '
      'electionTimeout=${electionTimeoutMs}ms, '
      'maxReconnect=$maxReconnectionAttempts)';
}

enum PacketType {
  query,
  advertisement,
  election,
  coordinator,
  heartbeat,
  electionAck,
}

class DiscoveryPacket {
  final PacketType type;
  final String nodeId;
  final int timestamp;
  final Map<String, dynamic> payload;

  const DiscoveryPacket({
    required this.type,
    required this.nodeId,
    required this.timestamp,
    this.payload = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'nodeId': nodeId,
        'timestamp': timestamp,
        ...payload,
      };

  static DiscoveryPacket fromJson(Map<String, dynamic> json) {
    final type = PacketType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => PacketType.query,
    );
    final payload = Map<String, dynamic>.from(json)
      ..remove('type')
      ..remove('nodeId')
      ..remove('timestamp');

    return DiscoveryPacket(
      type: type,
      nodeId: json['nodeId'] as String,
      timestamp: (json['timestamp'] as num).toInt(),
      payload: payload,
    );
  }

  String? get stringField => payload['value'] as String?;

  Map<String, dynamic> get dataMap =>
      payload['data'] as Map<String, dynamic>? ?? {};
}

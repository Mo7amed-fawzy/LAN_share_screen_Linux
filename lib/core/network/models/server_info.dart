import 'package:equatable/equatable.dart';

class ServerInfo extends Equatable {
  final String serverId;
  final String hostName;
  final String ip;
  final int port;
  final String protocolVersion;
  final int hostPriority;
  final DateTime lastSeen;
  final String? liveKitVersion;

  const ServerInfo({
    required this.serverId,
    required this.hostName,
    required this.ip,
    required this.port,
    required this.protocolVersion,
    required this.hostPriority,
    required this.lastSeen,
    this.liveKitVersion,
  });

  String get url => 'ws://$ip:$port';

  ServerInfo copyWith({DateTime? lastSeen}) => ServerInfo(
        serverId: serverId,
        hostName: hostName,
        ip: ip,
        port: port,
        protocolVersion: protocolVersion,
        hostPriority: hostPriority,
        lastSeen: lastSeen ?? this.lastSeen,
        liveKitVersion: liveKitVersion,
      );

  @override
  List<Object?> get props => [
        serverId,
        hostName,
        ip,
        port,
        protocolVersion,
        hostPriority,
        lastSeen,
        liveKitVersion,
      ];
}

import 'dart:io';

class NodeInfo {
  final String nodeId;
  final String hostName;
  final String ip;
  final int priority;
  final bool canHostServer;
  final int uptimeSeconds;

  const NodeInfo({
    required this.nodeId,
    required this.hostName,
    required this.ip,
    required this.priority,
    required this.canHostServer,
    required this.uptimeSeconds,
  });

  static Future<NodeInfo> create({
    required String nodeId,
    bool canHostServer = true,
  }) async {
    final interfaces = await NetworkInterface.list();
    final ip = interfaces
        .expand((i) => i.addresses)
        .where((a) =>
            a.type == InternetAddressType.IPv4 &&
            !a.isLoopback &&
            !a.isLinkLocal)
        .map((a) => a.address)
        .firstOrNull ?? '127.0.0.1';

    return NodeInfo(
      nodeId: nodeId,
      hostName: Platform.localHostname,
      ip: ip,
      priority: _calculatePriority(canHostServer),
      canHostServer: canHostServer,
      uptimeSeconds: 0,
    );
  }

  static int _calculatePriority(bool canHostServer) {
    int base = canHostServer ? 100 : 10;
    base += Platform.numberOfProcessors;
    return base;
  }

  NodeInfo copyWith({int? uptimeSeconds}) => NodeInfo(
        nodeId: nodeId,
        hostName: hostName,
        ip: ip,
        priority: priority,
        canHostServer: canHostServer,
        uptimeSeconds: uptimeSeconds ?? this.uptimeSeconds,
      );
}

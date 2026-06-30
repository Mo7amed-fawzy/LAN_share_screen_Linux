import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/network_config_provider.dart';
import '../discovery/discovery_provider.dart';
import 'heartbeat_service.dart';

final heartbeatServiceProvider = Provider<HeartbeatService>((ref) {
  final config = ref.watch(networkConfigProvider);
  final discovery = ref.watch(discoveryServiceProvider);
  final service = HeartbeatService(discovery: discovery, config: config);
  ref.onDispose(() => service.dispose());
  return service;
});

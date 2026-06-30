import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/network_config_provider.dart';
import 'discovery_service.dart';

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final config = ref.watch(networkConfigProvider);
  final service = DiscoveryService(config: config);
  ref.onDispose(() => service.dispose());
  return service;
});

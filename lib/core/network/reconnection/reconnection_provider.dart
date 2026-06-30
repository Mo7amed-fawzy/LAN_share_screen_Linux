import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/network_config_provider.dart';
import 'reconnection_service.dart';

final reconnectionServiceProvider = Provider<ReconnectionService>((ref) {
  final config = ref.watch(networkConfigProvider);
  final service = ReconnectionService(config: config);
  ref.onDispose(() => service.dispose());
  return service;
});

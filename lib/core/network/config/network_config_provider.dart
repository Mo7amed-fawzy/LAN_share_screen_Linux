import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_config.dart';

final networkConfigProvider = Provider<NetworkConfig>((ref) {
  return const NetworkConfig();
});

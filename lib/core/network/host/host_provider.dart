import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/network_config_provider.dart';
import 'host_manager.dart';
import 'host_advertiser.dart';

final hostAdvertiserProvider = Provider<HostAdvertiser>((ref) {
  final config = ref.watch(networkConfigProvider);
  final advertiser = HostAdvertiser(config: config);
  return advertiser;
});

final hostManagerProvider = Provider<HostManager>((ref) {
  final config = ref.watch(networkConfigProvider);
  final advertiser = ref.watch(hostAdvertiserProvider);
  final manager = HostManager(config: config, advertiser: advertiser);
  ref.onDispose(() => manager.dispose());
  return manager;
});

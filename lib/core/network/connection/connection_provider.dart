import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../livekit_client.dart';
import '../config/network_config_provider.dart';
import '../discovery/discovery_provider.dart';
import '../election/election_provider.dart';
import '../heartbeat/heartbeat_provider.dart';
import '../host/host_provider.dart';
import '../reconnection/reconnection_provider.dart';
import 'connection_manager.dart';
import 'connection_state.dart';

final liveKitClientProvider = Provider<LiveKitClient>((ref) {
  final client = LiveKitClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final connectionManagerProvider = Provider<ConnectionManager>((ref) {
  final config = ref.watch(networkConfigProvider);
  final discoveryService = ref.watch(discoveryServiceProvider);
  final electionService = ref.watch(leaderElectionProvider);
  final heartbeatService = ref.watch(heartbeatServiceProvider);
  final hostManagerService = ref.watch(hostManagerProvider);
  final hostAdvertiserService = ref.watch(hostAdvertiserProvider);
  final reconnectionService = ref.watch(reconnectionServiceProvider);
  final liveKitClient = ref.watch(liveKitClientProvider);

  final manager = ConnectionManager(
    config: config,
    discovery: discoveryService,
    election: electionService,
    heartbeat: heartbeatService,
    hostManager: hostManagerService,
    hostAdvertiser: hostAdvertiserService,
    reconnector: reconnectionService,
    liveKitClient: liveKitClient,
  );

  ref.onDispose(() => manager.dispose());
  return manager;
});

final connectionStateProvider = StreamProvider<ConnectionState>((ref) {
  return ref.watch(connectionManagerProvider).stateStream;
});

final isNetworkConnectedProvider = Provider<bool>((ref) {
  final state = ref.watch(connectionStateProvider).valueOrNull;
  return state?.isConnected ?? false;
});

final connectionPhaseProvider = Provider<ConnectionPhase>((ref) {
  final state = ref.watch(connectionStateProvider).valueOrNull;
  return state?.phase ?? ConnectionPhase.initializing;
});

final isHostProvider = Provider<bool>((ref) {
  final state = ref.watch(connectionStateProvider).valueOrNull;
  return state?.phase == ConnectionPhase.hostReady;
});

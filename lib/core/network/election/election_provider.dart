import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/network_config_provider.dart';
import '../discovery/discovery_provider.dart';
import 'leader_election.dart';

final leaderElectionProvider = Provider<LeaderElection>((ref) {
  final config = ref.watch(networkConfigProvider);
  final discovery = ref.watch(discoveryServiceProvider);
  final election = LeaderElection(discovery: discovery, config: config);
  ref.onDispose(() => election.dispose());
  return election;
});

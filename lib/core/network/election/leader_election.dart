import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:logging/logging.dart';
import '../../error/failures.dart';
import '../config/network_config.dart';
import '../discovery/discovery_service.dart';
import '../models/discovery_packet.dart';

enum ElectionPhase {
  idle,
  campaigning,
  waitingForAcks,
  elected,
  conceded,
}

class LeaderElection {
  final Logger _log = Logger('LeaderElection');
  final DiscoveryService _discovery;
  final NetworkConfig _config;

  String? _nodeId;
  int _nodePriority = 0;
  ElectionPhase _phase = ElectionPhase.idle;

  Completer<bool>? _electionCompleter;
  bool _electionCompleted = false;
  Timer? _electionTimer;
  Timer? _ackTimer;
  final List<String> _higherPriorityNodes = [];

  final _resultController = StreamController<ElectionResult>.broadcast();
  final _errorController = StreamController<Failure>.broadcast();

  Stream<ElectionResult> get results => _resultController.stream;
  Stream<Failure> get errors => _errorController.stream;
  ElectionPhase get phase => _phase;

  LeaderElection({
    required DiscoveryService discovery,
    required NetworkConfig config,
  })  : _discovery = discovery,
        _config = config;

  void configure({required String nodeId, required int priority}) {
    _nodeId = nodeId;
    _nodePriority = priority;
  }

  Future<bool> electLeader() async {
    if (_nodeId == null) return false;
    _phase = ElectionPhase.campaigning;
    _higherPriorityNodes.clear();
    _electionCompleter = Completer<bool>();
    _electionCompleted = false;

    final jitter = Random().nextInt(_config.electionJitterMaxMs);
    _log.info('Election jitter: ${jitter}ms before campaigning');

    await Future.delayed(Duration(milliseconds: jitter));

    if (_phase != ElectionPhase.campaigning) return false;

    _sendElectionMessage();

    _ackTimer = Timer(
      Duration(milliseconds: _config.electionTimeoutMs),
      _onAckTimeout,
    );

    final result = await _electionCompleter!.future;
    return result;
  }

  void _sendElectionMessage() {
    final packet = DiscoveryPacket(
      type: PacketType.election,
      nodeId: _nodeId!,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {
        'priority': _nodePriority,
        'data': {
          'nodeId': _nodeId,
          'priority': _nodePriority,
        },
      },
    );
    _discovery.sendPacket(packet);
    _log.info('Sent ELECTION message (priority: $_nodePriority)');
  }

  void handleElection(DiscoveryPacket packet) {
    if (_nodeId == null) return;
    if (_phase == ElectionPhase.conceded || _phase == ElectionPhase.elected) return;
    if (packet.nodeId == _nodeId) return;
    final senderId = packet.nodeId;
    final senderPriority = (packet.payload['priority'] as num?)?.toInt() ?? 0;

    if (_nodePriority > senderPriority) {
      _log.info('Received ELECTION from $senderId (p=$senderPriority) — responding OK (p=$_nodePriority)');
      final ack = DiscoveryPacket(
        type: PacketType.electionAck,
        nodeId: _nodeId!,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: {
          'priority': _nodePriority,
          'data': {
            'nodeId': _nodeId,
            'priority': _nodePriority,
          },
        },
      );
      _discovery.sendPacket(ack);

      if (_phase == ElectionPhase.idle) {
        _triggerElection();
      }
    } else if (_nodePriority < senderPriority) {
      _log.info('Received ELECTION from $senderId (p=$senderPriority) — yielding');
      _phase = ElectionPhase.conceded;
      _ackTimer?.cancel();
      _completeElection(false);
      _electionTimer = Timer(
        Duration(milliseconds: _config.electionTimeoutMs * 2),
        () {
          if (_phase == ElectionPhase.conceded) {
            _log.warning('No coordinator message received — retrying election');
            _phase = ElectionPhase.idle;
            _triggerElection();
          }
        },
      );
    } else {
      _log.info('Received ELECTION from $senderId — same priority, comparing UUIDs');
      if (_nodeId!.compareTo(senderId) > 0) {
        final ack = DiscoveryPacket(
          type: PacketType.electionAck,
          nodeId: _nodeId!,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          payload: {
            'priority': _nodePriority,
            'data': {
              'nodeId': _nodeId,
              'priority': _nodePriority,
            },
          },
        );
        _discovery.sendPacket(ack);
        if (_phase == ElectionPhase.idle) {
          _triggerElection();
        }
      } else {
        _log.info('Same priority but lower UUID — conceding to $senderId');
        _phase = ElectionPhase.conceded;
        _ackTimer?.cancel();
        _completeElection(false);
        _electionTimer = Timer(
          Duration(milliseconds: _config.electionTimeoutMs * 2),
          () {
            if (_phase == ElectionPhase.conceded) {
              _log.warning('No coordinator message received — retrying election');
              _phase = ElectionPhase.idle;
              _triggerElection();
            }
          },
        );
      }
    }
  }

  void handleElectionAck(DiscoveryPacket packet) {
    if (_phase != ElectionPhase.campaigning) return;
    final senderPriority = (packet.payload['priority'] as num?)?.toInt() ?? 0;

    if (senderPriority > _nodePriority) {
      _higherPriorityNodes.add(packet.nodeId);
      _log.info('Received ACK from ${packet.nodeId} (p=$senderPriority) — higher priority exists');
    }
  }

  void _triggerElection() {
    _phase = ElectionPhase.campaigning;
    _higherPriorityNodes.clear();
    _sendElectionMessage();

    _ackTimer?.cancel();
    _ackTimer = Timer(
      Duration(milliseconds: _config.electionTimeoutMs),
      _onAckTimeout,
    );
  }

  void _onAckTimeout() {
    if (_phase != ElectionPhase.campaigning) return;

    if (_higherPriorityNodes.isEmpty) {
      _log.info('No higher priority nodes responded — I am the leader!');
      _phase = ElectionPhase.elected;
      _sendCoordinatorMessage();
      _completeElection(true);
      _resultController.add(ElectionResult(
        winnerId: _nodeId!,
        isSelf: true,
      ));
    } else {
      _log.info('Higher priority nodes exist: $_higherPriorityNodes — waiting for coordinator');
      _phase = ElectionPhase.conceded;
      _completeElection(false);

      _electionTimer = Timer(
        Duration(milliseconds: _config.electionTimeoutMs * 2),
        () {
          if (_phase == ElectionPhase.conceded) {
            _log.warning('No coordinator message received — retrying election');
            _phase = ElectionPhase.idle;
            _triggerElection();
          }
        },
      );
    }
  }

  void handleCoordinator(DiscoveryPacket packet) {
    final coordinatorId = packet.nodeId;
    _log.info('Coordinator elected: $coordinatorId');
    _phase = ElectionPhase.idle;
    _electionTimer?.cancel();

    _resultController.add(ElectionResult(
      winnerId: coordinatorId,
      isSelf: coordinatorId == _nodeId,
    ));

    _completeElection(coordinatorId == _nodeId);
  }

  void _completeElection(bool result) {
    if (_electionCompleted) return;
    _electionCompleted = true;
    _electionCompleter?.complete(result);
  }

  void _sendCoordinatorMessage() {
    final packet = DiscoveryPacket(
      type: PacketType.coordinator,
      nodeId: _nodeId!,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      payload: {
        'coordinatorId': _nodeId,
        'data': {
          'coordinatorId': _nodeId,
          'hostName': Platform.localHostname,
        },
      },
    );
    _discovery.sendPacket(packet);
    _log.info('Sent COORDINATOR message');
  }

  void reset() {
    _phase = ElectionPhase.idle;
    _electionTimer?.cancel();
    _ackTimer?.cancel();
    if (_electionCompleter != null && !_electionCompleter!.isCompleted) {
      _electionCompleter?.complete(false);
    }
    _electionCompleter = null;
    _electionCompleted = false;
    _higherPriorityNodes.clear();
  }

  void dispose() {
    reset();
    _resultController.close();
    _errorController.close();
  }
}

class ElectionResult {
  final String winnerId;
  final bool isSelf;

  const ElectionResult({
    required this.winnerId,
    required this.isSelf,
  });
}

import 'dart:async';
import 'dart:math';
import 'package:logging/logging.dart';
import '../config/network_config.dart';

class ReconnectionService {
  final Logger _log = Logger('ReconnectionService');
  final NetworkConfig _config;

  int _attempts = 0;
  Timer? _reconnectTimer;
  bool _isRunning = false;

  final _triggerController = StreamController<void>.broadcast();
  final _maxAttemptsReachedController = StreamController<void>.broadcast();

  Stream<void> get reconnectTriggered => _triggerController.stream;
  Stream<void> get maxAttemptsReached => _maxAttemptsReachedController.stream;
  bool get isRunning => _isRunning;
  int get attemptCount => _attempts;

  ReconnectionService({NetworkConfig? config})
      : _config = config ?? NetworkConfig.production;

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _attempts = 0;
  }

  void scheduleReconnect() {
    if (!_isRunning) return;
    _attempts++;

    if (_attempts > _config.maxReconnectionAttempts) {
      _log.severe('Max reconnection attempts (${_config.maxReconnectionAttempts}) reached');
      _maxAttemptsReachedController.add(null);
      return;
    }

    final delay = _calculateBackoff();
    _log.info('Scheduling reconnect attempt $_attempts in ${delay.inMilliseconds}ms');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      _triggerController.add(null);
    });
  }

  Duration _calculateBackoff() {
    final base = _config.initialReconnectDelay.inMilliseconds;
    final max = _config.maxReconnectDelay.inMilliseconds;
    final exponential = (base * pow(2, _attempts - 1)).toInt();
    final jitter = Random().nextInt(1000);
    final capped = min(exponential + jitter, max);
    return Duration(milliseconds: capped);
  }

  void reset() {
    _attempts = 0;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> stop() async {
    _isRunning = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void dispose() {
    stop();
    _triggerController.close();
    _maxAttemptsReachedController.close();
  }
}

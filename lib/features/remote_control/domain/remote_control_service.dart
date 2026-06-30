import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../core/error/error_handler.dart';
import '../../../core/network/connection/connection_manager.dart';
import '../../../core/network/connection/connection_state.dart';
import '../../../core/network/livekit_client.dart';
import 'input_event.dart';
import 'remote_control_state.dart';

class RemoteControlService {
  final LiveKitClient _liveKitClient;
  final ConnectionManager _connectionManager;
  StreamSubscription? _connectionSub;
  Future<void> Function()? _dataCancel;
  bool _isConnected = false;

  final _stateController = StreamController<RemoteControlState>.broadcast();
  final _requestFromController =
      StreamController<String>.broadcast();

  RemoteControlState _state = const RemoteControlState();
  int? _screenWidth;
  int? _screenHeight;

  Stream<RemoteControlState> get stateStream => _stateController.stream;
  Stream<String> get requestFromStream => _requestFromController.stream;
  RemoteControlState get currentState => _state;

  RemoteControlService({
    required LiveKitClient liveKitClient,
    required ConnectionManager connectionManager,
  })  : _liveKitClient = liveKitClient,
        _connectionManager = connectionManager {
    debugPrint('[RemoteControlService] init');
    _connectionSub = _connectionManager.stateStream.listen((s) {
      if (s.phase == ConnectionPhase.connected ||
          s.phase == ConnectionPhase.hostReady) {
        _onConnected();
      } else if (s.phase == ConnectionPhase.initializing) {
        _onDisconnected();
      }
    });
  }

  void _onConnected() {
    if (_isConnected) {
      return;
    }
    _isConnected = true;
    debugPrint('[RemoteControlService] connected, setting up data listener');
    final room = _liveKitClient.isConnected ? _liveKitClient.room : null;
    if (room == null) return;
    _dataCancel?.call();
    _dataCancel = room.events.on<lk.DataReceivedEvent>(_onDataReceived);
  }

  void _onDisconnected() {
    if (!_isConnected) return;
    _isConnected = false;
    _dataCancel?.call();
    _dataCancel = null;
    _updateState(const RemoteControlState());
  }

  void _onDataReceived(lk.DataReceivedEvent event) {
    if (event.topic != 'remote_control') return;
    try {
      final json = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
      final type = json['type'] as String;
      final sender = event.participant?.identity ?? 'unknown';

      switch (type) {
        case 'request_control':
          _onControlRequest(sender);
        case 'grant_control':
          _onControlGranted();
        case 'deny_control':
          _onControlDenied();
        case 'release_control':
          _onControlReleased(json);
        case 'input_event':
          _onInputEvent(json);
        case 'screen_size_query':
          _sendScreenSize(sender);
      }
    } catch (e, s) {
      logError('[RemoteControlService] failed to parse data', e, s);
    }
  }

  Future<RemoteControlState> requestControl(String identity) async {
    _updateState(RemoteControlState(
      phase: RemoteControlPhase.requesting,
      participantIdentity: identity,
    ));
    _sendMessage({'type': 'request_control'}, target: identity);
    return currentState;
  }

  void _sendReleaseControl(String reason, {String? target}) {
    _sendMessage({'type': 'release_control', 'reason': reason}, target: target);
  }

  void grantControl(String identity) async {
    if (_state.phase == RemoteControlPhase.beingControlled) return;
    _sendMessage({'type': 'grant_control'}, target: identity);
    await _detectScreenSize();
    _updateState(RemoteControlState(
      phase: RemoteControlPhase.beingControlled,
      participantIdentity: identity,
    ));
  }

  void denyControl(String identity) {
    _sendMessage({'type': 'deny_control'}, target: identity);
    _updateState(const RemoteControlState());
  }

  void releaseControl() {
    final target = _state.participantIdentity;
    _sendReleaseControl('released_by_controller', target: target);
    _updateState(RemoteControlState(releaseReason: 'released_by_controller'));
  }

  void stopBeingControlled({String reason = 'stopped_by_sharer'}) {
    final target = _state.participantIdentity;
    _sendReleaseControl(reason, target: target);
    _updateState(RemoteControlState(releaseReason: reason));
  }

  DateTime _lastInputSend = DateTime.now();
  static const Duration _throttle = Duration(milliseconds: 16);

  Future<void> sendInputEvent(InputEvent event) async {
    if (_state.phase != RemoteControlPhase.controlling) return;
    final now = DateTime.now();
    if (event.type == InputEventType.mouseMove &&
        now.difference(_lastInputSend) < _throttle) return;
    _lastInputSend = now;
    final target = _state.participantIdentity;
    final map = event.toJson();
    map['type'] = 'input_event';
    _sendMessage(map, target: target);
  }

  void _onControlRequest(String identity) {
    if (const bool.fromEnvironment('AUTO_TEST', defaultValue: false)) {
      grantControl(identity);
      return;
    }
    if (_state.phase == RemoteControlPhase.beingRequested ||
        _state.phase == RemoteControlPhase.beingControlled) return;
    _updateState(RemoteControlState(
      phase: RemoteControlPhase.beingRequested,
      participantIdentity: identity,
    ));
    _requestFromController.add(identity);
  }

  void _onControlGranted() {
    if (_state.phase != RemoteControlPhase.requesting) return;
    _updateState(_state.copyWith(phase: RemoteControlPhase.controlling));
  }

  void _onControlDenied() {
    _updateState(const RemoteControlState());
  }

  void _onControlReleased(Map<String, dynamic> json) {
    final reason = json['reason'] as String?;
    _updateState(RemoteControlState(releaseReason: reason));
  }

  void _onInputEvent(Map<String, dynamic> json) async {
    if (_state.phase != RemoteControlPhase.beingControlled) return;
    try {
      final event = InputEvent.fromJson(json);
      await _executeInput(event);
    } catch (e, s) {
      logError('[RemoteControlService] executeInput failed', e, s);
    }
  }

  Future<void> _executeInput(InputEvent event) async {
    try {
      switch (event.type) {
        case InputEventType.mouseMove:
          final px = (event.x * (_screenWidth ?? 1920)).round();
          final py = (event.y * (_screenHeight ?? 1080)).round();
          await _xdotool('mousemove', ['--', '$px', '$py']);
        case InputEventType.mouseDown:
          await _xdotool('mousedown', [_mouseButtonArg(event.button)]);
        case InputEventType.mouseUp:
          await _xdotool('mouseup', [_mouseButtonArg(event.button)]);
        case InputEventType.scroll:
          final btn = (event.deltaY ?? 0) < 0 ? '4' : '5';
          await _xdotool('click', [btn]);
        case InputEventType.keyDown:
          if (event.key != null) await _xdotool('keydown', [event.key!]);
        case InputEventType.keyUp:
          if (event.key != null) await _xdotool('keyup', [event.key!]);
      }
    } catch (e) {
      debugPrint('[RemoteControlService] xdotool error: $e');
    }
  }

  String _mouseButtonArg(MouseButton? button) {
    switch (button) {
      case MouseButton.left:
        return '1';
      case MouseButton.middle:
        return '2';
      case MouseButton.right:
        return '3';
      default:
        return '1';
    }
  }

  Future<void> _xdotool(String command, List<String> args) async {
    await Process.run('xdotool', [command, ...args]);
  }

  Future<void> _detectScreenSize() async {
    try {
      final result = await Process.run('xdotool', ['getdisplaygeometry']);
      if (result.exitCode == 0) {
        final parts = (result.stdout as String).trim().split(' ');
        _screenWidth = int.tryParse(parts.isNotEmpty ? parts[0] : '');
        _screenHeight = int.tryParse(parts.length > 1 ? parts[1] : '');
      }
    } catch (e) {
      debugPrint('[RemoteControlService] could not detect screen size: $e');
    }
  }

  void _sendScreenSize(String toIdentity) {
    _sendMessage({
      'type': 'screen_size_info',
      'width': _screenWidth ?? 1920,
      'height': _screenHeight ?? 1080,
    }, target: toIdentity);
  }

  void _sendMessage(Map<String, dynamic> json, {String? target}) {
    try {
      final bytes = utf8.encode(jsonEncode(json));
      final room = _liveKitClient.isConnected ? _liveKitClient.room : null;
      room?.localParticipant?.publishData(
        bytes.toList(),
        reliable: true,
        topic: 'remote_control',
        destinationIdentities: target != null ? [target] : null,
      );
    } catch (e, s) {
      logError('[RemoteControlService] sendMessage failed', e, s);
    }
  }

  void _updateState(RemoteControlState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  void dispose() {
    _connectionSub?.cancel();
    _dataCancel?.call();
    _stateController.close();
    _requestFromController.close();
  }
}

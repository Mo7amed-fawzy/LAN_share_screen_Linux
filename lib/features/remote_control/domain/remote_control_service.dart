import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../core/error/error_handler.dart';
import '../../room/domain/room_service.dart';
import '../../room/domain/room_state.dart';
import 'input_event.dart';
import 'remote_control_state.dart';

class RemoteControlService {
  final RoomService _roomService;
  StreamSubscription? _connectionSub;
  Future<void> Function()? _dataCancel;

  final _stateController = StreamController<RemoteControlState>.broadcast();
  final _requestFromController =
      StreamController<String>.broadcast(); // identity of requester

  RemoteControlState _state = const RemoteControlState();
  int? _screenWidth;
  int? _screenHeight;

  Stream<RemoteControlState> get stateStream => _stateController.stream;
  Stream<String> get requestFromStream => _requestFromController.stream;
  RemoteControlState get currentState => _state;

  RemoteControlService(this._roomService) {
    debugPrint('[RemoteControlService] init');
    _connectionSub = _roomService.connectionStateStream.listen((s) {
      if (s == RoomConnectionState.connected) {
        _onConnected();
      } else if (s == RoomConnectionState.disconnected) {
        _onDisconnected();
      }
    });
  }

  void _onConnected() {
    debugPrint('[RemoteControlService] connected, setting up data listener');
    final room = _roomService.room;
    if (room == null) return;
    _dataCancel = room.events.on<lk.DataReceivedEvent>(_onDataReceived);
  }

  void _onDisconnected() {
    debugPrint('[RemoteControlService] disconnected, cleaning up');
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

      debugPrint('[RemoteControlService] received type=$type from=$sender');

      switch (type) {
        case 'request_control':
          _onControlRequest(sender);
        case 'grant_control':
          _onControlGranted();
        case 'deny_control':
          _onControlDenied();
        case 'release_control':
          _onControlReleased();
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
    debugPrint('[RemoteControlService] requestControl: $identity');
    _updateState(RemoteControlState(
      phase: RemoteControlPhase.requesting,
      participantIdentity: identity,
    ));
    _sendMessage({'type': 'request_control'});
    return currentState;
  }

  void grantControl(String identity) async {
    debugPrint('[RemoteControlService] grantControl: $identity');
    _sendMessage({'type': 'grant_control'});
    await _detectScreenSize();
    _updateState(RemoteControlState(
      phase: RemoteControlPhase.beingControlled,
      participantIdentity: identity,
    ));
  }

  void denyControl(String identity) {
    debugPrint('[RemoteControlService] denyControl: $identity');
    _sendMessage({'type': 'deny_control'});
    _updateState(const RemoteControlState());
  }

  void releaseControl() {
    debugPrint('[RemoteControlService] releaseControl');
    _sendMessage({'type': 'release_control'});
    _updateState(const RemoteControlState());
  }

  void stopBeingControlled() {
    debugPrint('[RemoteControlService] stopBeingControlled');
    _updateState(const RemoteControlState());
  }

  Future<void> sendInputEvent(InputEvent event) async {
    if (_state.phase != RemoteControlPhase.controlling) return;
    debugPrint('[RemoteControlService] sendInputEvent: ${event.type}');
    final map = event.toJson();
    map['type'] = 'input_event';
    _sendMessage(map);
  }

  void _onControlRequest(String identity) {
    if (_state.phase == RemoteControlPhase.beingRequested ||
        _state.phase == RemoteControlPhase.beingControlled) return;
    _updateState(RemoteControlState(
      phase: RemoteControlPhase.beingRequested,
      participantIdentity: identity,
    ));
    _requestFromController.add(identity);
  }

  void _onControlGranted() {
    debugPrint('[RemoteControlService] control granted!');
    _updateState(_state.copyWith(phase: RemoteControlPhase.controlling));
  }

  void _onControlDenied() {
    debugPrint('[RemoteControlService] control denied');
    _updateState(const RemoteControlState());
  }

  void _onControlReleased() {
    debugPrint('[RemoteControlService] control released by controller');
    _updateState(const RemoteControlState());
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
        debugPrint('[RemoteControlService] screen size: $_screenWidth x $_screenHeight');
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
    });
  }

  void _sendMessage(Map<String, dynamic> json) {
    try {
      final bytes = utf8.encode(jsonEncode(json));
      final room = _roomService.room;
      room?.localParticipant?.publishData(bytes.toList(), reliable: true, topic: 'remote_control');
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

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/input_event.dart';
import '../../domain/remote_control_service.dart';
import '../providers/remote_control_provider.dart';

final _screenKeyMap = <LogicalKeyboardKey, String>{
  LogicalKeyboardKey.enter: 'Return',
  LogicalKeyboardKey.tab: 'Tab',
  LogicalKeyboardKey.backspace: 'BackSpace',
  LogicalKeyboardKey.escape: 'Escape',
  LogicalKeyboardKey.space: 'space',
  LogicalKeyboardKey.delete: 'Delete',
  LogicalKeyboardKey.arrowUp: 'Up',
  LogicalKeyboardKey.arrowDown: 'Down',
  LogicalKeyboardKey.arrowLeft: 'Left',
  LogicalKeyboardKey.arrowRight: 'Right',
  LogicalKeyboardKey.shiftLeft: 'Shift_L',
  LogicalKeyboardKey.shiftRight: 'Shift_R',
  LogicalKeyboardKey.controlLeft: 'Control_L',
  LogicalKeyboardKey.controlRight: 'Control_R',
  LogicalKeyboardKey.altLeft: 'Alt_L',
  LogicalKeyboardKey.altRight: 'Alt_R',
  LogicalKeyboardKey.metaLeft: 'Super_L',
  LogicalKeyboardKey.metaRight: 'Super_R',
  LogicalKeyboardKey.capsLock: 'Caps_Lock',
  LogicalKeyboardKey.home: 'Home',
  LogicalKeyboardKey.end: 'End',
  LogicalKeyboardKey.pageUp: 'Page_Up',
  LogicalKeyboardKey.pageDown: 'Page_Down',
  LogicalKeyboardKey.insert: 'Insert',
  LogicalKeyboardKey.f1: 'F1',
  LogicalKeyboardKey.f2: 'F2',
  LogicalKeyboardKey.f3: 'F3',
  LogicalKeyboardKey.f4: 'F4',
  LogicalKeyboardKey.f5: 'F5',
  LogicalKeyboardKey.f6: 'F6',
  LogicalKeyboardKey.f7: 'F7',
  LogicalKeyboardKey.f8: 'F8',
  LogicalKeyboardKey.f9: 'F9',
  LogicalKeyboardKey.f10: 'F10',
  LogicalKeyboardKey.f11: 'F11',
  LogicalKeyboardKey.f12: 'F12',
};

class RemoteControlOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const RemoteControlOverlay({super.key, required this.child});

  @override
  ConsumerState<RemoteControlOverlay> createState() =>
      _RemoteControlOverlayState();
}

class _RemoteControlOverlayState extends ConsumerState<RemoteControlOverlay> {
  final FocusNode _focusNode = FocusNode();
  RemoteControlService? _service;
  bool _isControlling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _isControlling = ref.watch(isControllingProvider);
    _service = ref.read(remoteControlServiceProvider);

    return Stack(
      children: [
        widget.child,
        if (_isControlling) ...[
          Positioned.fill(
            child: Listener(
              onPointerMove: _onPointerMove,
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerSignal: _onPointerSignal,
              child: Focus(
                focusNode: _focusNode,
                autofocus: true,
                onKeyEvent: _onKeyEvent,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.screen_lock_portrait,
                        size: 16, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Remote Control Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _service?.releaseControl();
                  _focusNode.unfocus();
                },
                icon: const Icon(Icons.stop, size: 16),
                label: const Text('Release Control'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!_isControlling) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPos = box.globalToLocal(event.position);
    final size = box.size;
    if (size.width <= 0 || size.height <= 0) return;
    _service?.sendInputEvent(InputEvent(
      type: InputEventType.mouseMove,
      x: localPos.dx / size.width,
      y: localPos.dy / size.height,
    ));
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isControlling) return;
    _focusNode.requestFocus();
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPos = box.globalToLocal(event.position);
    final size = box.size;
    if (size.width <= 0 || size.height <= 0) return;
    final button = _flattenButton(event.buttons);
    _service?.sendInputEvent(InputEvent(
      type: InputEventType.mouseDown,
      x: localPos.dx / size.width,
      y: localPos.dy / size.height,
      button: button,
    ));
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_isControlling) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final localPos = box.globalToLocal(event.position);
    final size = box.size;
    if (size.width <= 0 || size.height <= 0) return;
    final button = _flattenButton(event.buttons);
    _service?.sendInputEvent(InputEvent(
      type: InputEventType.mouseUp,
      x: localPos.dx / size.width,
      y: localPos.dy / size.height,
      button: button,
    ));
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!_isControlling) return;
    if (event is PointerScrollEvent) {
      _service?.sendInputEvent(InputEvent(
        type: InputEventType.scroll,
        deltaY: event.scrollDelta.dy.round(),
      ));
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (!_isControlling) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyUpEvent) {
      return KeyEventResult.ignored;
    }
    final xdotoolKey = _mapKey(event.logicalKey);
    if (xdotoolKey == null) return KeyEventResult.ignored;
    final type = event is KeyDownEvent
        ? InputEventType.keyDown
        : InputEventType.keyUp;
    _service?.sendInputEvent(InputEvent(type: type, key: xdotoolKey));
    return KeyEventResult.handled;
  }

  String? _mapKey(LogicalKeyboardKey key) {
    final mapped = _screenKeyMap[key];
    if (mapped != null) return mapped;
    final label = key.keyLabel;
    if (label.isNotEmpty && label.length == 1) return label;
    return null;
  }

  MouseButton _flattenButton(int? buttons) {
    if (buttons == null) return MouseButton.left;
    if (buttons & kSecondaryMouseButton != 0) return MouseButton.right;
    if (buttons & kMiddleMouseButton != 0) return MouseButton.middle;
    return MouseButton.left;
  }
}

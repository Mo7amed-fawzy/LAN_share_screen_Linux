enum InputEventType {
  mouseMove,
  mouseDown,
  mouseUp,
  scroll,
  keyDown,
  keyUp,
}

enum MouseButton {
  left,
  middle,
  right,
}

class InputEvent {
  final InputEventType type;
  final double x;
  final double y;
  final MouseButton? button;
  final String? key;
  final int? deltaY;

  const InputEvent({
    required this.type,
    this.x = 0,
    this.y = 0,
    this.button,
    this.key,
    this.deltaY,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type.name};
    if (type == InputEventType.mouseMove ||
        type == InputEventType.mouseDown ||
        type == InputEventType.mouseUp) {
      map['x'] = x;
      map['y'] = y;
    }
    if (button != null) map['button'] = button!.name;
    if (key != null) map['key'] = key;
    if (deltaY != null) map['deltaY'] = deltaY;
    return map;
  }

  factory InputEvent.fromJson(Map<String, dynamic> json) => InputEvent(
        type: InputEventType.values.byName(json['type'] as String),
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        button: json['button'] != null
            ? MouseButton.values.byName(json['button'] as String)
            : null,
        key: json['key'] as String?,
        deltaY: json['deltaY'] as int?,
      );

  @override
  String toString() => 'InputEvent(${type.name})';
}

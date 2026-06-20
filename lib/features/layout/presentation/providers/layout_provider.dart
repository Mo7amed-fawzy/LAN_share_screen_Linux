import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/layout_state.dart';

final layoutModeProvider = StateProvider<LayoutMode>((ref) => LayoutMode.focus);

final isFocusModeProvider = Provider<bool>((ref) {
  return ref.watch(layoutModeProvider) == LayoutMode.focus;
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../domain/room_state.dart';
import '../providers/room_provider.dart';

class ConnectionStatusBar extends ConsumerWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomStateNotifierProvider);
    return _StatusIndicator(state: state);
  }
}

class _StatusIndicator extends StatelessWidget {
  final RoomConnectionState state;

  const _StatusIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (state) {
      RoomConnectionState.disconnected => (AppColors.textSecondary, Icons.link_off),
      RoomConnectionState.connecting => (AppColors.warning, Icons.sync),
      RoomConnectionState.connected => (AppColors.success, Icons.link),
      RoomConnectionState.reconnecting => (AppColors.warning, Icons.sync),
      RoomConnectionState.failed => (AppColors.error, Icons.error_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppDimensions.xs),
          Text(
            state.label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

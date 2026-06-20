import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../participant/domain/participant_entity.dart';
import '../../../../shared/widgets/video_renderer.dart';
import '../../../remote_control/presentation/widgets/remote_control_overlay.dart';
import '../../../remote_control/presentation/providers/remote_control_provider.dart';

class MainVideoView extends ConsumerWidget {
  final ParticipantEntity? participant;

  const MainVideoView({super.key, required this.participant});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (participant == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.desktop_windows_outlined,
                size: 80,
                color: AppColors.textSecondary,
              ),
              SizedBox(height: AppDimensions.md),
              Text(
                'No participant selected',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: AppDimensions.sm),
              Text(
                'Click a thumbnail below to view',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isControlling = ref.watch(isControllingProvider);
    final isRequesting = ref.watch(isRequestingProvider);
    final isBeingControlled = ref.watch(isBeingControlledProvider);
    final service = ref.read(remoteControlServiceProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: AppColors.focusedBorder, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (participant!.hasVideo && participant!.screenTrack != null)
            RemoteControlOverlay(
              child: VideoRenderer(
                track: participant!.screenTrack!,
                mirrorMode: lk.VideoViewMirrorMode.off,
              ),
            )
          else
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.desktop_windows_outlined,
                    size: 80,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: AppDimensions.md),
                  Text(
                    'Screen not available',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: AppDimensions.md,
            left: AppDimensions.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.sm,
                vertical: AppDimensions.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.overlay,
                borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXs),
              ),
              child: Text(
                participant!.displayNameOrIdentity,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (participant!.isScreenSharing)
            Positioned(
              top: AppDimensions.md,
              right: AppDimensions.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.sm,
                  vertical: AppDimensions.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadiusXs),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.screen_share,
                      size: 14,
                      color: AppColors.success,
                    ),
                    SizedBox(width: AppDimensions.xxs),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!participant!.isLocal &&
              participant!.hasVideo &&
              !isControlling &&
              !isRequesting &&
              !isBeingControlled)
            Positioned(
              bottom: AppDimensions.md,
              right: AppDimensions.md,
              child: FloatingActionButton.small(
                heroTag: 'request_control',
                onPressed: () => service.requestControl(participant!.identity),
                tooltip: 'Request Remote Control',
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.cast_connected, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

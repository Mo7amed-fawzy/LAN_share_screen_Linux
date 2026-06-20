import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../participant/domain/participant_entity.dart';
import '../../../../shared/widgets/video_renderer.dart';

class MainVideoView extends StatelessWidget {
  final ParticipantEntity? participant;

  const MainVideoView({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
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
            VideoRenderer(
              track: participant!.screenTrack!,
              mirrorMode: lk.VideoViewMirrorMode.off,
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
        ],
      ),
    );
  }
}

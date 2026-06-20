import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../shared/widgets/video_renderer.dart';
import '../../domain/participant_entity.dart';

class ParticipantThumbnail extends StatelessWidget {
  final ParticipantEntity participant;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const ParticipantThumbnail({
    super.key,
    required this.participant,
    required this.isSelected,
    required this.onTap,
    this.width = 160,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.thumbnailBackground,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusSm),
          border: Border.all(
            color: isSelected ? AppColors.focusedBorder : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (participant.hasVideo && participant.screenTrack != null)
              VideoRenderer(track: participant.screenTrack!)
            else
              const Center(
                child: Icon(
                  Icons.desktop_windows_outlined,
                  color: AppColors.textSecondary,
                  size: 32,
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.xs,
                  vertical: AppDimensions.xxs,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.overlay,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      participant.isLocal
                          ? Icons.person
                          : Icons.person_outline,
                      size: 12,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: AppDimensions.xxs),
                    Expanded(
                      child: Text(
                        participant.displayNameOrIdentity,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (participant.isScreenSharing)
              Positioned(
                top: AppDimensions.xs,
                right: AppDimensions.xs,
                child: const Icon(
                  Icons.screen_share,
                  size: 14,
                  color: AppColors.success,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

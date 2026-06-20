import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../participant/domain/participant_entity.dart';
import '../../../participant/presentation/widgets/participant_thumbnail.dart';

class ThumbnailBar extends StatelessWidget {
  final List<ParticipantEntity> participants;
  final String? focusedParticipantId;
  final void Function(ParticipantEntity) onParticipantTap;

  const ThumbnailBar({
    super.key,
    required this.participants,
    required this.focusedParticipantId,
    required this.onParticipantTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.thumbnailBarHeight,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: participants.isEmpty
          ? const Center(
              child: Text(
                'No participants connected',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.md,
                vertical: AppDimensions.sm,
              ),
              itemCount: participants.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppConstants.thumbnailGap),
              itemBuilder: (context, index) {
                final participant = participants[index];
                return ParticipantThumbnail(
                  participant: participant,
                  isSelected: participant.identity == focusedParticipantId,
                  onTap: () => onParticipantTap(participant),
                );
              },
            ),
    );
  }
}

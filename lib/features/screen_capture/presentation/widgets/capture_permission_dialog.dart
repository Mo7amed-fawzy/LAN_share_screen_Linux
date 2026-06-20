import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';

class CapturePermissionDialog extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onDismiss;

  const CapturePermissionDialog({
    super.key,
    required this.onStart,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, {
    required VoidCallback onStart,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CapturePermissionDialog(
        onStart: () {
          Navigator.of(ctx).pop();
          onStart();
        },
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      title: const Row(
        children: [
          Icon(Icons.screen_share, color: AppColors.primary),
          SizedBox(width: AppDimensions.sm),
          Text(
            'Share Your Screen',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
      content: const Text(
        'Your screen will be shared with everyone in the room.\n\n'
        'A system dialog will appear asking you to select which screen to share.\n\n'
        'Click "Start Sharing" to begin.',
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.screen_share, size: 18),
          label: const Text('Start Sharing'),
        ),
      ],
    );
  }
}

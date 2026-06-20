import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/remote_control_provider.dart';

class RemoteControlPermissionDialog extends ConsumerWidget {
  final String requesterIdentity;

  const RemoteControlPermissionDialog({
    super.key,
    required this.requesterIdentity,
  });

  static Future<void> show(BuildContext context, String requesterIdentity) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RemoteControlPermissionDialog(
        requesterIdentity: requesterIdentity,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(remoteControlServiceProvider);

    return AlertDialog(
      title: const Text('Remote Control Request'),
      content: Text(
        '$requesterIdentity wants to control your screen.\n'
        'Allow remote control?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            service.denyControl(requesterIdentity);
            Navigator.of(context).pop();
          },
          child: const Text('Deny'),
        ),
        FilledButton(
          onPressed: () {
            service.grantControl(requesterIdentity);
            Navigator.of(context).pop();
          },
          child: const Text('Allow'),
        ),
      ],
    );
  }

  static void showBeingControlled(
    BuildContext context,
    String controllerIdentity,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remote Control Active'),
        content: Text('$controllerIdentity is controlling your screen.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/theme/dimensions.dart';
import '../../../../features/participant/presentation/providers/participants_provider.dart';
import '../../../../features/participant/presentation/providers/focused_participant_provider.dart';
import '../../../../features/participant/domain/participant_entity.dart';
import '../../../../features/room/presentation/providers/room_provider.dart';
import '../../../../features/screen_capture/presentation/providers/capture_provider.dart';
import '../../../../features/screen_capture/presentation/widgets/capture_permission_dialog.dart';
import '../../../../features/room/presentation/widgets/connection_status_bar.dart';
import '../../../../shared/widgets/video_renderer.dart';
import '../../domain/layout_state.dart';
import '../providers/layout_provider.dart';
import '../widgets/main_video_view.dart';
import '../widgets/thumbnail_bar.dart';
import '../../../remote_control/presentation/providers/remote_control_provider.dart';
import '../../../remote_control/presentation/widgets/remote_control_permission_dialog.dart';
import '../../../remote_control/domain/remote_control_state.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  bool _dialogShowing = false;
  String? _bannerMessage;
  Timer? _bannerTimer;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(remoteControlStateProvider, (prev, next) {
      final prevState = prev?.valueOrNull;
      final state = next.valueOrNull;
      if (prevState?.phase == RemoteControlPhase.controlling &&
          state?.phase == RemoteControlPhase.idle) {
        final reason = state?.releaseReason;
        if (reason == 'screen_share_stopped') {
          _showBanner('Share screen is stopped', duration: 5);
        } else if (reason == 'stopped_by_sharer' || reason == null) {
          _showBanner('Screen control is stopped', duration: 5);
        }
        // 'released_by_controller' → no banner, controller self-released
      }
      if (state == null) return;
      if (state.phase == RemoteControlPhase.beingRequested &&
          state.participantIdentity != null &&
          !_dialogShowing) {
        _dialogShowing = true;
        RemoteControlPermissionDialog.show(
          context,
          state.participantIdentity!,
        ).then((_) => _dialogShowing = false);
      } else if (state.phase == RemoteControlPhase.beingControlled &&
          state.participantIdentity != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${state.participantIdentity} is controlling your screen',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });
    ref.listen<bool>(isCapturingProvider, (prev, next) {
      if (prev == true && next == false) {
        final s = ref.read(remoteControlStateProvider).valueOrNull;
        if (s?.phase == RemoteControlPhase.beingControlled) {
          ref.read(remoteControlServiceProvider).stopBeingControlled(reason: 'screen_share_stopped');
        }
      }
    });
    final layoutMode = ref.watch(layoutModeProvider);
    final focused = ref.watch(focusedParticipantProvider);
    final isCapturing = ref.watch(isCapturingProvider);
    final isBeingControlled = ref.watch(isBeingControlledProvider);
    final allParticipants =
        ref.watch(participantsProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ScreenShare'),
        actions: [
          const ConnectionStatusBar(),
          const SizedBox(width: AppDimensions.sm),
          if (isBeingControlled)
            IconButton(
              icon: Icon(Icons.stop_screen_share, color: Colors.red),
              tooltip: 'Stop being controlled',
              onPressed: _confirmStopBeingControlled,
            ),
            if (!isCapturing)
            IconButton(
              icon: const Icon(Icons.screen_share_outlined),
              tooltip: 'Share Screen',
              onPressed: () => _onShareScreen(),
            )
          else
            IconButton(
              icon: const Icon(Icons.stop_screen_share),
              tooltip: 'Stop Sharing',
              onPressed: _confirmStopSharing,
            ),
          IconButton(
            icon: Icon(
              layoutMode == LayoutMode.gallery
                  ? Icons.fullscreen
                  : Icons.grid_view,
            ),
            tooltip: layoutMode == LayoutMode.gallery
                ? 'Focus Mode'
                : 'Gallery Mode',
            onPressed: () {
              final current = ref.read(layoutModeProvider);
              ref.read(layoutModeProvider.notifier).state =
                  current == LayoutMode.focus ? LayoutMode.gallery : LayoutMode.focus;
            },
          ),
          const SizedBox(width: AppDimensions.sm),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Visibility(
                      visible: layoutMode == LayoutMode.focus,
                      maintainState: true,
                      child: _buildFocusLayout(context, ref, focused, allParticipants),
                    ),
                    Visibility(
                      visible: layoutMode == LayoutMode.gallery,
                      maintainState: true,
                      child: _buildGalleryLayout(context, ref, allParticipants),
                    ),
                  ],
                ),
              ),
              ThumbnailBar(
                participants: allParticipants,
                focusedParticipantId: focused?.identity,
                onParticipantTap: (participant) {
                  ref.read(focusedParticipantProvider.notifier).state = participant;
                },
              ),
            ],
          ),
          if (_bannerMessage != null)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Text(
                    _bannerMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFocusLayout(
    BuildContext context,
    WidgetRef widgetRef,
    ParticipantEntity? focused,
    List<ParticipantEntity> participants,
  ) {
    final displayParticipant =
        focused ?? participants.where((p) => !p.isLocal).firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: MainVideoView(participant: displayParticipant),
    );
  }

  Widget _buildGalleryLayout(
    BuildContext context,
    WidgetRef ref,
    List<ParticipantEntity> participants,
  ) {
    final gridColumns = participants.length <= 4 ? 2 : 3;
    final nonLocal = participants.where((p) => !p.isLocal).toList();

    if (nonLocal.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: AppDimensions.md),
            Text(
              'Waiting for participants...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridColumns,
          mainAxisSpacing: AppDimensions.sm,
          crossAxisSpacing: AppDimensions.sm,
          childAspectRatio: 16 / 9,
        ),
        itemCount: nonLocal.length,
        itemBuilder: (context, index) {
          final participant = nonLocal[index];
          return _GalleryTile(
            participant: participant,
            onTap: () {
              ref.read(focusedParticipantProvider.notifier).state = participant;
              ref.read(layoutModeProvider.notifier).state = LayoutMode.focus;
            },
          );
        },
      ),
    );
  }

  void _showBanner(String message, {int duration = 5}) {
    _bannerTimer?.cancel();
    setState(() => _bannerMessage = message);
    _bannerTimer = Timer(Duration(seconds: duration), () {
      if (mounted) setState(() => _bannerMessage = null);
    });
  }

  void _confirmStopBeingControlled() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Being Controlled'),
        content: const Text('Are you sure you want to stop being controlled?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(remoteControlServiceProvider).stopBeingControlled();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  void _confirmStopSharing() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Sharing'),
        content: const Text(
          'You will stop sharing your screen and remote control will be cancelled. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _doStopSharing();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  void _doStopSharing() {
    final service = ref.read(remoteControlServiceProvider);
    final s = ref.read(remoteControlStateProvider).valueOrNull;
    if (s?.phase == RemoteControlPhase.beingControlled) {
      service.stopBeingControlled(reason: 'screen_share_stopped');
    }
    final captureService = ref.read(captureServiceProvider);
    final roomService = ref.read(roomServiceProvider);
    final sid = captureService.publishedSid;
    if (sid != null) {
      debugPrint('[RoomScreen] unpublishing track: $sid');
      roomService.unpublishScreenTrack(sid);
      captureService.clearPublished();
    }
    captureService.stopCapture();
    ref.read(isCapturingProvider.notifier).state = false;
  }

  void _onShareScreen() {
    CapturePermissionDialog.show(
      context,
      onStart: () async {
        try {
          final captureService = ref.read(captureServiceProvider);
          final roomService = ref.read(roomServiceProvider);

          debugPrint('[RoomScreen] starting capture...');
          await captureService.startCapture();
          debugPrint('[RoomScreen] capture done, creating track...');

          final track = captureService.screenTrack;
          if (track == null) {
            throw Exception('Screen track is null after capture');
          }

          debugPrint('[RoomScreen] publishing screen track to LiveKit...');
          final publication = await roomService.publishScreenTrack(track);
          captureService.markPublished(publication.sid);
          debugPrint('[RoomScreen] screen track published: sid=${publication.sid}');

          ref.read(isCapturingProvider.notifier).state = true;
        } catch (e) {
          debugPrint('[RoomScreen] share screen FAILED: $e');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to share screen: $e')),
            );
          }
        }
      },
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final ParticipantEntity participant;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.participant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.thumbnailBackground,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (participant.hasVideo && participant.screenTrack != null)
              VideoRenderer(track: participant.screenTrack!)
            else
              const Center(
                child: Icon(
                  Icons.desktop_windows_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.sm),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.overlay],
                  ),
                ),
                child: Text(
                  participant.displayNameOrIdentity,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

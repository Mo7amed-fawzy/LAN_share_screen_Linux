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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupListeners());
  }

  void _setupListeners() {
    ref.listen(remoteControlStateProvider, (prev, next) {
      final state = next.valueOrNull;
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
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () {
                ref.read(remoteControlServiceProvider).stopBeingControlled();
              },
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
              onPressed: () {
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
              },
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
      body: Column(
        children: [
          Expanded(
            child: layoutMode == LayoutMode.focus
                ? _buildFocusLayout(context, ref, focused, allParticipants)
                : _buildGalleryLayout(context, ref, allParticipants),
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

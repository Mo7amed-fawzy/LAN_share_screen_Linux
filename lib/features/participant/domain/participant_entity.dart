import 'package:livekit_client/livekit_client.dart' as lk;

class ParticipantEntity {
  final String identity;
  final String? displayName;
  final bool isLocal;
  final bool isScreenSharing;
  final bool hasVideo;
  final lk.VideoTrack? screenTrack;
  final lk.ConnectionQuality connectionQuality;

  const ParticipantEntity({
    required this.identity,
    this.displayName,
    required this.isLocal,
    this.isScreenSharing = false,
    this.hasVideo = false,
    this.screenTrack,
    this.connectionQuality = lk.ConnectionQuality.unknown,
  });

  String get displayNameOrIdentity => displayName ?? identity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantEntity &&
          identity == other.identity &&
          isLocal == other.isLocal &&
          hasVideo == other.hasVideo &&
          isScreenSharing == other.isScreenSharing &&
          connectionQuality == other.connectionQuality &&
          screenTrack == other.screenTrack;

  @override
  int get hashCode => Object.hash(
        identity,
        isLocal,
        hasVideo,
        isScreenSharing,
        connectionQuality,
        screenTrack,
      );
}

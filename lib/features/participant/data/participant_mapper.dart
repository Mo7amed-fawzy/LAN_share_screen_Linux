import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../domain/participant_entity.dart';

class ParticipantMapper {
  static ParticipantEntity fromRemoteParticipant(
      lk.RemoteParticipant participant) {
    final videoPubs = participant.videoTrackPublications;

    debugPrint('[ParticipantMapper] remote ${participant.identity}'
        ' has ${videoPubs.length} video publications');
    for (final pub in videoPubs) {
      debugPrint('[ParticipantMapper]   pub sid=${pub.sid}'
          ' source=${pub.source} subscribed=${pub.subscribed} muted=${pub.muted}');
    }

    final screenTrack = videoPubs.where(
      (pub) =>
          pub.source == lk.TrackSource.screenShareVideo &&
          pub.subscribed &&
          !pub.muted,
    ).firstOrNull;

    return ParticipantEntity(
      identity: participant.identity,
      displayName: participant.name,
      isLocal: false,
      isScreenSharing: screenTrack != null,
      hasVideo: screenTrack != null,
      screenTrack: screenTrack?.track,
      connectionQuality: participant.connectionQuality,
    );
  }

  static ParticipantEntity fromLocalParticipant(
      lk.LocalParticipant participant) {
    final videoPubs = participant.videoTrackPublications;

    debugPrint('[ParticipantMapper] local ${participant.identity}'
        ' has ${videoPubs.length} video publications');
    for (final pub in videoPubs) {
      debugPrint('[ParticipantMapper]   pub sid=${pub.sid}'
          ' source=${pub.source} muted=${pub.muted}');
    }

    final screenTrack = videoPubs.where(
      (pub) => pub.source == lk.TrackSource.screenShareVideo && !pub.muted,
    ).firstOrNull;

    return ParticipantEntity(
      identity: participant.identity,
      displayName: participant.name,
      isLocal: true,
      isScreenSharing: screenTrack != null,
      hasVideo: screenTrack != null,
      screenTrack: screenTrack?.track,
      connectionQuality: participant.connectionQuality,
    );
  }
}

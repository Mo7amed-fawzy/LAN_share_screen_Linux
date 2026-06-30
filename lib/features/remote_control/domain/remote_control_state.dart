enum RemoteControlPhase {
  idle,
  requesting,
  controlling,
  beingRequested,
  beingControlled,
}

class RemoteControlState {
  final RemoteControlPhase phase;
  final String? participantIdentity;
  final String? releaseReason;

  const RemoteControlState({
    this.phase = RemoteControlPhase.idle,
    this.participantIdentity,
    this.releaseReason,
  });

  bool get isIdle => phase == RemoteControlPhase.idle;
  bool get isRequesting => phase == RemoteControlPhase.requesting;
  bool get isControlling => phase == RemoteControlPhase.controlling;
  bool get isBeingControlled => phase == RemoteControlPhase.beingControlled;

  RemoteControlState copyWith({
    RemoteControlPhase? phase,
    String? participantIdentity,
    bool clearParticipant = false,
    String? releaseReason,
    bool clearReleaseReason = false,
  }) {
    return RemoteControlState(
      phase: phase ?? this.phase,
      participantIdentity:
          clearParticipant ? null : (participantIdentity ?? this.participantIdentity),
      releaseReason:
          clearReleaseReason ? null : (releaseReason ?? this.releaseReason),
    );
  }

  @override
  String toString() => 'RemoteControlState(${phase.name}, $participantIdentity)';
}

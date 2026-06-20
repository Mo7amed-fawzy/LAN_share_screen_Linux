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

  const RemoteControlState({
    this.phase = RemoteControlPhase.idle,
    this.participantIdentity,
  });

  bool get isIdle => phase == RemoteControlPhase.idle;
  bool get isRequesting => phase == RemoteControlPhase.requesting;
  bool get isControlling => phase == RemoteControlPhase.controlling;
  bool get isBeingControlled => phase == RemoteControlPhase.beingControlled;

  RemoteControlState copyWith({
    RemoteControlPhase? phase,
    String? participantIdentity,
    bool clearParticipant = false,
  }) {
    return RemoteControlState(
      phase: phase ?? this.phase,
      participantIdentity:
          clearParticipant ? null : (participantIdentity ?? this.participantIdentity),
    );
  }

  @override
  String toString() => 'RemoteControlState(${phase.name}, $participantIdentity)';
}

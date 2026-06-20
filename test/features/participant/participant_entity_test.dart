import 'package:flutter_test/flutter_test.dart';
import 'package:screen_share/features/participant/domain/participant_entity.dart';

void main() {
  group('ParticipantEntity', () {
    test('creates with required fields', () {
      final entity = ParticipantEntity(
        identity: 'user1',
        isLocal: false,
      );

      expect(entity.identity, 'user1');
      expect(entity.isLocal, isFalse);
      expect(entity.hasVideo, isFalse);
      expect(entity.displayNameOrIdentity, 'user1');
    });

    test('displayNameOrIdentity returns display name when set', () {
      final entity = ParticipantEntity(
        identity: 'user1',
        displayName: 'Alice',
        isLocal: false,
      );

      expect(entity.displayNameOrIdentity, 'Alice');
    });

    test('equality works correctly', () {
      final a = ParticipantEntity(identity: 'u1', isLocal: false);
      final b = ParticipantEntity(identity: 'u1', isLocal: false);
      final c = ParticipantEntity(identity: 'u2', isLocal: false);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      final a = ParticipantEntity(identity: 'u1', isLocal: false);
      final b = ParticipantEntity(identity: 'u1', isLocal: false);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}

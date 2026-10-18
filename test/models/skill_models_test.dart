import 'package:edupro_mobile_app/features/skill_sharing/models/skill_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SkillSession session;
  setUp(() {
    session = SkillSession(
      id: 'session-1',
      title: 'Algebra',
      person: 'Tutor',
      description: 'Equations',
      date: DateTime.utc(2026, 3, 1),
      time: '10:00',
      status: SessionStatus.awaitingLink,
      avatarColor: Colors.blue,
      initials: 'TU',
      profileImageUrl: 'avatar.png',
      canPublishLink: true,
    );
  });

  test(
    'SKILL001 copyWith updates meeting details and preserves session identity',
    () {
      // Arrange / Act
      final updated = session.copyWith(
        status: SessionStatus.confirmed,
        meetingPlatform: 'Teams',
        meetingLink: 'https://example.test/session',
      );
      // Assert
      expect(updated.status, SessionStatus.confirmed);
      expect(updated.meetingPlatform, 'Teams');
      expect(updated.meetingLink, 'https://example.test/session');
      expect(updated.id, session.id);
      expect(updated.title, session.title);
      expect(updated.person, session.person);
      expect(updated.description, session.description);
      expect(updated.date, session.date);
      expect(updated.time, session.time);
      expect(updated.avatarColor, session.avatarColor);
      expect(updated.initials, session.initials);
      expect(updated.profileImageUrl, session.profileImageUrl);
      expect(updated.canPublishLink, isTrue);
      expect(session.status, SessionStatus.awaitingLink);
      expect(session.meetingLink, isNull);
    },
  );

  test(
    'SKILL002 copyWith keeps existing optional values when arguments are null',
    () {
      // Arrange
      final confirmed = session.copyWith(
        status: SessionStatus.confirmed,
        meetingLink: 'https://example.test/session',
      );
      // Act
      final copied = confirmed.copyWith(
        status: null,
        meetingPlatform: null,
        meetingLink: null,
      );
      // Assert
      expect(copied.status, SessionStatus.confirmed);
      expect(copied.meetingLink, 'https://example.test/session');
      expect(copied.meetingPlatform, 'Google Meet');
      expect(identical(copied, confirmed), isFalse);
    },
  );
}

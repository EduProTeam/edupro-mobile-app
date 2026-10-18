import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/chat/models/group_model.dart';
import 'package:edupro_mobile_app/features/chat/models/message_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/chat_firebase_mocks.dart';

void main() {
  group('MessageModel', () {
    test('CHAT001 serializes sender details and an explicit timestamp', () {
      // Arrange
      final date = DateTime.utc(2026, 1, 2, 3, 4);
      final message = MessageModel(
        id: 'local-id',
        senderId: 'student',
        senderName: 'Student',
        senderProfileImageUrl: 'https://example.test/avatar.png',
        text: 'Can you explain algebra?',
        timestamp: date,
      );
      // Act
      final map = message.toMap();
      // Assert
      expect(map, {
        'senderId': 'student',
        'senderName': 'Student',
        'senderProfileImageUrl': 'https://example.test/avatar.png',
        'text': 'Can you explain algebra?',
        'timestamp': Timestamp.fromDate(date),
      });
    });

    test('CHAT002 requests a server timestamp when timestamp is absent', () {
      // Arrange
      final message = MessageModel(
        senderId: 'student',
        senderName: 'Student',
        senderProfileImageUrl: '',
        text: 'Hello',
      );
      // Act
      final map = message.toMap();
      // Assert
      expect(map['timestamp'], FieldValue.serverTimestamp());
    });

    test('CHAT003 deserializes all message fields from a snapshot', () {
      // Arrange
      final date = DateTime.utc(2026, 1, 2);
      final snapshot = chatSnapshot('message-1', {
        'senderId': 'student',
        'senderName': 'Student',
        'senderProfileImageUrl': 'avatar.png',
        'text': 'Hello',
        'timestamp': Timestamp.fromDate(date),
      });
      // Act
      final message = MessageModel.fromFirestore(snapshot);
      // Assert
      expect(message.id, 'message-1');
      expect(message.senderId, 'student');
      expect(message.senderName, 'Student');
      expect(message.senderProfileImageUrl, 'avatar.png');
      expect(message.text, 'Hello');
      expect(message.timestamp?.toUtc(), date);
    });

    test('CHAT004 defaults missing message data and pending timestamps', () {
      // Arrange
      final snapshot = chatSnapshot('missing', null);
      // Act
      final message = MessageModel.fromFirestore(snapshot);
      // Assert
      expect(message.senderId, isEmpty);
      expect(message.senderName, 'Unknown');
      expect(message.senderProfileImageUrl, isEmpty);
      expect(message.text, isEmpty);
      expect(message.timestamp, isNull);
    });
  });

  group('GroupModel', () {
    test('CHAT005 serializes all group fields and creation time', () {
      // Arrange
      final date = DateTime.utc(2026, 2, 1);
      final group = GroupModel(
        id: 'group-1',
        groupName: 'Math',
        description: 'Study together',
        category: 'Education',
        imageUrl: 'image',
        createdBy: 'owner',
        admins: ['owner'],
        members: ['owner', 'learner'],
        createdAt: date,
      );
      // Act
      final map = group.toMap();
      // Assert
      expect(map, {
        'groupName': 'Math',
        'description': 'Study together',
        'category': 'Education',
        'imageUrl': 'image',
        'createdBy': 'owner',
        'admins': ['owner'],
        'members': ['owner', 'learner'],
        'createdAt': Timestamp.fromDate(date),
      });
    });

    test('CHAT006 round trips persisted group fields', () {
      // Arrange
      final original = GroupModel(
        groupName: 'Math',
        description: 'Algebra',
        category: 'Education',
        imageUrl: 'image',
        createdBy: 'owner',
        admins: ['owner', 'helper'],
        members: ['owner', 'helper'],
        createdAt: DateTime.utc(2026, 2, 1),
      );
      // Act
      final restored = GroupModel.fromFirestore(
        chatSnapshot('group-1', original.toMap()),
      );
      // Assert
      expect(restored.id, 'group-1');
      expect(restored.toMap(), original.toMap());
    });

    test('CHAT007 treats legacy group creator as admin when admins absent', () {
      // Arrange
      final snapshot = chatSnapshot('legacy', {'createdBy': 'owner'});
      // Act
      final group = GroupModel.fromFirestore(snapshot);
      // Assert
      expect(group.admins, ['owner']);
      expect(group.members, isEmpty);
      expect(group.createdAt, isNull);
    });

    test('CHAT008 preserves an explicitly empty admin list', () {
      // Arrange
      final snapshot = chatSnapshot('group-1', {
        'createdBy': 'owner',
        'admins': <String>[],
      });
      // Act
      final group = GroupModel.fromFirestore(snapshot);
      // Assert
      expect(group.admins, isEmpty);
    });

    test('CHAT009 defaults missing group data without inventing an admin', () {
      // Arrange
      final snapshot = chatSnapshot('missing', null);
      // Act
      final group = GroupModel.fromFirestore(snapshot);
      // Assert
      expect(group.groupName, isEmpty);
      expect(group.description, isEmpty);
      expect(group.category, isEmpty);
      expect(group.imageUrl, isEmpty);
      expect(group.createdBy, isEmpty);
      expect(group.admins, isEmpty);
      expect(group.members, isEmpty);
      expect(group.toMap()['createdAt'], FieldValue.serverTimestamp());
    });
  });
}

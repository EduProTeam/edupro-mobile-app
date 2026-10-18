import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/chat/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/chat_firebase_mocks.dart';

void main() {
  late MockChatFirestore firestore;
  late MockChatAuth auth;
  late MockChatUser user;
  late MockChatCollection users;
  late MockChatCollection groups;
  late MockChatCollection messages;
  late MockChatDocument profile;
  late MockChatDocument group;
  late ChatService service;

  setUp(() {
    firestore = MockChatFirestore();
    auth = MockChatAuth();
    user = MockChatUser();
    users = MockChatCollection();
    groups = MockChatCollection();
    messages = MockChatCollection();
    profile = MockChatDocument();
    group = MockChatDocument();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('student-1');
    when(() => user.displayName).thenReturn('Account Name');
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => firestore.collection('groups')).thenReturn(groups);
    when(() => users.doc('student-1')).thenReturn(profile);
    when(() => groups.doc('group-1')).thenReturn(group);
    when(() => group.collection('messages')).thenReturn(messages);
    when(() => profile.get()).thenAnswer(
      (_) async => chatSnapshot('student-1', {
        'fullName': 'Profile Name',
        'profileImageUrl': 'avatar.png',
      }),
    );
    when(() => messages.add(any())).thenAnswer((_) async => MockChatDocument());
    service = ChatService(firestore: firestore, auth: auth);
  });

  test('CHAT010 rejects messages when no user is authenticated', () async {
    // Arrange
    when(() => auth.currentUser).thenReturn(null);
    // Act / Assert
    await expectLater(
      service.sendMessage('group-1', 'Hello'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('not logged in'),
        ),
      ),
    );
    verifyZeroInteractions(firestore);
  });

  test(
    'CHAT011 ignores whitespace-only messages without reading a profile',
    () async {
      // Arrange
      const text = ' \t\n ';
      // Act
      await service.sendMessage('group-1', text);
      // Assert
      verifyZeroInteractions(firestore);
      verifyNever(() => messages.add(any()));
    },
  );

  test(
    'CHAT012 sends trimmed text using the stored profile and server timestamp',
    () async {
      // Arrange
      const text = '  Hello classmates! \n';
      // Act
      await service.sendMessage('group-1', text);
      // Assert
      final saved =
          verify(() => messages.add(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(saved, {
        'senderId': 'student-1',
        'senderName': 'Profile Name',
        'senderProfileImageUrl': 'avatar.png',
        'text': 'Hello classmates!',
        'timestamp': FieldValue.serverTimestamp(),
      });
    },
  );

  test(
    'CHAT013 falls back to account display name when the profile is absent',
    () async {
      // Arrange
      when(
        () => profile.get(),
      ).thenAnswer((_) async => chatSnapshot('student-1', null));
      // Act
      await service.sendMessage('group-1', 'Hello');
      // Assert
      final saved =
          verify(() => messages.add(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(saved['senderName'], 'Account Name');
      expect(saved['senderProfileImageUrl'], isEmpty);
    },
  );

  test(
    'CHAT014 falls back to User when profile name is blank and display name null',
    () async {
      // Arrange
      when(() => user.displayName).thenReturn(null);
      when(
        () => profile.get(),
      ).thenAnswer((_) async => chatSnapshot('student-1', {'fullName': '  '}));
      // Act
      await service.sendMessage('group-1', 'Hello');
      // Assert
      final saved =
          verify(() => messages.add(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(saved['senderName'], 'User');
    },
  );

  test(
    'CHAT015 propagates profile read failures without sending a message',
    () async {
      // Arrange
      final error = FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
      );
      when(() => profile.get()).thenThrow(error);
      // Act / Assert
      await expectLater(
        service.sendMessage('group-1', 'Hello'),
        throwsA(same(error)),
      );
      verifyNever(() => messages.add(any()));
    },
  );

  test('CHAT016 propagates message write failures', () async {
    // Arrange
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    when(() => messages.add(any())).thenThrow(error);
    // Act / Assert
    await expectLater(
      service.sendMessage('group-1', 'Hello'),
      throwsA(same(error)),
    );
  });

  test('CHAT017 maps ordered message snapshots to message models', () async {
    // Arrange
    final query = MockChatQuery();
    when(
      () => messages.orderBy('timestamp', descending: true),
    ).thenReturn(query);
    when(() => query.snapshots()).thenAnswer(
      (_) => Stream.value(
        chatQuerySnapshot({
          'message-2': {'text': 'Latest', 'senderId': 'a'},
          'message-1': {'text': 'Earlier', 'senderId': 'b'},
        }),
      ),
    );
    // Act
    final result = await service.getMessages('group-1').first;
    // Assert
    expect(result.map((message) => message.id), ['message-2', 'message-1']);
    expect(result.map((message) => message.text), ['Latest', 'Earlier']);
    verify(() => messages.orderBy('timestamp', descending: true)).called(1);
  });

  test('CHAT018 emits an empty list for groups without messages', () async {
    // Arrange
    final query = MockChatQuery();
    when(
      () => messages.orderBy('timestamp', descending: true),
    ).thenReturn(query);
    when(
      () => query.snapshots(),
    ).thenAnswer((_) => Stream.value(chatQuerySnapshot({})));
    // Act
    final result = await service.getMessages('group-1').first;
    // Assert
    expect(result, isEmpty);
  });

  test('CHAT019 forwards message stream errors to the subscriber', () async {
    // Arrange
    final query = MockChatQuery();
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    when(
      () => messages.orderBy('timestamp', descending: true),
    ).thenReturn(query);
    when(() => query.snapshots()).thenAnswer((_) => Stream.error(error));
    // Act / Assert
    await expectLater(service.getMessages('group-1'), emitsError(same(error)));
  });
}

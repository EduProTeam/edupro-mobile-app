import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/chat/models/group_model.dart';
import 'package:edupro_mobile_app/features/chat/services/group_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/chat_firebase_mocks.dart';

void main() {
  late MockChatFirestore firestore;
  late MockChatAuth auth;
  late MockChatCollection groups;
  late MockChatDocument document;
  late MockChatTransaction transaction;
  late GroupService service;

  Map<String, dynamic> data({
    List<String> members = const ['student-1', 'student-2'],
    List<String> admins = const ['student-1'],
    String creator = 'student-1',
  }) => {'members': members, 'admins': admins, 'createdBy': creator};

  GroupModel model({
    List<String> members = const ['student-1', 'student-2'],
    List<String> admins = const ['student-1'],
    String creator = 'student-1',
  }) => GroupModel(
    id: 'group-1',
    groupName: 'Math',
    description: 'Study',
    category: 'Education',
    imageUrl: '',
    createdBy: creator,
    admins: admins,
    members: members,
  );

  void stubData(Map<String, dynamic>? groupData, {bool exists = true}) {
    final snapshot = chatSnapshot('group-1', groupData, exists: exists);
    when(() => document.get()).thenAnswer((_) async => snapshot);
    when(() => transaction.get(document)).thenAnswer((_) async => snapshot);
  }

  setUpAll(() {
    registerFallbackValue((Transaction transaction) async => null);
  });

  setUp(() {
    firestore = MockChatFirestore();
    auth = MockChatAuth();
    groups = MockChatCollection();
    document = MockChatDocument();
    transaction = MockChatTransaction();
    stubChatUser(auth);
    when(() => firestore.collection('groups')).thenReturn(groups);
    when(() => groups.doc('group-1')).thenReturn(document);
    when(() => groups.add(any())).thenAnswer((_) async => document);
    when(() => document.update(any())).thenAnswer((_) async {});
    when(() => document.delete()).thenAnswer((_) async {});
    when(() => transaction.update(document, any())).thenReturn(transaction);
    when(() => transaction.delete(document)).thenReturn(transaction);
    // These callbacks have implicit null returns, so Dart infers Null for T.
    when(() => firestore.runTransaction<Null>(any())).thenAnswer((
      invocation,
    ) async {
      final operation =
          invocation.positionalArguments.first as TransactionHandler<Null>;
      return await operation(transaction);
    });
    stubData(data());
    service = GroupService(firestore: firestore, auth: auth);
  });

  test(
    'CHAT020 creates a trimmed group with the creator as member and admin',
    () async {
      // Arrange
      const name = '  Algebra  ';
      // Act
      await service.createGroup(
        groupName: name,
        description: '  Study group  ',
        category: 'Math',
        imageUrl: ' image.png ',
      );
      // Assert
      final written =
          verify(() => groups.add(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(written, {
        'groupName': 'Algebra',
        'description': 'Study group',
        'category': 'Math',
        'imageUrl': 'image.png',
        'createdBy': 'student-1',
        'admins': ['student-1'],
        'members': ['student-1'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    },
  );

  test('CHAT021 prevents group creation when signed out', () async {
    // Arrange
    when(() => auth.currentUser).thenReturn(null);
    // Act / Assert
    await expectLater(
      service.createGroup(
        groupName: 'Math',
        description: 'Study',
        category: 'Math',
        imageUrl: '',
      ),
      throwsException,
    );
    verifyZeroInteractions(firestore);
  });

  test('CHAT022 joins a group through an atomic member union', () async {
    // Arrange / Act
    await service.joinGroup('group-1');
    // Assert
    verify(
      () => document.update({
        'members': FieldValue.arrayUnion(['student-1']),
      }),
    ).called(1);
  });

  test(
    'CHAT023 checks membership and admin status against their own lists',
    () {
      // Arrange
      final group = model(admins: ['student-2']);
      // Act
      final member = service.isCurrentUserMember(group);
      final admin = service.isCurrentUserAdmin(group);
      // Assert
      expect(member, isTrue);
      expect(
        admin,
        isFalse,
      ); // Being the creator alone does not grant admin access.
    },
  );

  test(
    'CHAT024 recognizes promoted admins and signed-out membership checks',
    () {
      // Arrange
      final group = model(creator: 'student-2');
      // Act / Assert
      expect(service.isCurrentUserAdmin(group), isTrue);
      when(() => auth.currentUser).thenReturn(null);
      expect(service.currentUserId, isNull);
      expect(service.isCurrentUserAdmin(group), isFalse);
      expect(service.isCurrentUserMember(group), isFalse);
    },
  );

  test('CHAT025 rejects blank group names before reading storage', () async {
    // Arrange / Act / Assert
    await expectLater(
      service.updateGroupDetails(
        groupId: 'group-1',
        groupName: ' \n',
        description: 'Study',
        category: 'Math',
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Group name cannot be empty'),
        ),
      ),
    );
    verifyZeroInteractions(firestore);
  });

  test('CHAT026 rejects blank descriptions before reading storage', () async {
    // Arrange / Act / Assert
    await expectLater(
      service.updateGroupDetails(
        groupId: 'group-1',
        groupName: 'Math',
        description: ' \t',
        category: 'Math',
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Description cannot be empty'),
        ),
      ),
    );
    verifyZeroInteractions(firestore);
  });

  test('CHAT027 permits admins to update trimmed group details', () async {
    // Arrange / Act
    await service.updateGroupDetails(
      groupId: 'group-1',
      groupName: ' Algebra ',
      description: ' Practice ',
      category: 'Math',
    );
    // Assert
    verify(
      () => document.update({
        'groupName': 'Algebra',
        'description': 'Practice',
        'category': 'Math',
      }),
    ).called(1);
  });

  test(
    'CHAT028 denies group updates to a creator removed from admins',
    () async {
      // Arrange
      stubData(data(admins: ['student-2']));
      // Act / Assert
      await expectLater(
        service.updateGroupDetails(
          groupId: 'group-1',
          groupName: 'Math',
          description: 'Study',
          category: 'Math',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Only group admins'),
          ),
        ),
      );
      verifyNever(() => document.update(any()));
    },
  );

  test('CHAT029 rejects updates when the group no longer exists', () async {
    // Arrange
    stubData(null, exists: false);
    // Act / Assert
    await expectLater(
      service.updateGroupDetails(
        groupId: 'group-1',
        groupName: 'Math',
        description: 'Study',
        category: 'Math',
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Group not found'),
        ),
      ),
    );
    verifyNever(() => document.update(any()));
  });

  test(
    'CHAT030 supports deleting legacy groups owned by the authenticated user',
    () async {
      // Arrange
      stubData({'createdBy': 'student-1'});
      // Act
      await service.deleteGroup('group-1');
      // Assert
      verify(() => document.delete()).called(1);
    },
  );

  test('CHAT031 denies deletion by non-admin members', () async {
    // Arrange
    stubData(data(admins: ['student-2']));
    // Act / Assert
    await expectLater(
      service.deleteGroup('group-1'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Only an admin'),
        ),
      ),
    );
    verifyNever(() => document.delete());
  });

  test('CHAT032 rejects null group data without deleting anything', () async {
    // Arrange
    stubData(null);
    // Act / Assert
    await expectLater(
      service.deleteGroup('group-1'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Group data not found'),
        ),
      ),
    );
    verifyNever(() => document.delete());
  });

  test(
    'CHAT033 removes a departing member and preserves the remaining admin',
    () async {
      // Arrange
      stubData(data(admins: ['student-2'], creator: 'student-2'));
      // Act
      await service.exitGroup('group-1');
      // Assert
      verify(
        () => transaction.update(document, {
          'members': ['student-2'],
          'admins': ['student-2'],
          'createdBy': 'student-2',
        }),
      ).called(1);
      verifyNever(() => transaction.delete(document));
    },
  );

  test(
    'CHAT034 promotes the sole remaining member when the creator exits',
    () async {
      // Arrange / Act
      await service.exitGroup('group-1');
      // Assert
      verify(
        () => transaction.update(document, {
          'members': ['student-2'],
          'admins': ['student-2'],
          'createdBy': 'student-2',
        }),
      ).called(1);
    },
  );

  test('CHAT035 deletes the group when its last member exits', () async {
    // Arrange
    stubData(data(members: ['student-1']));
    // Act
    await service.exitGroup('group-1');
    // Assert
    verify(() => transaction.delete(document)).called(1);
    verifyNever(() => transaction.update(document, any()));
  });

  test('CHAT036 prevents nonmembers from exiting a group', () async {
    // Arrange
    stubData(
      data(members: ['student-2'], admins: ['student-2'], creator: 'student-2'),
    );
    // Act / Assert
    await expectLater(
      service.exitGroup('group-1'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('not a member'),
        ),
      ),
    );
    verifyNever(() => transaction.update(document, any()));
    verifyNever(() => transaction.delete(document));
  });

  test(
    'CHAT037 removes stale admins and chooses a remaining member as admin',
    () async {
      // Arrange
      stubData(
        data(
          members: ['student-1', 'student-2', 'student-3'],
          admins: ['student-1', 'stale-user'],
        ),
      );
      // Act
      await service.exitGroup('group-1');
      // Assert
      final updated =
          verify(
                () => transaction.update(document, captureAny()),
              ).captured.single
              as Map<Object, Object?>;
      expect(updated['members'], ['student-2', 'student-3']);
      final admins = updated['admins'] as List<String>;
      expect(admins, hasLength(1));
      expect(updated['members'], contains(admins.single));
      expect(updated['createdBy'], admins.single);
    },
  );

  test('CHAT038 allows admins to promote an existing member', () async {
    // Arrange / Act
    await service.makeMemberAdmin(groupId: 'group-1', memberId: 'student-2');
    // Assert
    verify(
      () => transaction.update(document, {
        'admins': ['student-1', 'student-2'],
      }),
    ).called(1);
  });

  test(
    'CHAT039 does not write when a selected member is already an admin',
    () async {
      // Arrange / Act
      await service.makeMemberAdmin(groupId: 'group-1', memberId: 'student-1');
      // Assert
      verifyNever(() => transaction.update(document, any()));
    },
  );

  test('CHAT040 rejects promotion by non-admins', () async {
    // Arrange
    stubData(data(admins: ['student-2']));
    // Act / Assert
    await expectLater(
      service.makeMemberAdmin(groupId: 'group-1', memberId: 'student-1'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Only an admin'),
        ),
      ),
    );
    verifyNever(() => transaction.update(document, any()));
  });

  test('CHAT041 rejects promotion of a user outside the group', () async {
    // Arrange / Act / Assert
    await expectLater(
      service.makeMemberAdmin(groupId: 'group-1', memberId: 'outsider'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('not a member'),
        ),
      ),
    );
    verifyNever(() => transaction.update(document, any()));
  });

  test('CHAT042 returns no member profiles for an empty group', () async {
    // Arrange
    final group = model(members: []);
    // Act
    final members = await service.getGroupMembers(group);
    // Assert
    expect(members, isEmpty);
    verifyZeroInteractions(firestore);
  });

  test(
    'CHAT043 orders admins first then names and falls back to email or unknown',
    () async {
      // Arrange
      final users = MockChatCollection();
      when(() => firestore.collection('users')).thenReturn(users);
      final profiles = <String, Map<String, dynamic>?>{
        'student-1': {'fullName': ' Zoe ', 'email': ' z@example.test '},
        'student-2': {'fullName': ' Alice ', 'email': 'a@example.test'},
        'student-3': {'fullName': ' ', 'email': ' bob@example.test '},
        'student-4': null,
      };
      for (final entry in profiles.entries) {
        final ref = MockChatDocument();
        when(() => users.doc(entry.key)).thenReturn(ref);
        when(
          () => ref.get(),
        ).thenAnswer((_) async => chatSnapshot(entry.key, entry.value));
      }
      // Act
      final members = await service.getGroupMembers(
        model(members: profiles.keys.toList()),
      );
      // Assert
      expect(members.map((member) => member.fullName), [
        'Zoe',
        'Alice',
        'bob',
        'Unknown User',
      ]);
      expect(members.first.isAdmin, isTrue);
      expect(members.skip(1).every((member) => !member.isAdmin), isTrue);
      expect(members.first.email, 'z@example.test');
      expect(members.last.email, isEmpty);
    },
  );

  group('filtered group streams', () {
    setUp(() {
      final query = MockChatQuery();
      when(
        () => groups.orderBy('createdAt', descending: true),
      ).thenReturn(query);
      when(() => query.snapshots()).thenAnswer(
        (_) => Stream.value(
          chatQuerySnapshot({
            'math': {
              'groupName': 'Algebra Club',
              'description': 'Practice together',
              'category': 'Math',
              'members': ['student-1'],
              'createdBy': 'other',
            },
            'coding': {
              'groupName': 'Developers',
              'description': 'Learn Flutter',
              'category': 'Programming',
              'members': ['other'],
              'createdBy': 'student-1',
            },
            'art': {
              'groupName': 'Artists',
              'description': 'Painting',
              'category': 'Art',
              'members': ['other'],
              'createdBy': 'other',
            },
          }),
        ),
      );
    });

    test(
      'CHAT044 includes joined and created groups when filtering my groups',
      () async {
        // Arrange / Act
        final result = await service
            .getFilteredGroups(onlyMyGroups: true)
            .first;
        // Assert
        expect(result.map((group) => group.id), ['math', 'coding']);
      },
    );

    test(
      'CHAT045 matches trimmed case-insensitive description searches',
      () async {
        // Arrange / Act
        final result = await service
            .getFilteredGroups(searchQuery: ' FLUTTER ')
            .first;
        // Assert
        expect(result.single.id, 'coding');
      },
    );

    test('CHAT046 combines category membership and name filters', () async {
      // Arrange / Act
      final result = await service
          .getFilteredGroups(
            searchQuery: 'CLUB',
            category: 'mAtH',
            onlyMyGroups: true,
          )
          .first;
      // Assert
      expect(result.single.id, 'math');
    });

    test('CHAT047 returns an empty list when no group matches', () async {
      // Arrange / Act
      final result = await service
          .getFilteredGroups(searchQuery: 'Physics')
          .first;
      // Assert
      expect(result, isEmpty);
    });

    test('CHAT048 searches the category as well as group text', () async {
      // Arrange / Act
      final result = await service
          .getFilteredGroups(searchQuery: 'programming')
          .first;
      // Assert
      expect(result.single.id, 'coding');
    });
  });

  test('CHAT049 watchGroup emits null for deleted groups', () async {
    // Arrange
    when(() => document.snapshots()).thenAnswer(
      (_) => Stream.value(chatSnapshot('group-1', null, exists: false)),
    );
    // Act
    final result = await service.watchGroup('group-1').first;
    // Assert
    expect(result, isNull);
  });

  test('CHAT050 propagates group write failures', () async {
    // Arrange
    final error = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
    when(() => document.update(any())).thenThrow(error);
    // Act / Assert
    await expectLater(service.joinGroup('group-1'), throwsA(same(error)));
  });
}

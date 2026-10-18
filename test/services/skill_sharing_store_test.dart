import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/skill_sharing/models/skill_models.dart';
import 'package:edupro_mobile_app/features/skill_sharing/services/skill_sharing_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/chat_firebase_mocks.dart';

SkillRequest request({String? owner = 'owner', String id = 'request-1'}) =>
    SkillRequest(
      id: id,
      ownerId: owner,
      requester: 'Owner',
      role: 'Student',
      title: 'Algebra',
      description: 'Equations',
      tags: const ['Math'],
      date: DateTime.utc(2026, 3, 1),
      time: '10:00',
      level: SkillLevel.beginner,
      postedAgo: 'Posted now',
      avatarColor: Colors.blue,
      initials: 'OW',
    );

TutorOffer offer({String sender = 'tutor', String recipient = 'student-1'}) =>
    TutorOffer(
      id: 'offer-1',
      senderId: sender,
      recipientId: recipient,
      name: 'Tutor',
      title: 'Math Tutor',
      rating: 0,
      reviews: 0,
      sessions: 0,
      message: 'I can help',
      available: 'Tomorrow',
      price: 0,
      tags: const ['Math'],
      avatarColor: Colors.blue,
      initials: 'TU',
      profileImageUrl: 'tutor.png',
    );

void main() {
  group('offline skill store', () {
    late SkillSharingStore store;
    setUp(() => store = SkillSharingStore());
    tearDown(() => store.dispose());

    test('SKILL003 toggles saved IDs independently and notifies listeners', () {
      // Arrange
      var notifications = 0;
      store.addListener(() => notifications++);
      // Act
      store.toggleSaved('first');
      store.toggleSaved('second');
      store.toggleSaved('first');
      // Assert
      expect(store.isSaved('first'), isFalse);
      expect(store.isSaved('second'), isTrue);
      expect(store.isSaved('unknown'), isFalse);
      expect(notifications, 3);
    });

    test(
      'SKILL004 offline offers mark only their request without duplicates',
      () async {
        // Arrange
        final skillRequest = request(owner: null);
        // Act
        await store.sendOffer(skillRequest);
        await store.sendOffer(skillRequest);
        // Assert
        expect(store.hasOffered(skillRequest.id), isTrue);
        expect(store.hasOffered('another-request'), isFalse);
        expect(store.sentOffers, isEmpty);
      },
    );

    test('SKILL005 rejects request creation without authentication', () async {
      // Arrange / Act / Assert
      await expectLater(
        store.addSkillRequest(
          title: 'Math',
          description: 'Study',
          tags: [],
          date: DateTime.utc(2026, 1, 1),
          time: '10:00',
          level: SkillLevel.beginner,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('sign in'),
          ),
        ),
      );
    });

    test('SKILL006 rescheduling a tutor replaces the previous session', () {
      // Arrange
      final tutor = offer();
      store.addScheduledSession(
        tutor: tutor,
        date: DateTime.utc(2026, 1, 1),
        time: '10:00',
        platform: 'Meet',
      );
      // Act
      store.addScheduledSession(
        tutor: tutor,
        date: DateTime.utc(2026, 1, 2),
        time: '12:00',
        platform: 'Teams',
      );
      // Assert
      final scheduled = store.sessions
          .where((session) => session.id == 'scheduled-offer-1')
          .toList();
      expect(scheduled, hasLength(1));
      expect(store.sessions.first.id, 'scheduled-offer-1');
      expect(scheduled.single.date, DateTime.utc(2026, 1, 2));
      expect(scheduled.single.time, '12:00');
      expect(scheduled.single.meetingPlatform, 'Teams');
      expect(scheduled.single.status, SessionStatus.awaitingLink);
      expect(scheduled.single.person, tutor.name);
      expect(scheduled.single.profileImageUrl, 'tutor.png');
    });

    test(
      'SKILL007 publishing a local link confirms only the selected session',
      () async {
        // Arrange
        final before = store.sessions.first;
        // Act
        await store.publishMeetingLink(
          sessionId: 'ui-session',
          platform: 'Teams',
          link: 'https://example.test/meeting',
        );
        // Assert
        final updated = store.sessions.singleWhere(
          (session) => session.id == 'ui-session',
        );
        expect(updated.status, SessionStatus.confirmed);
        expect(updated.meetingLink, 'https://example.test/meeting');
        expect(updated.meetingPlatform, 'Teams');
        expect(store.sessions.first, same(before));
      },
    );

    test(
      'SKILL008 ignores a missing local session without notifying',
      () async {
        // Arrange
        var notifications = 0;
        store.addListener(() => notifications++);
        final before = store.sessions;
        // Act
        await store.publishMeetingLink(
          sessionId: 'missing',
          platform: 'Meet',
          link: 'https://example.test',
        );
        // Assert
        expect(store.sessions, before);
        expect(notifications, 0);
      },
    );

    test('SKILL009 exposes immutable session and offer lists', () {
      // Arrange
      final sessions = store.sessions;
      final sent = store.sentOffers;
      final received = store.receivedOffers;
      // Act / Assert
      expect(() => sessions.clear(), throwsUnsupportedError);
      expect(() => sent.add(offer()), throwsUnsupportedError);
      expect(() => received.clear(), throwsUnsupportedError);
      expect(store.sessions, isNotEmpty);
    });

    test(
      'SKILL010 formats boundary calendar dates with zero-padded month and day',
      () {
        // Arrange / Act
        final leapDay = store.formatDateForStorage(DateTime(2024, 2, 29));
        final newYear = store.formatDateForStorage(DateTime(2026, 1, 1));
        // Assert
        expect(leapDay, '2024-02-29');
        expect(newYear, '2026-01-01');
      },
    );

    test('SKILL011 stores independent saved state in separate instances', () {
      // Arrange
      final other = SkillSharingStore();
      addTearDown(other.dispose);
      // Act
      store.toggleSaved('request-1');
      // Assert
      expect(store.isSaved('request-1'), isTrue);
      expect(other.isSaved('request-1'), isFalse);
    });
  });

  group('skill store with mocked Firebase', () {
    late MockChatAuth auth;
    late MockChatUser user;
    late MockChatFirestore firestore;
    late MockChatCollection requests;
    late MockChatCollection offers;
    late MockChatDocument profile;
    late MockChatDocument offerRef;
    late MockChatQuery requestQuery;
    late MockChatQuery receivedQuery;
    late MockChatQuery sentQuery;
    late StreamController<QuerySnapshot<Map<String, dynamic>>> requestStream;
    late StreamController<QuerySnapshot<Map<String, dynamic>>> receivedStream;
    late StreamController<QuerySnapshot<Map<String, dynamic>>> sentStream;
    late SkillSharingStore store;

    Map<String, dynamic> offerData({
      String status = 'accepted',
      String recipient = 'student-1',
      String? link,
    }) => {
      'requestId': 'request-1',
      'senderId': 'tutor',
      'recipientId': recipient,
      'senderName': 'Tutor Name',
      'requestTitle': 'Algebra',
      'requestDescription': 'Equations',
      'recipientName': 'Skill Owner',
      'status': status,
      'scheduledDate': Timestamp.fromDate(DateTime.utc(2026, 3, 1)),
      'scheduledTime': '10:00',
      'meetingPlatform': 'Teams',
      'meetingLink': link,
    };

    setUp(() {
      auth = MockChatAuth();
      user = MockChatUser();
      firestore = MockChatFirestore();
      requests = MockChatCollection();
      offers = MockChatCollection();
      profile = MockChatDocument();
      offerRef = MockChatDocument();
      final users = MockChatCollection();
      requestQuery = MockChatQuery();
      receivedQuery = MockChatQuery();
      sentQuery = MockChatQuery();
      requestStream = StreamController.broadcast(sync: true);
      receivedStream = StreamController.broadcast(sync: true);
      sentStream = StreamController.broadcast(sync: true);
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.uid).thenReturn('student-1');
      when(() => user.displayName).thenReturn('Account Name');
      when(() => user.email).thenReturn('student@example.test');
      when(() => user.photoURL).thenReturn('account.png');
      when(() => firestore.collection('users')).thenReturn(users);
      when(() => users.doc('student-1')).thenReturn(profile);
      when(() => profile.get()).thenAnswer(
        (_) async => chatSnapshot('student-1', {
          'fullName': ' Profile Name ',
          'professionalTitle': ' Math Tutor ',
          'profileImageUrl': ' profile.png ',
        }),
      );
      when(() => firestore.collection('skill_requests')).thenReturn(requests);
      when(() => firestore.collection('skill_offers')).thenReturn(offers);
      when(
        () => requests.orderBy('createdAt', descending: true),
      ).thenReturn(requestQuery);
      when(
        () => requestQuery.snapshots(),
      ).thenAnswer((_) => requestStream.stream);
      when(
        () => offers.where('senderId', isEqualTo: 'student-1'),
      ).thenReturn(sentQuery);
      when(
        () => offers.where('recipientId', isEqualTo: 'student-1'),
      ).thenReturn(receivedQuery);
      when(() => sentQuery.snapshots()).thenAnswer((_) => sentStream.stream);
      when(
        () => receivedQuery.snapshots(),
      ).thenAnswer((_) => receivedStream.stream);
      when(() => offers.doc(any())).thenReturn(offerRef);
      when(() => offerRef.set(any())).thenAnswer((_) async {});
      when(() => offerRef.update(any())).thenAnswer((_) async {});
      when(
        () => requests.add(any()),
      ).thenAnswer((_) async => MockChatDocument());
      store = SkillSharingStore.withFirebase(auth, firestore);
    });

    tearDown(() async {
      store.dispose();
      await requestStream.close();
      await receivedStream.close();
      await sentStream.close();
    });

    test('SKILL012 rejects sending an offer to an owned request', () async {
      // Arrange
      final owned = request(owner: 'student-1');
      // Act / Assert
      expect(store.isOwnRequest(owned), isTrue);
      await expectLater(store.sendOffer(owned), throwsA(isA<StateError>()));
      verifyZeroInteractions(firestore);
      expect(store.hasOffered(owned.id), isFalse);
    });

    test(
      'SKILL013 sends an offer with stable ID and trimmed profile details',
      () async {
        // Arrange
        final skillRequest = request();
        // Act
        await store.sendOffer(skillRequest);
        // Assert
        verify(() => offers.doc('request-1_student-1')).called(1);
        final saved =
            verify(() => offerRef.set(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(saved['senderName'], 'Profile Name');
        expect(saved['senderTitle'], 'Math Tutor');
        expect(saved['profileImageUrl'], 'profile.png');
        expect(saved['senderId'], 'student-1');
        expect(saved['recipientId'], 'owner');
        expect(saved['requestId'], 'request-1');
        expect(saved['status'], 'pending');
        expect(saved['available'], '2026-03-01 • 10:00');
        expect(saved['createdAt'], FieldValue.serverTimestamp());
        expect(store.hasOffered('request-1'), isTrue);
      },
    );

    test(
      'SKILL014 falls back to account identity when the profile is absent',
      () async {
        // Arrange
        when(
          () => profile.get(),
        ).thenAnswer((_) async => chatSnapshot('student-1', null));
        // Act
        await store.sendOffer(request());
        // Assert
        final saved =
            verify(() => offerRef.set(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(saved['senderName'], 'Account Name');
        expect(saved['senderTitle'], 'Skill tutor');
        expect(saved['profileImageUrl'], 'account.png');
      },
    );

    test(
      'SKILL015 propagates offer failures without marking the request offered',
      () async {
        // Arrange
        final error = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
        );
        when(() => offerRef.set(any())).thenThrow(error);
        // Act / Assert
        await expectLater(store.sendOffer(request()), throwsA(same(error)));
        expect(store.hasOffered('request-1'), isFalse);
      },
    );

    test(
      'SKILL016 adds trimmed requests with dates levels tags and owner identity',
      () async {
        // Arrange
        final date = DateTime.utc(2026, 3, 1);
        // Act
        await store.addSkillRequest(
          title: ' Algebra ',
          description: ' Equations ',
          tags: ['Math'],
          date: date,
          time: '10:00',
          level: SkillLevel.advanced,
        );
        // Assert
        final saved =
            verify(() => requests.add(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(saved['ownerId'], 'student-1');
        expect(saved['requester'], 'Profile Name');
        expect(saved['role'], 'Math Tutor');
        expect(saved['title'], 'Algebra');
        expect(saved['description'], 'Equations');
        expect(saved['tags'], ['Math']);
        expect(saved['date'], Timestamp.fromDate(date));
        expect(saved['time'], '10:00');
        expect(saved['level'], 'advanced');
        expect(saved['createdAt'], FieldValue.serverTimestamp());
      },
    );

    test('SKILL017 only the request recipient may accept an offer', () async {
      // Arrange
      final otherOffer = offer(recipient: 'another-owner');
      // Act / Assert
      await expectLater(
        store.acceptOffer(
          offer: otherOffer,
          date: DateTime.utc(2026, 3, 1),
          time: '10:00',
          platform: 'Teams',
        ),
        throwsA(isA<StateError>()),
      );
      verifyNever(() => offerRef.update(any()));
    });

    test('SKILL018 offer senders cannot accept their own offers', () async {
      // Arrange
      final ownOffer = offer(sender: 'student-1');
      // Act / Assert
      await expectLater(
        store.acceptOffer(
          offer: ownOffer,
          date: DateTime.utc(2026, 3, 1),
          time: '10:00',
          platform: 'Teams',
        ),
        throwsA(isA<StateError>()),
      );
      verifyNever(() => offerRef.update(any()));
    });

    test(
      'SKILL019 accepting an offer stores scheduling and clears previous meeting links',
      () async {
        // Arrange
        final date = DateTime.utc(2026, 3, 1);
        // Act
        await store.acceptOffer(
          offer: offer(),
          date: date,
          time: '10:00',
          platform: 'Teams',
        );
        // Assert
        verify(
          () => offerRef.update({
            'status': 'accepted',
            'scheduledDate': Timestamp.fromDate(date),
            'scheduledTime': '10:00',
            'meetingPlatform': 'Teams',
            'meetingLink': FieldValue.delete(),
            'acceptedAt': FieldValue.serverTimestamp(),
          }),
        ).called(1);
      },
    );

    test(
      'SKILL020 rejecting an offer clears scheduling and link fields',
      () async {
        // Arrange / Act
        await store.rejectOffer(offer());
        // Assert
        verify(
          () => offerRef.update({
            'status': 'rejected',
            'scheduledDate': FieldValue.delete(),
            'scheduledTime': FieldValue.delete(),
            'meetingPlatform': FieldValue.delete(),
            'meetingLink': FieldValue.delete(),
            'rejectedAt': FieldValue.serverTimestamp(),
          }),
        ).called(1);
      },
    );

    test('SKILL021 prevents another owner from rejecting an offer', () async {
      // Arrange / Act / Assert
      await expectLater(
        store.rejectOffer(offer(recipient: 'other')),
        throwsA(isA<StateError>()),
      );
      verifyNever(() => offerRef.update(any()));
    });

    test('SKILL022 skips remote initialization while signed out', () async {
      // Arrange
      when(() => auth.currentUser).thenReturn(null);
      final original = List<SkillRequest>.from(store.requests);
      // Act
      await store.initializeRemote();
      // Assert
      expect(store.requests, original);
      verifyZeroInteractions(firestore);
    });

    test(
      'SKILL023 initializes remote subscriptions once per authenticated user',
      () async {
        // Arrange / Act
        await store.initializeRemote();
        await store.initializeRemote();
        // Assert
        expect(store.requests, isEmpty);
        expect(store.sessions, isEmpty);
        verify(() => requestQuery.snapshots()).called(1);
        verify(() => sentQuery.snapshots()).called(1);
        verify(() => receivedQuery.snapshots()).called(1);
      },
    );

    test(
      'SKILL024 maps requests and defaults invalid optional document fields',
      () async {
        // Arrange
        await store.initializeRemote();
        // Act
        requestStream.add(
          chatQuerySnapshot({
            'request-1': {
              'requester': '  Jane Doe  ',
              'ownerId': ' owner ',
              'role': ' ',
              'title': '',
              'description': null,
              'tags': ['Math', 12, null],
              'date': Timestamp.fromDate(DateTime.utc(2026, 3, 1)),
              'level': 'unrecognized',
              'profileImageUrl': ' ',
            },
          }),
        );
        // Assert
        final loaded = store.requests.single;
        expect(loaded.id, 'request-1');
        expect(loaded.requester, 'Jane Doe');
        expect(loaded.ownerId, 'owner');
        expect(loaded.initials, 'JD');
        expect(loaded.role, 'Student');
        expect(loaded.title, 'Skill request');
        expect(loaded.description, isEmpty);
        expect(loaded.tags, ['Math']);
        expect(loaded.date.toUtc(), DateTime.utc(2026, 3, 1));
        expect(loaded.level, SkillLevel.beginner);
        expect(loaded.profileImageUrl, isNull);
        expect(loaded.time, 'Time not specified');
        expect(loaded.postedAgo, 'Posted now');
      },
    );

    test(
      'SKILL025 creates sessions only from accepted received and sent offers',
      () async {
        // Arrange
        await store.initializeRemote();
        // Act
        receivedStream.add(
          chatQuerySnapshot({
            'accepted-received': offerData(),
            'pending': offerData(status: 'pending'),
            'rejected': offerData(status: 'rejected'),
          }),
        );
        sentStream.add(
          chatQuerySnapshot({
            'accepted-sent': offerData(
              recipient: 'other',
              link: 'https://example.test',
            ),
          }),
        );
        // Assert
        expect(store.sessions, hasLength(2));
        final ownerSession = store.sessions.first;
        final tutorSession = store.sessions.last;
        expect(ownerSession.id, 'accepted-received');
        expect(ownerSession.person, 'Tutor Name');
        expect(ownerSession.canPublishLink, isTrue);
        expect(ownerSession.status, SessionStatus.awaitingLink);
        expect(ownerSession.date.toUtc(), DateTime.utc(2026, 3, 1));
        expect(ownerSession.time, '10:00');
        expect(ownerSession.title, 'Algebra');
        expect(tutorSession.id, 'accepted-sent');
        expect(tutorSession.person, 'Skill Owner');
        expect(tutorSession.canPublishLink, isFalse);
        expect(tutorSession.status, SessionStatus.confirmed);
        expect(tutorSession.meetingLink, 'https://example.test');
      },
    );

    test(
      'SKILL026 filters received offers by request and resolves sent offers',
      () async {
        // Arrange
        await store.initializeRemote();
        receivedStream.add(
          chatQuerySnapshot({
            'offer-1': offerData(),
            'offer-2': {...offerData(), 'requestId': 'other-request'},
          }),
        );
        sentStream.add(chatQuerySnapshot({'sent-1': offerData()}));
        // Act
        final received = store.offersForRequest('request-1');
        final sent = store.sentOfferForRequest('request-1');
        // Assert
        expect(received.single.id, 'offer-1');
        expect(store.offersForRequest('missing'), isEmpty);
        expect(sent?.id, 'sent-1');
        expect(store.sentOfferForRequest('missing'), isNull);
        expect(store.hasOffered('request-1'), isTrue);
      },
    );

    test(
      'SKILL027 replaces offered request tracking on sent-offer snapshots',
      () async {
        // Arrange
        await store.initializeRemote();
        sentStream.add(chatQuerySnapshot({'sent-1': offerData()}));
        expect(store.hasOffered('request-1'), isTrue);
        // Act
        sentStream.add(chatQuerySnapshot({}));
        // Assert
        expect(store.hasOffered('request-1'), isFalse);
        expect(store.sentOffers, isEmpty);
        expect(store.sessions, isEmpty);
      },
    );

    test(
      'SKILL028 defaults unknown offer status and missing descriptive fields',
      () async {
        // Arrange
        await store.initializeRemote();
        // Act
        receivedStream.add(
          chatQuerySnapshot({
            'offer-1': {'status': 'unknown', 'senderName': ' '},
          }),
        );
        // Assert
        final loaded = store.receivedOffers.single;
        expect(loaded.status, SkillRequestStatus.pending);
        expect(loaded.name, 'EduPro member');
        expect(loaded.initials, 'EM');
        expect(loaded.title, 'Skill tutor');
        expect(loaded.message, 'I would like to help.');
        expect(loaded.available, 'To be arranged');
        expect(loaded.scheduledDate, isNull);
        expect(loaded.meetingLink, isNull);
        expect(store.sessions, isEmpty);
      },
    );

    test(
      'SKILL029 publishes trimmed meeting links for accepted owned offers',
      () async {
        // Arrange
        await store.initializeRemote();
        receivedStream.add(chatQuerySnapshot({'offer-1': offerData()}));
        // Act
        await store.publishMeetingLink(
          sessionId: 'offer-1',
          platform: 'Teams',
          link: ' https://example.test/meeting ',
        );
        // Assert
        verify(
          () => offerRef.update({
            'meetingPlatform': 'Teams',
            'meetingLink': 'https://example.test/meeting',
            'linkPublishedAt': FieldValue.serverTimestamp(),
          }),
        ).called(1);
      },
    );

    test('SKILL030 prevents publishing links before acceptance', () async {
      // Arrange
      await store.initializeRemote();
      receivedStream.add(
        chatQuerySnapshot({'offer-1': offerData(status: 'pending')}),
      );
      // Act / Assert
      await expectLater(
        store.publishMeetingLink(
          sessionId: 'offer-1',
          platform: 'Teams',
          link: 'https://example.test',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('after acceptance'),
          ),
        ),
      );
      verifyNever(() => offerRef.update(any()));
    });

    test(
      'SKILL031 prevents publishing another owners or nonexistent meeting links',
      () async {
        // Arrange
        await store.initializeRemote();
        receivedStream.add(
          chatQuerySnapshot({'offer-1': offerData(recipient: 'other')}),
        );
        // Act / Assert
        await expectLater(
          store.publishMeetingLink(
            sessionId: 'offer-1',
            platform: 'Teams',
            link: 'https://example.test',
          ),
          throwsA(isA<StateError>()),
        );
        await expectLater(
          store.publishMeetingLink(
            sessionId: 'missing',
            platform: 'Teams',
            link: 'https://example.test',
          ),
          throwsA(isA<StateError>()),
        );
        verifyNever(() => offerRef.update(any()));
      },
    );
  });
}

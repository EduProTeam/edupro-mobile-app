// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/courses/models/course_draft.dart';
import 'package:edupro_mobile_app/features/courses/services/course_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _Reference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class _Snapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _Query extends Mock implements Query<Map<String, dynamic>> {}

class _QuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class _QueryDocument extends Mock
    implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class _Transaction extends Mock implements Transaction {}

Matcher _failure(String message) =>
    isA<CourseFailure>().having((error) => error.message, 'message', message);

const _media = CourseMedia(
  name: 'file.mp4',
  path: 'owner/file.mp4',
  url: 'https://example.invalid/file',
);

Map<String, dynamic> _validCourseData() => {
  'title': 'Flutter basics',
  'category': 'Development',
  'description': 'Learn Flutter',
  'language': 'English',
  'userId': 'student',
  'status': 'published',
  'type': 'paid',
  'price': 25,
  'thumbnail': _media.toMap(),
  'lessons': [
    CourseLesson(id: 'lesson', title: 'Introduction', video: _media).toMap(),
  ],
};

void main() {
  late _Auth auth;
  late _User user;
  late _Firestore firestore;
  late _Collection courses;
  late _Collection users;
  late _Collection enrollments;
  late _Reference courseRef;
  late _Reference userRef;
  late _Reference enrollmentRef;
  late _Snapshot courseSnapshot;
  late _Snapshot enrollmentSnapshot;
  late _Transaction transaction;
  late CourseService service;

  setUpAll(() {
    registerFallbackValue((Transaction transaction) async => null);
  });

  setUp(() {
    auth = _Auth();
    user = _User();
    firestore = _Firestore();
    courses = _Collection();
    users = _Collection();
    enrollments = _Collection();
    courseRef = _Reference();
    userRef = _Reference();
    enrollmentRef = _Reference();
    courseSnapshot = _Snapshot();
    enrollmentSnapshot = _Snapshot();
    transaction = _Transaction();
    service = CourseService(auth: auth, firestore: firestore);
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('student');
    when(() => firestore.collection('courses')).thenReturn(courses);
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => courses.doc('course')).thenReturn(courseRef);
    when(() => users.doc('student')).thenReturn(userRef);
    when(() => userRef.collection('courseEnrollments')).thenReturn(enrollments);
    when(() => enrollments.doc('course')).thenReturn(enrollmentRef);
    when(
      () => transaction.get(courseRef),
    ).thenAnswer((_) async => courseSnapshot);
    when(
      () => transaction.get(enrollmentRef),
    ).thenAnswer((_) async => enrollmentSnapshot);
    when(() => transaction.update(courseRef, any())).thenReturn(transaction);
    when(
      () => transaction.update(enrollmentRef, any()),
    ).thenReturn(transaction);
    when(
      () => transaction.set(courseRef, any<Map<String, dynamic>>()),
    ).thenReturn(transaction);
    when(
      () => transaction.set(enrollmentRef, any<Map<String, dynamic>>()),
    ).thenReturn(transaction);
    when(
      () => transaction.set<Map<String, Object?>>(enrollmentRef, any()),
    ).thenReturn(transaction);
    when(() => transaction.delete(courseRef)).thenReturn(transaction);
    when(() => courseRef.update(any())).thenAnswer((_) async {});
    when(() => firestore.runTransaction<Null>(any())).thenAnswer((
      invocation,
    ) async {
      final handler =
          invocation.positionalArguments.single as TransactionHandler<Null>;
      await handler(transaction);
    });
    when(() => courseSnapshot.exists).thenReturn(true);
    when(
      () => courseSnapshot.data(),
    ).thenReturn({'userId': 'student', 'status': 'published'});
    when(() => enrollmentSnapshot.exists).thenReturn(false);
  });

  group('Course publication and persistence', () {
    test('COURSE041 missing auth sessions expose an empty user ID', () {
      // Arrange
      when(() => auth.currentUser).thenReturn(null);

      // Act
      final id = service.userId;

      // Assert
      expect(id, isEmpty);
      verifyZeroInteractions(firestore);
    });

    test('COURSE042 new IDs come from the course collection', () {
      // Arrange
      when(() => courses.doc()).thenReturn(courseRef);
      when(() => courseRef.id).thenReturn('generated-course');

      // Act
      final id = service.newId();

      // Assert
      expect(id, 'generated-course');
      verify(() => courses.doc()).called(1);
      verifyNever(() => courseRef.update(any()));
    });

    test(
      'COURSE043 saving another owners course fails before database access',
      () async {
        // Arrange
        final course = CourseDraft.fromMap('course', {'userId': 'other-owner'});

        // Act
        final operation = service.save(course, isNew: false);

        // Assert
        await expectLater(
          operation,
          throwsA(_failure('Sign in with the course owner account to save.')),
        );
        verifyZeroInteractions(firestore);
      },
    );

    final invalidPublicationCases = [
      (id: 'COURSE044', name: 'blank title', key: 'title', value: '   '),
      (
        id: 'COURSE045',
        name: 'blank description',
        key: 'description',
        value: '\n',
      ),
      (id: 'COURSE046', name: 'missing category', key: 'category', value: ''),
      (id: 'COURSE047', name: 'missing language', key: 'language', value: ''),
      (
        id: 'COURSE048',
        name: 'missing thumbnail',
        key: 'thumbnail',
        value: null,
      ),
      (
        id: 'COURSE049',
        name: 'no lessons',
        key: 'lessons',
        value: <Map<String, dynamic>>[],
      ),
      (
        id: 'COURSE050',
        name: 'blank lesson title',
        key: 'lessons',
        value: [
          {'id': 'lesson', 'title': ' ', 'video': _media.toMap()},
        ],
      ),
      (
        id: 'COURSE051',
        name: 'missing lesson video',
        key: 'lessons',
        value: [
          {'id': 'lesson', 'title': 'Intro'},
        ],
      ),
      (id: 'COURSE052', name: 'zero paid price', key: 'price', value: 0),
    ];
    for (final scenario in invalidPublicationCases) {
      test('${scenario.id} publication rejects ${scenario.name}', () async {
        // Arrange
        final data = _validCourseData()..[scenario.key] = scenario.value;
        final course = CourseDraft.fromMap('course', data);

        // Act
        final operation = service.save(course, isNew: false);

        // Assert
        await expectLater(
          operation,
          throwsA(
            _failure(
              'Complete all required course and lesson fields before publishing.',
            ),
          ),
        );
        verifyZeroInteractions(firestore);
      });
    }

    test(
      'COURSE053 incomplete drafts save without writing enrollment or creation fields',
      () async {
        // Arrange
        final course = CourseDraft.fromMap('course', {
          'userId': 'student',
          'enrollmentCount': 99,
        });

        // Act
        await service.save(course, isNew: false);

        // Assert
        final data =
            verify(() => courseRef.update(captureAny())).captured.single as Map;
        expect(data['status'], 'draft');
        expect(data['title'], isEmpty);
        expect(data['updatedAt'], isA<FieldValue>());
        expect(data.containsKey('createdAt'), isFalse);
        expect(data.containsKey('enrollmentCount'), isFalse);
        verifyNever(() => firestore.runTransaction<Null>(any()));
      },
    );

    test(
      'COURSE054 a complete paid course publishes its price and lessons',
      () async {
        // Arrange
        final course = CourseDraft.fromMap('course', _validCourseData());

        // Act
        await service.save(course, isNew: false);

        // Assert
        final data =
            verify(() => courseRef.update(captureAny())).captured.single as Map;
        expect(data['status'], 'published');
        expect(data['price'], 25);
        expect((data['lessons'] as List).single['title'], 'Introduction');
      },
    );

    test(
      'COURSE055 a new course transaction initializes creation date and enrollment count',
      () async {
        // Arrange
        when(() => courseSnapshot.exists).thenReturn(false);
        final course = CourseDraft.fromMap('course', _validCourseData());

        // Act
        await service.save(course, isNew: true);

        // Assert
        final data =
            verify(
                  () => transaction.set(
                    courseRef,
                    captureAny<Map<String, dynamic>>(),
                  ),
                ).captured.single
                as Map;
        expect(data['enrollmentCount'], 0);
        expect(data['createdAt'], isA<FieldValue>());
        expect(data['updatedAt'], isA<FieldValue>());
        verifyNever(() => transaction.update(courseRef, any()));
      },
    );

    test(
      'COURSE056 retrying new-course save updates an existing owner document',
      () async {
        // Arrange
        when(
          () => courseSnapshot.data(),
        ).thenReturn({'userId': 'student', 'enrollmentCount': 12});
        final course = CourseDraft.fromMap('course', _validCourseData());

        // Act
        await service.save(course, isNew: true);

        // Assert
        final data =
            verify(
                  () => transaction.update(courseRef, captureAny()),
                ).captured.single
                as Map;
        expect(data['title'], 'Flutter basics');
        expect(data.containsKey('createdAt'), isFalse);
        expect(data.containsKey('enrollmentCount'), isFalse);
        verifyNever(
          () => transaction.set(courseRef, any<Map<String, dynamic>>()),
        );
      },
    );

    test(
      'COURSE057 Firestore save errors retain the backend error code',
      () async {
        // Arrange
        when(() => courseRef.update(any())).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
        final course = CourseDraft.fromMap('course', {'userId': 'student'});

        // Act
        final operation = service.save(course, isNew: false);

        // Assert
        await expectLater(
          operation,
          throwsA(
            _failure(
              'Could not save the course to Firestore (permission-denied). Check your Firestore rules and try again.',
            ),
          ),
        );
      },
    );

    test(
      'COURSE058 unexpected save failures return the retained-entries retry message',
      () async {
        // Arrange
        when(() => courseRef.update(any())).thenThrow(StateError('offline'));
        final course = CourseDraft.fromMap('course', {'userId': 'student'});

        // Act
        final operation = service.save(course, isNew: false);

        // Assert
        await expectLater(
          operation,
          throwsA(
            _failure(
              'Could not save the course to Firestore. Your entries are retained; please retry.',
            ),
          ),
        );
      },
    );

    test(
      'COURSE077 new-course retries never overwrite another owners existing document',
      () async {
        // Arrange
        when(
          () => courseSnapshot.data(),
        ).thenReturn({'userId': 'different-owner'});
        final course = CourseDraft.fromMap('course', _validCourseData());

        // Act
        final operation = service.save(course, isNew: true);

        // Assert
        await expectLater(
          operation,
          throwsA(
            _failure(
              'Could not save the course to Firestore. Your entries are retained; please retry.',
            ),
          ),
        );
        verifyNever(
          () => transaction.set(courseRef, any<Map<String, dynamic>>()),
        );
        verifyNever(() => transaction.update(courseRef, any()));
      },
    );
  });

  group('Enrollment and completion', () {
    test(
      'COURSE059 a missing enrollment count starts at one with no completed lessons',
      () async {
        // Arrange
        when(() => courseSnapshot.data()).thenReturn({'status': 'published'});

        // Act
        await service.enroll('course');

        // Assert
        final data =
            verify(
                  () => transaction.set(
                    enrollmentRef,
                    captureAny<Map<String, dynamic>>(),
                  ),
                ).captured.single
                as Map;
        expect(data['courseId'], 'course');
        expect(data['userId'], 'student');
        expect(data['enrolledAt'], isA<FieldValue>());
        expect(data['completedLessonIds'], isEmpty);
        verify(
          () => transaction.update(courseRef, {'enrollmentCount': 1}),
        ).called(1);
      },
    );

    test(
      'COURSE060 enrollment backend failures return a connection retry error',
      () async {
        // Arrange
        when(
          () => firestore.runTransaction<Null>(any()),
        ).thenThrow(StateError('offline'));

        // Act
        final operation = service.enroll('course');

        // Assert
        await expectLater(
          operation,
          throwsA(
            _failure('Could not enroll. Check your connection and try again.'),
          ),
        );
        verifyZeroInteractions(transaction);
      },
    );

    test(
      'COURSE061 blank lesson IDs are rejected before database access',
      () async {
        // Arrange
        const lessonId = ' \n ';

        // Act
        final operation = service.completeLesson('course', lessonId);

        // Assert
        await expectLater(
          operation,
          throwsA(_failure('This lesson cannot be marked as complete.')),
        );
        verifyZeroInteractions(firestore);
      },
    );

    test(
      'COURSE062 signed-out students cannot mark lessons complete',
      () async {
        // Arrange
        when(() => auth.currentUser).thenReturn(null);

        // Act
        final operation = service.completeLesson('course', 'lesson');

        // Assert
        await expectLater(
          operation,
          throwsA(_failure('Sign in to track lesson progress.')),
        );
        verifyZeroInteractions(firestore);
      },
    );

    test(
      'COURSE063 completion requires an existing enrollment with its specific error',
      () async {
        // Arrange
        when(() => enrollmentSnapshot.exists).thenReturn(false);

        // Act
        final operation = service.completeLesson('course', 'lesson');

        // Assert
        await expectLater(
          operation,
          throwsA(_failure('Enroll in this course to track progress.')),
        );
        verifyNever(() => transaction.update(enrollmentRef, any()));
      },
    );

    test(
      'COURSE064 completion filters malformed IDs and stores sorted unique IDs',
      () async {
        // Arrange
        when(() => enrollmentSnapshot.exists).thenReturn(true);
        when(() => enrollmentSnapshot.data()).thenReturn({
          'completedLessonIds': ['z', null, 4, 'z', 'a'],
        });

        // Act
        await service.completeLesson('course', 'm');

        // Assert
        final data =
            verify(
                  () => transaction.update(enrollmentRef, captureAny()),
                ).captured.single
                as Map;
        expect(data['completedLessonIds'], ['a', 'm', 'z']);
        expect(data['lastProgressAt'], isA<FieldValue>());
        verifyNever(() => transaction.update(courseRef, any()));
      },
    );

    test(
      'COURSE065 completion backend failures return the progress retry message',
      () async {
        // Arrange
        when(
          () => firestore.runTransaction<Null>(any()),
        ).thenThrow(StateError('offline'));

        // Act
        final operation = service.completeLesson('course', 'lesson');

        // Assert
        await expectLater(
          operation,
          throwsA(
            _failure(
              'Could not save lesson progress. Check your connection and try again.',
            ),
          ),
        );
      },
    );
  });

  group('Course deletion', () {
    test(
      'COURSE078 deleting another owners course fails before database access',
      () async {
        // Arrange
        final course = CourseDraft.fromMap('course', {'userId': 'other-owner'});

        // Act
        final operation = service.delete(course);

        // Assert
        await expectLater(
          operation,
          throwsA(_failure('Sign in with the course owner account to delete.')),
        );
        verifyZeroInteractions(firestore);
      },
    );

    test(
      'COURSE066 deleting a missing owner course performs no write',
      () async {
        // Arrange
        when(() => courseSnapshot.exists).thenReturn(false);
        final course = CourseDraft.fromMap('course', {'userId': 'student'});

        // Act
        await service.delete(course);

        // Assert
        verifyNever(() => transaction.delete(courseRef));
      },
    );

    test(
      'COURSE067 changed ownership in Firestore prevents deletion',
      () async {
        // Arrange
        when(
          () => courseSnapshot.data(),
        ).thenReturn({'userId': 'different-owner'});
        final course = CourseDraft.fromMap('course', {'userId': 'student'});

        // Act
        final operation = service.delete(course);

        // Assert
        await expectLater(
          operation,
          throwsA(_failure('Only the course owner can delete this course.')),
        );
        verifyNever(() => transaction.delete(courseRef));
      },
    );

    test(
      'COURSE068 the owner deletes the course reference in a transaction',
      () async {
        // Arrange
        final course = CourseDraft.fromMap('course', {'userId': 'student'});

        // Act
        await service.delete(course);

        // Assert
        verify(() => transaction.get(courseRef)).called(1);
        verify(() => transaction.delete(courseRef)).called(1);
        verifyNever(() => transaction.update(courseRef, any()));
      },
    );

    test('COURSE069 delete failures return a connection retry error', () async {
      // Arrange
      when(
        () => firestore.runTransaction<Null>(any()),
      ).thenThrow(StateError('offline'));
      final course = CourseDraft.fromMap('course', {'userId': 'student'});

      // Act
      final operation = service.delete(course);

      // Assert
      await expectLater(
        operation,
        throwsA(
          _failure(
            'Could not delete the course. Check your connection and try again.',
          ),
        ),
      );
    });
  });

  group('Course streams and media guards', () {
    test(
      'COURSE070 signed-out owned and enrollment streams emit empty data without Firestore',
      () async {
        // Arrange
        when(() => auth.currentUser).thenReturn(null);

        // Act
        final owned = await service.watchCourses(owned: true).single;
        final records = await service.watchEnrollments().single;
        final ids = await service.watchEnrolledCourseIds().single;

        // Assert
        expect(owned, isEmpty);
        expect(records, isEmpty);
        expect(ids, isEmpty);
        verifyZeroInteractions(firestore);
      },
    );

    test(
      'COURSE071 owned course streams sort newest first and decode Firestore dates',
      () async {
        // Arrange
        final query = _Query();
        final snapshot = _QuerySnapshot();
        final older = _QueryDocument();
        final newer = _QueryDocument();
        when(
          () => courses.where('userId', isEqualTo: 'student'),
        ).thenReturn(query);
        when(() => query.snapshots()).thenAnswer((_) => Stream.value(snapshot));
        when(() => snapshot.docs).thenReturn([older, newer]);
        when(() => older.id).thenReturn('older');
        when(() => older.data()).thenReturn({
          'updatedAt': Timestamp.fromMillisecondsSinceEpoch(100),
          'createdAt': 'legacy',
        });
        when(() => newer.id).thenReturn('newer');
        when(() => newer.data()).thenReturn({
          'updatedAt': Timestamp.fromMillisecondsSinceEpoch(200),
          'createdAt': Timestamp.fromMillisecondsSinceEpoch(50),
        });

        // Act
        final result = await service.watchCourses(owned: true).single;

        // Assert
        expect(result.map((course) => course.id), ['newer', 'older']);
        expect(result.first.updatedAt, 200);
        expect(result.first.createdAt, 50);
        expect(result.last.createdAt, 0);
      },
    );

    test(
      'COURSE072 public course streams select published documents while signed out',
      () async {
        // Arrange
        final query = _Query();
        final snapshot = _QuerySnapshot();
        when(() => auth.currentUser).thenReturn(null);
        when(
          () => courses.where('status', isEqualTo: 'published'),
        ).thenReturn(query);
        when(() => query.snapshots()).thenAnswer((_) => Stream.value(snapshot));
        when(() => snapshot.docs).thenReturn([]);

        // Act
        final result = await service.watchCourses(owned: false).single;

        // Assert
        expect(result, isEmpty);
        verify(() => courses.where('status', isEqualTo: 'published')).called(1);
      },
    );

    test(
      'COURSE073 enrollment streams restore document IDs and completion records',
      () async {
        // Arrange
        final snapshot = _QuerySnapshot();
        final document = _QueryDocument();
        when(
          () => enrollments.snapshots(),
        ).thenAnswer((_) => Stream.value(snapshot));
        when(() => snapshot.docs).thenReturn([document]);
        when(() => document.id).thenReturn('course');
        when(() => document.data()).thenReturn({
          'completedLessonIds': ['lesson', 'lesson'],
        });

        // Act
        final result = await service.watchEnrollments().single;
        final ids = await service.watchEnrolledCourseIds().single;

        // Assert
        expect(result.keys, ['course']);
        expect(result['course']!.courseId, 'course');
        expect(result['course']!.completedLessonIds, {'lesson'});
        expect(ids, {'course'});
      },
    );

    test(
      'COURSE074 Firestore stream errors are preserved for stream consumers',
      () async {
        // Arrange
        final query = _Query();
        final error = StateError('offline');
        when(
          () => courses.where('userId', isEqualTo: 'student'),
        ).thenReturn(query);
        when(() => query.snapshots()).thenAnswer((_) => Stream.error(error));

        // Act
        final stream = service.watchCourses(owned: true);

        // Assert
        await expectLater(stream, emitsError(same(error)));
      },
    );

    test(
      'COURSE075 signed-out uploads fail before storage or filesystem access',
      () async {
        // Arrange
        when(() => auth.currentUser).thenReturn(null);

        // Act
        final operation = service.upload('course', 'nonexistent.mp4');

        // Assert
        await expectLater(
          operation,
          throwsA(_failure('Sign in to save a course.')),
        );
        verifyZeroInteractions(firestore);
      },
    );

    test(
      'COURSE076 blank media paths fail before storage is initialized',
      () async {
        // Arrange
        const path = ' \n ';

        // Act
        final operation = service.refreshMediaUrl(path);

        // Assert
        await expectLater(
          operation,
          throwsA(_failure('The stored video path is empty.')),
        );
        verifyZeroInteractions(firestore);
      },
    );
  });
}

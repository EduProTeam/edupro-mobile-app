// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edupro_mobile_app/features/courses/services/course_service.dart';
import 'package:edupro_mobile_app/features/courses/presentation/screens/view_course_screen.dart';
import 'package:edupro_mobile_app/features/courses/models/course_draft.dart';

// A transactional test double exercises the actual service write logic without
// Firebase credentials. Production rule enforcement still requires emulator QA.
class MemoryDb implements FirebaseFirestore {
  Map<String, Map<String, dynamic>> docs = {};
  bool failCommit = false;
  Future<void> _queue = Future.value();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      MemoryCollection(this, path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    final result = _queue.then((_) async {
      final transaction = MemoryTransaction(this);
      final value = await handler(transaction);
      if (failCommit) throw StateError('Offline');
      docs = transaction.pending;
      return value;
    });
    _queue = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryCollection implements CollectionReference<Map<String, dynamic>> {
  MemoryCollection(this.db, this.path);
  final MemoryDb db;
  @override
  final String path;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      MemoryReference(db, '${this.path}/$path');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryReference implements DocumentReference<Map<String, dynamic>> {
  MemoryReference(this.db, this.path);
  final MemoryDb db;
  @override
  final String path;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      MemoryCollection(db, '${this.path}/$path');
  @override
  Future<void> update(Map<Object, Object?> data) async {
    if (!db.docs.containsKey(path)) throw StateError('Document was deleted');
    db.docs[path]!.addAll(Map<String, dynamic>.from(data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemorySnapshot<T> implements DocumentSnapshot<T> {
  MemorySnapshot(this.value);
  final T? value;
  @override
  bool get exists => value != null;
  @override
  T? data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryTransaction implements Transaction {
  MemoryTransaction(MemoryDb db)
    : pending = {
        for (final entry in db.docs.entries) entry.key: Map.of(entry.value),
      };
  final Map<String, Map<String, dynamic>> pending;
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> reference,
  ) async => MemorySnapshot<T>(pending[reference.path] as T?);
  @override
  Transaction set<T>(
    DocumentReference<T> reference,
    T data, [
    SetOptions? options,
  ]) {
    pending[reference.path] = Map<String, dynamic>.from(data as Map);
    return this;
  }

  @override
  Transaction update(DocumentReference reference, Map<Object, Object?> data) {
    pending[reference.path]!.addAll(Map<String, dynamic>.from(data));
    return this;
  }

  @override
  Transaction delete(DocumentReference reference) {
    pending.remove(reference.path);
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StudentService extends CourseService {
  StudentService(MemoryDb db, this.userId) : super(firestore: db);
  @override
  final String userId;
}

class EnrollmentUiService extends CourseService {
  bool enrolled = false;
  int attempts = 0;
  Completer<void>? pending;
  @override
  Stream<Set<String>> watchEnrolledCourseIds() =>
      Stream.value(enrolled ? {'course'} : <String>{});
  @override
  Future<void> enroll(String courseId) async {
    attempts++;
    await pending?.future;
    enrolled = true;
  }
}

void main() {
  test(
    'enrollment initializes legacy count and counts each student once',
    () async {
      final db = MemoryDb()
        ..docs['courses/course'] = {'status': 'published', 'userId': 'owner'};
      final student = StudentService(db, 'student');
      await Future.wait([student.enroll('course'), student.enroll('course')]);
      await StudentService(db, 'student').enroll('course');
      expect(db.docs['courses/course']!['enrollmentCount'], 1);
      expect(
        db.docs['users/student/courseEnrollments/course']!['courseId'],
        'course',
      );
      await StudentService(db, 'another').enroll('course');
      expect(db.docs['courses/course']!['enrollmentCount'], 2);
    },
  );

  test(
    'failed commits, drafts, deleted courses and signed-out users never increment',
    () async {
      final db = MemoryDb()
        ..docs['courses/course'] = {
          'status': 'published',
          'enrollmentCount': 3,
        };
      final student = StudentService(db, 'student');
      db.failCommit = true;
      await expectLater(
        student.enroll('course'),
        throwsA(isA<CourseFailure>()),
      );
      expect(db.docs['courses/course']!['enrollmentCount'], 3);
      expect(
        db.docs.containsKey('users/student/courseEnrollments/course'),
        isFalse,
      );
      db.failCommit = false;
      db.docs['courses/course']!['status'] = 'draft';
      await expectLater(
        student.enroll('course'),
        throwsA(isA<CourseFailure>()),
      );
      await expectLater(
        student.enroll('missing'),
        throwsA(isA<CourseFailure>()),
      );
      await expectLater(
        StudentService(db, '').enroll('course'),
        throwsA(isA<CourseFailure>()),
      );
      expect(db.docs['courses/course']!['enrollmentCount'], 3);
    },
  );

  test(
    'saving existing courses preserves enrollment count and cannot recreate deleted course',
    () async {
      final db = MemoryDb()
        ..docs['courses/course'] = {'userId': 'owner', 'enrollmentCount': 12};
      final draft = CourseDraft.fromMap('course', {
        'title': 'Updated',
        'userId': 'owner',
      });
      final service = StudentService(db, 'owner');
      await service.save(draft, isNew: false);
      expect(db.docs['courses/course']!['enrollmentCount'], 12);
      expect(db.docs.length, 1);
      db.docs.clear();
      await expectLater(
        service.save(draft, isNew: false),
        throwsA(isA<CourseFailure>()),
      );
      expect(db.docs, isEmpty);
    },
  );

  testWidgets(
    'overview enrolls once, prevents repeat taps and restores Continue Learning',
    (tester) async {
      final service = EnrollmentUiService()..pending = Completer<void>();
      final course = CourseDraft.fromMap('course', {
        'title': 'Course',
        'status': 'published',
      });
      Widget screen() => MaterialApp(
        home: ViewCourseScreen(course: course, service: service),
      );
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('Edit Course'), findsNothing);
      await tester.tap(find.text('Enroll for Free'));
      await tester.pump();
      expect(find.text('Enrolling...'), findsOneWidget);
      await tester.tap(find.text('Enrolling...'));
      expect(service.attempts, 1);
      service.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Continue Learning'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('Enroll for Free'), findsNothing);
    },
  );
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../supabase_options.dart';
import '../models/course_draft.dart';

class CourseService {
  CourseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _providedAuth = auth,
      _providedDb = firestore;
  final FirebaseAuth? _providedAuth;
  final FirebaseFirestore? _providedDb;
  late final FirebaseAuth _auth = _providedAuth ?? FirebaseAuth.instance;
  late final FirebaseFirestore _db = _providedDb ?? FirebaseFirestore.instance;
  late final SupabaseClient _storage = SupabaseClient(
    SupabaseOptions.url,
    SupabaseOptions.publishableKey,
    accessToken: () async => _auth.currentUser?.getIdToken(),
  );
  String get userId => _auth.currentUser?.uid ?? '';
  String newId() => _db.collection('courses').doc().id;

  Stream<List<CourseDraft>> watchCourses({required bool owned}) {
    if (owned && userId.isEmpty) return Stream.value([]);
    final query = owned
        ? _db.collection('courses').where('userId', isEqualTo: userId)
        : _db.collection('courses').where('status', isEqualTo: 'published');
    return query.snapshots().map((snapshot) {
      final courses = snapshot.docs.map((doc) {
        final data = doc.data();
        final time = data['updatedAt'];
        return CourseDraft.fromMap(
          doc.id,
          data,
          updatedAt: time is Timestamp ? time.millisecondsSinceEpoch : 0,
          createdAt: data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch
              : 0,
        );
      }).toList();
      courses.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return courses;
    });
  }

  Future<CourseMedia> upload(String courseId, String localPath) async {
    if (userId.isEmpty) throw const CourseFailure('Sign in to save a course.');
    final name = localPath.replaceAll('\\', '/').split('/').last;
    final safeName = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path =
        '$userId/course_${courseId}_${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final bucket = _storage.storage.from(SupabaseOptions.mediaBucket);
    try {
      await bucket.upload(
        path,
        File(localPath),
        fileOptions: FileOptions(contentType: _mime(name)),
      );
    } on StorageException catch (error) {
      debugPrint(
        'Course media upload error: ${error.statusCode} ${error.message}',
      );
      throw const CourseFailure(
        'Upload failed. Check your connection and retry.',
      );
    } catch (error) {
      debugPrint('Course media upload error: $error');
      throw const CourseFailure(
        'Upload failed. Check your connection and retry.',
      );
    }
    try {
      final url = await bucket.createSignedUrl(path, 60 * 60 * 24 * 365);
      return CourseMedia(name: name, path: path, url: url);
    } on StorageException catch (error) {
      debugPrint(
        'Course signed URL error: ${error.statusCode} ${error.message}',
      );
      try {
        await bucket.remove([path]);
      } catch (_) {
        // Preserve the original failure.
      }
      throw const CourseFailure('Could not finish the upload. Please retry.');
    } catch (error) {
      debugPrint('Course signed URL error: $error');
      try {
        await bucket.remove([path]);
      } catch (_) {
        /* Preserve the original failure. */
      }
      throw const CourseFailure('Could not finish the upload. Please retry.');
    }
  }

  Future<String> refreshMediaUrl(String path) async {
    if (path.trim().isEmpty) {
      throw const CourseFailure('The stored video path is empty.');
    }
    try {
      return await _storage.storage
          .from(SupabaseOptions.mediaBucket)
          .createSignedUrl(path, 60 * 60 * 24 * 365);
    } on StorageException catch (error) {
      debugPrint(
        'Course media URL refresh error: ${error.statusCode} ${error.message}',
      );
      throw const CourseFailure('The video URL could not be refreshed.');
    }
  }

  Future<void> save(CourseDraft course, {required bool isNew}) async {
    if (userId.isEmpty || course.userId != userId) {
      throw const CourseFailure(
        'Sign in with the course owner account to save.',
      );
    }
    if (course.status == CourseStatus.published &&
        (course.title.trim().isEmpty ||
            course.description.trim().isEmpty ||
            course.category.isEmpty ||
            course.language.isEmpty ||
            course.thumbnail == null ||
            course.lessons.isEmpty ||
            course.lessons.any(
              (l) => l.title.trim().isEmpty || l.video == null,
            ) ||
            (course.type == CourseType.paid &&
                validateCoursePrice('${course.price}') != null))) {
      throw const CourseFailure(
        'Complete all required course and lesson fields before publishing.',
      );
    }
    try {
      final reference = _db.collection('courses').doc(course.id);
      final data = {
        ...course.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (isNew) {
        // Retries keep the same ID and must not reset the count or creation date.
        await _db.runTransaction((transaction) async {
          final existing = await transaction.get(reference);
          if (existing.exists) {
            if (existing.data()?['userId'] != userId) {
              throw const CourseFailure(
                'Only the course owner can edit this course.',
              );
            }
            transaction.update(reference, data);
          } else {
            transaction.set(reference, {
              ...data,
              'createdAt': FieldValue.serverTimestamp(),
              'enrollmentCount': 0,
            });
          }
        });
      } else {
        // update cannot recreate a course deleted while the editor was open.
        // Enrollment counts are intentionally excluded from form writes.
        await reference.update(data);
      }
    } on FirebaseException catch (error) {
      debugPrint('Course Firestore save error: ${error.code} ${error.message}');
      throw CourseFailure(
        'Could not save the course to Firestore (${error.code}). Check your Firestore rules and try again.',
      );
    } catch (error) {
      debugPrint('Course Firestore save error: $error');
      throw const CourseFailure(
        'Could not save the course to Firestore. Your entries are retained; please retry.',
      );
    }
  }

  Stream<Map<String, CourseEnrollment>> watchEnrollments() {
    if (userId.isEmpty) return Stream.value(<String, CourseEnrollment>{});
    return _db
        .collection('users')
        .doc(userId)
        .collection('courseEnrollments')
        .snapshots()
        .map(
          (snapshot) => {
            for (final document in snapshot.docs)
              document.id: CourseEnrollment.fromMap(
                document.id,
                document.data(),
              ),
          },
        );
  }

  Stream<Set<String>> watchEnrolledCourseIds() =>
      watchEnrollments().map((enrollments) => enrollments.keys.toSet());

  Future<void> enroll(String courseId) async {
    final studentId = userId;
    if (studentId.isEmpty) {
      throw const CourseFailure('Sign in to enroll in a course.');
    }
    final courseRef = _db.collection('courses').doc(courseId);
    final enrollmentRef = _db
        .collection('users')
        .doc(studentId)
        .collection('courseEnrollments')
        .doc(courseId);
    try {
      await _db.runTransaction((transaction) async {
        final course = await transaction.get(courseRef);
        final enrollment = await transaction.get(enrollmentRef);
        if (!course.exists || course.data()?['status'] != 'published') {
          throw const CourseFailure(
            'This course is not available for enrollment.',
          );
        }
        if (enrollment.exists) return;
        final count = (course.data()?['enrollmentCount'] as num?)?.toInt() ?? 0;
        transaction.set(enrollmentRef, {
          'courseId': courseId,
          'userId': studentId,
          'enrolledAt': FieldValue.serverTimestamp(),
          'completedLessonIds': <String>[],
        });
        transaction.update(courseRef, {'enrollmentCount': count + 1});
      });
    } on CourseFailure {
      rethrow;
    } catch (error) {
      debugPrint('Course enrollment error: $error');
      throw const CourseFailure(
        'Could not enroll. Check your connection and try again.',
      );
    }
  }

  Future<void> completeLesson(String courseId, String lessonId) async {
    final studentId = userId;
    if (studentId.isEmpty) {
      throw const CourseFailure('Sign in to track lesson progress.');
    }
    if (lessonId.trim().isEmpty) {
      throw const CourseFailure('This lesson cannot be marked as complete.');
    }
    final enrollmentRef = _db
        .collection('users')
        .doc(studentId)
        .collection('courseEnrollments')
        .doc(courseId);
    try {
      await _db.runTransaction((transaction) async {
        final enrollment = await transaction.get(enrollmentRef);
        if (!enrollment.exists) {
          throw const CourseFailure('Enroll in this course to track progress.');
        }
        final existing =
            (enrollment.data()?['completedLessonIds'] as List? ?? [])
                .whereType<String>()
                .toSet();
        if (!existing.add(lessonId)) return;
        transaction.update(enrollmentRef, {
          'completedLessonIds': existing.toList()..sort(),
          'lastProgressAt': FieldValue.serverTimestamp(),
        });
      });
    } on CourseFailure {
      rethrow;
    } catch (error) {
      debugPrint('Course lesson progress error: $error');
      throw const CourseFailure(
        'Could not save lesson progress. Check your connection and try again.',
      );
    }
  }

  Future<void> delete(CourseDraft course) async {
    final ownerId = userId;
    if (ownerId.isEmpty || course.userId != ownerId) {
      throw const CourseFailure(
        'Sign in with the course owner account to delete.',
      );
    }
    try {
      final reference = _db.collection('courses').doc(course.id);
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        if (!snapshot.exists) return;
        if (snapshot.data()?['userId'] != ownerId) {
          throw const CourseFailure(
            'Only the course owner can delete this course.',
          );
        }
        transaction.delete(reference);
      });
    } on CourseFailure {
      rethrow;
    } catch (error) {
      debugPrint('Course delete error: $error');
      throw const CourseFailure(
        'Could not delete the course. Check your connection and try again.',
      );
    }
  }

  String? _mime(String name) => switch (name.split('.').last.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'mp4' => 'video/mp4',
    'mov' => 'video/quicktime',
    'pdf' => 'application/pdf',
    'docx' =>
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'pptx' =>
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    _ => null,
  };
}

class CourseFailure implements Exception {
  const CourseFailure(this.message);
  final String message;
}

class CourseEnrollment {
  const CourseEnrollment({
    required this.courseId,
    required this.completedLessonIds,
  });

  final String courseId;
  final Set<String> completedLessonIds;

  factory CourseEnrollment.fromMap(String courseId, Map<String, dynamic> data) {
    return CourseEnrollment(
      courseId: courseId,
      completedLessonIds: Set.unmodifiable(
        (data['completedLessonIds'] as List? ?? []).whereType<String>(),
      ),
    );
  }
}

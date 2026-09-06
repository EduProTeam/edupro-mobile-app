import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    } catch (_) {
      throw const CourseFailure(
        'Upload failed. Check your connection and retry.',
      );
    }
    try {
      final url = await bucket.createSignedUrl(path, 60 * 60 * 24 * 365);
      return CourseMedia(name: name, path: path, url: url);
    } catch (_) {
      try {
        await bucket.remove([path]);
      } catch (_) {
        /* Preserve the original failure. */
      }
      throw const CourseFailure('Could not finish the upload. Please retry.');
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
      await _db.collection('courses').doc(course.id).set({
        ...course.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (isNew) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      throw const CourseFailure(
        'Could not save the course to Firestore. Your entries are retained; please retry.',
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

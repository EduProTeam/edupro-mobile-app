import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase_options.dart';

class ProfilePhotoService {
  ProfilePhotoService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  SupabaseClient get _supabase => SupabaseClient(
    SupabaseOptions.url,
    SupabaseOptions.publishableKey,
    accessToken: () async {
      final user = _firebaseAuth.currentUser;
      return await user?.getIdToken();
    },
  );

  Future<String> uploadProfilePhoto(File image) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ProfilePhotoFailure('No signed-in user is available.');
    }

    final extension = image.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
    final objectPath =
        '${user.uid}/profile_${DateTime.now().millisecondsSinceEpoch}.$extension';

    try {
      final document = await _firestore.collection('users').doc(user.uid).get();
      await _deleteOwnedPhoto(document.data()?['profileImageUrl'], user.uid);
      await _supabase.storage
          .from(SupabaseOptions.mediaBucket)
          .upload(
            objectPath,
            image,
            fileOptions: FileOptions(contentType: contentType),
          );
      final url = await _supabase.storage
          .from(SupabaseOptions.mediaBucket)
          .createSignedUrl(objectPath, 60 * 60 * 24 * 365);
      await _firestore.collection('users').doc(user.uid).set({
        'profileImageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.updatePhotoURL(url);
      return url;
    } on FirebaseException catch (error) {
      debugPrint('Profile photo upload Firestore error: ${error.code}');
      throw const ProfilePhotoFailure(
        'Unable to save the profile photo. Please try again.',
      );
    } catch (_) {
      throw const ProfilePhotoFailure(
        'Unable to upload profile photo. Please try again.',
      );
    }
  }

  Future<void> removeProfilePhoto(String? existingUrl) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ProfilePhotoFailure('No signed-in user is available.');
    }

    try {
      if (existingUrl != null && existingUrl.isNotEmpty) {
        await _deleteOwnedPhoto(existingUrl, user.uid);
      }
      await _firestore.collection('users').doc(user.uid).set({
        'profileImageUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.updatePhotoURL(null);
    } on FirebaseException catch (error) {
      debugPrint('Profile photo removal Firestore error: ${error.code}');
      throw const ProfilePhotoFailure(
        'Unable to remove profile photo. Please try again.',
      );
    } catch (_) {
      throw const ProfilePhotoFailure(
        'Unable to remove profile photo. Please try again.',
      );
    }
  }

  Future<void> _deleteOwnedPhoto(dynamic url, String uid) async {
    if (url is! String || url.isEmpty) {
      return;
    }

    final objectPath = _objectPathFromSignedUrl(url);
    if (objectPath == null || !objectPath.startsWith('$uid/')) {
      return;
    }

    try {
      await _supabase.storage.from(SupabaseOptions.mediaBucket).remove([
        objectPath,
      ]);
    } catch (_) {
      // A stale previous object must not stop a new profile photo upload.
    }
  }

  String? _objectPathFromSignedUrl(String url) {
    final path = Uri.tryParse(url)?.path;
    const marker = '/object/sign/${SupabaseOptions.mediaBucket}/';
    if (path == null || !path.contains(marker)) {
      return null;
    }
    return Uri.decodeFull(path.substring(path.indexOf(marker) + marker.length));
  }
}

class ProfilePhotoFailure implements Exception {
  const ProfilePhotoFailure(this.message);

  final String message;
}

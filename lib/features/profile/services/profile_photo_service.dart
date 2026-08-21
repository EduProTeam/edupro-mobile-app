import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePhotoService {
  ProfilePhotoService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<String> uploadProfilePhoto(File image) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const ProfilePhotoFailure('No signed-in user is available.');
    }

    final extension = image.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    final reference = _storage.ref(
      'profile_images/${user.uid}/profile.$extension',
    );

    try {
      await reference.putFile(image);
      final url = await reference.getDownloadURL();
      await _firestore.collection('users').doc(user.uid).set({
        'profileImageUrl': url,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.updatePhotoURL(url);
      return url;
    } on FirebaseException {
      throw const ProfilePhotoFailure(
        'Unable to upload profile photo. Please try again.',
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
        final ownPhotoPath = 'profile_images/${user.uid}/';
        final encodedOwnPhotoPath = 'profile_images%2F${user.uid}%2F';
        if (existingUrl.contains(ownPhotoPath) ||
            existingUrl.contains(encodedOwnPhotoPath)) {
          final reference = _storage.refFromURL(existingUrl);
          await reference.delete();
        }
      }
      await _firestore.collection('users').doc(user.uid).set({
        'profileImageUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await user.updatePhotoURL(null);
    } on FirebaseException {
      throw const ProfilePhotoFailure(
        'Unable to remove profile photo. Please try again.',
      );
    } catch (_) {
      throw const ProfilePhotoFailure(
        'Unable to remove profile photo. Please try again.',
      );
    }
  }
}

class ProfilePhotoFailure implements Exception {
  const ProfilePhotoFailure(this.message);

  final String message;
}

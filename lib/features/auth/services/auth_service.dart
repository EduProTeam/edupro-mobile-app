import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Login auth error: code=${error.code}, message=${error.message}',
      );
      throw AuthFailure(_mapSignInError(error.code));
    } catch (_) {
      throw const AuthFailure(
        'Something went wrong while signing you in. Please try again.',
      );
    }
  }

  Future<void> registerWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    User? createdUser;

    try {
      final trimmedFullName = fullName.trim();
      final trimmedEmail = email.trim();

      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      createdUser = credential.user;
      if (createdUser == null) {
        throw const AuthFailure(
          'Your account could not be created right now. Please try again.',
        );
      }

      if (trimmedFullName.isNotEmpty) {
        await createdUser.updateDisplayName(trimmedFullName);
      }

      await _firestore.collection('users').doc(createdUser.uid).set({
        'uid': createdUser.uid,
        'fullName': trimmedFullName,
        'email': trimmedEmail,
        'profileImageUrl': null,
        'role': 'student',
        'authProvider': 'password',
        'isProfileComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'Register auth error: code=${error.code}, message=${error.message}',
      );
      throw AuthFailure(_mapFirebaseError(error.code));
    } on FirebaseException catch (_) {
      await _deleteCreatedUser(createdUser);
      debugPrint('Register firestore error while saving profile.');
      throw const AuthFailure(
        'Your account was created, but we could not finish saving your profile. Please try again.',
      );
    } on AuthFailure {
      await _deleteCreatedUser(createdUser);
      rethrow;
    } catch (_) {
      await _deleteCreatedUser(createdUser);
      throw const AuthFailure(
        'Something went wrong while creating your account. Please try again.',
      );
    }
  }

  Future<void> _deleteCreatedUser(User? user) async {
    try {
      await user?.delete();
    } catch (_) {
      // Ignore cleanup failures so the original registration error is preserved.
    }
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'That email address is already in use. Try logging in instead.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password sign-up is not enabled for this project yet.';
      case 'network-request-failed':
        return 'Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts were made. Please wait a bit and try again.';
      case 'configurations-not-found':
        return 'Firebase Authentication is not configured correctly for this app yet.';
      case 'invalid-api-key':
        return 'This Firebase app configuration is invalid. Please check the project setup.';
      case 'app-not-authorized':
        return 'This app is not authorized in Firebase. Please check the Android app configuration.';
      case 'internal-error':
        return 'Firebase returned an internal error. Please try again in a moment.';
      case 'channel-error':
        return 'The request could not be sent. Please restart the app and try again.';
      default:
        return 'Could not create your account right now. Please try again.';
    }
  }

  String _mapSignInError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled for this project yet.';
      case 'network-request-failed':
        return 'Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts were made. Please wait a bit and try again.';
      case 'invalid-api-key':
        return 'This Firebase app configuration is invalid. Please check the project setup.';
      case 'app-not-authorized':
        return 'This app is not authorized in Firebase. Please check the Android app configuration.';
      case 'internal-error':
        return 'Firebase returned an internal error. Please try again in a moment.';
      case 'channel-error':
        return 'The request could not be sent. Please restart the app and try again.';
      default:
        return 'Could not sign you in right now. Please try again.';
    }
  }
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

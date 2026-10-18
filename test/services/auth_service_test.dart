// Firebase SDK interfaces are mocked; these tests never initialize Firebase.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockFirestore extends Mock implements FirebaseFirestore {}

class _MockUser extends Mock implements User {}

class _MockCredential extends Mock implements UserCredential {}

class _MockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockDocument extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

Matcher _authFailure(String message) =>
    isA<AuthFailure>().having((failure) => failure.message, 'message', message);

void main() {
  late _MockAuth auth;
  late _MockFirestore firestore;
  late _MockUser user;
  late _MockCredential credential;
  late _MockCollection users;
  late _MockDocument profile;
  late AuthService service;

  setUpAll(() => registerFallbackValue(SetOptions(merge: true)));

  setUp(() {
    auth = _MockAuth();
    firestore = _MockFirestore();
    user = _MockUser();
    credential = _MockCredential();
    users = _MockCollection();
    profile = _MockDocument();
    service = AuthService(firebaseAuth: auth, firestore: firestore);

    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('test-learner');
    when(() => credential.user).thenReturn(user);
    when(() => firestore.collection('users')).thenReturn(users);
    when(() => users.doc('test-learner')).thenReturn(profile);
    when(() => user.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => user.delete()).thenAnswer((_) async {});
    when(() => profile.set(any(), any())).thenAnswer((_) async {});
    when(
      () => auth.createUserWithEmailAndPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => credential);
  });

  group('Sign in', () {
    test('AUTH001 returns the credential and trims only the email', () async {
      // Arrange.
      when(
        () => auth.signInWithEmailAndPassword(
          email: 'learner@example.com',
          password: '  sample-password  ',
        ),
      ).thenAnswer((_) async => credential);

      // Act.
      final result = await service.signInWithEmailAndPassword(
        email: '  learner@example.com  ',
        password: '  sample-password  ',
      );

      // Assert.
      expect(result, same(credential));
      verify(
        () => auth.signInWithEmailAndPassword(
          email: 'learner@example.com',
          password: '  sample-password  ',
        ),
      ).called(1);
      verifyZeroInteractions(firestore);
    });

    final errors = <(String, String, String)>[
      ('AUTH002', 'invalid-email', 'Enter a valid email address.'),
      ('AUTH003', 'invalid-credential', 'Incorrect email or password.'),
      ('AUTH004', 'user-not-found', 'Incorrect email or password.'),
      ('AUTH005', 'wrong-password', 'Incorrect email or password.'),
      (
        'AUTH006',
        'user-disabled',
        'This account has been disabled. Please contact support.',
      ),
      (
        'AUTH007',
        'operation-not-allowed',
        'Email/password sign-in is not enabled for this project yet.',
      ),
      (
        'AUTH008',
        'network-request-failed',
        'Please check your internet connection and try again.',
      ),
      (
        'AUTH009',
        'too-many-requests',
        'Too many attempts were made. Please wait a bit and try again.',
      ),
      (
        'AUTH010',
        'invalid-api-key',
        'This Firebase app configuration is invalid. Please check the project setup.',
      ),
      (
        'AUTH011',
        'app-not-authorized',
        'This app is not authorized in Firebase. Please check the Android app configuration.',
      ),
      (
        'AUTH012',
        'internal-error',
        'Firebase returned an internal error. Please try again in a moment.',
      ),
      (
        'AUTH013',
        'channel-error',
        'The request could not be sent. Please restart the app and try again.',
      ),
      (
        'AUTH014',
        'unexpected-code',
        'Could not sign you in right now. Please try again.',
      ),
    ];
    for (final (id, code, expected) in errors) {
      test('$id maps sign-in error $code to a useful failure', () async {
        // Arrange.
        when(
          () => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: code));

        // Act.
        final result = service.signInWithEmailAndPassword(
          email: 'learner@example.com',
          password: 'sample-password',
        );

        // Assert.
        await expectLater(result, throwsA(_authFailure(expected)));
        verifyZeroInteractions(firestore);
      });
    }

    test(
      'AUTH015 maps unexpected sign-in exceptions to a generic failure',
      () async {
        // Arrange.
        when(
          () => auth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(StateError('SDK failure'));
        // Act.
        final result = service.signInWithEmailAndPassword(
          email: 'learner@example.com',
          password: 'sample-password',
        );
        // Assert.
        await expectLater(
          result,
          throwsA(
            _authFailure(
              'Something went wrong while signing you in. Please try again.',
            ),
          ),
        );
      },
    );
  });

  group('Registration', () {
    test(
      'AUTH016 saves a trimmed student profile after creating an account',
      () async {
        // Arrange.
        const password = '  sample-password  ';
        // Act.
        await service.registerWithEmailAndPassword(
          fullName: '  Alex Learner  ',
          email: '  learner@example.com  ',
          password: password,
        );
        // Assert.
        verify(
          () => auth.createUserWithEmailAndPassword(
            email: 'learner@example.com',
            password: password,
          ),
        ).called(1);
        final saved =
            verify(() => profile.set(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(saved, {
          'uid': 'test-learner',
          'fullName': 'Alex Learner',
          'email': 'learner@example.com',
          'profileImageUrl': null,
          'role': 'student',
          'authProvider': 'password',
          'isProfileComplete': false,
          'createdAt': isA<FieldValue>(),
          'updatedAt': isA<FieldValue>(),
        });
        verify(() => user.updateDisplayName('Alex Learner')).called(1);
        verifyNever(() => user.delete());
      },
    );

    test(
      'AUTH017 skips display-name updates when the trimmed name is empty',
      () async {
        // Arrange.
        const fullName = '  ';
        // Act.
        await service.registerWithEmailAndPassword(
          fullName: fullName,
          email: 'learner@example.com',
          password: 'sample-password',
        );
        // Assert.
        verifyNever(() => user.updateDisplayName(any()));
        final saved =
            verify(() => profile.set(captureAny())).captured.single
                as Map<String, dynamic>;
        expect(saved['fullName'], '');
        verifyNever(() => user.delete());
      },
    );

    test(
      'AUTH018 fails safely when Firebase returns no created user',
      () async {
        // Arrange.
        when(() => credential.user).thenReturn(null);
        // Act.
        final result = service.registerWithEmailAndPassword(
          fullName: 'Alex',
          email: 'learner@example.com',
          password: 'sample-password',
        );
        // Assert.
        await expectLater(
          result,
          throwsA(
            _authFailure(
              'Your account could not be created right now. Please try again.',
            ),
          ),
        );
        verifyZeroInteractions(firestore);
        verifyNever(() => user.delete());
      },
    );

    final errors = <(String, String, String)>[
      (
        'AUTH019',
        'email-already-in-use',
        'That email address is already in use. Try logging in instead.',
      ),
      ('AUTH020', 'invalid-email', 'Enter a valid email address.'),
      (
        'AUTH021',
        'weak-password',
        'Choose a stronger password with at least 6 characters.',
      ),
      (
        'AUTH022',
        'operation-not-allowed',
        'Email/password sign-up is not enabled for this project yet.',
      ),
      (
        'AUTH023',
        'network-request-failed',
        'Please check your internet connection and try again.',
      ),
      (
        'AUTH024',
        'too-many-requests',
        'Too many attempts were made. Please wait a bit and try again.',
      ),
      (
        'AUTH025',
        'configurations-not-found',
        'Firebase Authentication is not configured correctly for this app yet.',
      ),
      (
        'AUTH026',
        'invalid-api-key',
        'This Firebase app configuration is invalid. Please check the project setup.',
      ),
      (
        'AUTH027',
        'app-not-authorized',
        'This app is not authorized in Firebase. Please check the Android app configuration.',
      ),
      (
        'AUTH028',
        'internal-error',
        'Firebase returned an internal error. Please try again in a moment.',
      ),
      (
        'AUTH029',
        'channel-error',
        'The request could not be sent. Please restart the app and try again.',
      ),
      (
        'AUTH030',
        'unexpected-code',
        'Could not create your account right now. Please try again.',
      ),
    ];
    for (final (id, code, expected) in errors) {
      test(
        '$id maps registration error $code without saving a profile',
        () async {
          // Arrange.
          when(
            () => auth.createUserWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(FirebaseAuthException(code: code));
          // Act.
          final result = service.registerWithEmailAndPassword(
            fullName: 'Alex',
            email: 'learner@example.com',
            password: 'sample-password',
          );
          // Assert.
          await expectLater(result, throwsA(_authFailure(expected)));
          verifyZeroInteractions(firestore);
          verifyNever(() => user.delete());
        },
      );
    }

    test(
      'AUTH031 deletes the created account if storing its profile fails',
      () async {
        // Arrange.
        when(() => profile.set(any())).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );
        // Act.
        final result = service.registerWithEmailAndPassword(
          fullName: 'Alex',
          email: 'learner@example.com',
          password: 'sample-password',
        );
        // Assert.
        await expectLater(
          result,
          throwsA(
            _authFailure(
              'Your account was created, but we could not finish saving your profile. Please try again.',
            ),
          ),
        );
        verify(() => user.delete()).called(1);
      },
    );

    test(
      'AUTH032 preserves profile-save failure if account cleanup also fails',
      () async {
        // Arrange.
        when(() => profile.set(any())).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );
        when(() => user.delete()).thenThrow(StateError('Cleanup failed'));
        // Act.
        final result = service.registerWithEmailAndPassword(
          fullName: 'Alex',
          email: 'learner@example.com',
          password: 'sample-password',
        );
        // Assert.
        await expectLater(
          result,
          throwsA(
            _authFailure(
              'Your account was created, but we could not finish saving your profile. Please try again.',
            ),
          ),
        );
        verify(() => user.delete()).called(1);
      },
    );

    test(
      'AUTH033 rolls back a created account for unexpected profile errors',
      () async {
        // Arrange.
        when(
          () => profile.set(any()),
        ).thenThrow(StateError('Unexpected save failure'));
        // Act.
        final result = service.registerWithEmailAndPassword(
          fullName: 'Alex',
          email: 'learner@example.com',
          password: 'sample-password',
        );
        // Assert.
        await expectLater(
          result,
          throwsA(
            _authFailure(
              'Something went wrong while creating your account. Please try again.',
            ),
          ),
        );
        verify(() => user.delete()).called(1);
      },
    );

    test(
      'AUTH034 preserves a domain failure and rolls back the created account',
      () async {
        // Arrange.
        const failure = AuthFailure('Profile is temporarily unavailable.');
        when(() => profile.set(any())).thenThrow(failure);
        // Act.
        final result = service.registerWithEmailAndPassword(
          fullName: 'Alex',
          email: 'learner@example.com',
          password: 'sample-password',
        );
        // Assert.
        await expectLater(result, throwsA(same(failure)));
        verify(() => user.delete()).called(1);
      },
    );

    test(
      'AUTH035 rolls back if updating the created display name fails',
      () async {
        // Arrange.
        when(
          () => user.updateDisplayName(any()),
        ).thenThrow(StateError('Display-name failure'));
        // Act.
        final result = service.registerWithEmailAndPassword(
          fullName: 'Alex',
          email: 'learner@example.com',
          password: 'sample-password',
        );
        // Assert.
        await expectLater(
          result,
          throwsA(
            _authFailure(
              'Something went wrong while creating your account. Please try again.',
            ),
          ),
        );
        verify(() => user.delete()).called(1);
        verifyZeroInteractions(firestore);
      },
    );
  });

  group('Profile update', () {
    Future<void> updateProfile({bool nullable = false}) =>
        service.updateProfile(
          fullName: 'Alex Learner',
          username: nullable ? null : 'alex',
          phone: nullable ? null : '+94000000000',
          organization: nullable ? null : 'Example University',
          professionalTitle: nullable ? null : 'Student',
          bio: nullable ? null : 'Learning Flutter',
          skills: nullable ? [] : ['Dart'],
          learningInterests: nullable ? [] : ['Testing'],
        );

    test(
      'AUTH036 merges editable profile fields and updates the display name',
      () async {
        // Arrange: a signed-in test user and an isolated mock document.
        // Act.
        await updateProfile();
        // Assert.
        final captured = verify(
          () => profile.set(captureAny(), captureAny()),
        ).captured;
        expect(captured[0], {
          'fullName': 'Alex Learner',
          'username': 'alex',
          'phone': '+94000000000',
          'organization': 'Example University',
          'professionalTitle': 'Student',
          'bio': 'Learning Flutter',
          'skills': ['Dart'],
          'learningInterests': ['Testing'],
          'updatedAt': isA<FieldValue>(),
        });
        expect((captured[1] as SetOptions).merge, isTrue);
        verify(() => user.updateDisplayName('Alex Learner')).called(1);
      },
    );

    test(
      'AUTH037 persists null optional fields and empty skill lists',
      () async {
        // Arrange.
        const nullable = true;
        // Act.
        await updateProfile(nullable: nullable);
        // Assert.
        final saved =
            verify(() => profile.set(captureAny(), any())).captured.single
                as Map<String, dynamic>;
        for (final field in [
          'username',
          'phone',
          'organization',
          'professionalTitle',
          'bio',
        ]) {
          expect(
            saved.containsKey(field),
            isTrue,
            reason: '$field must explicitly clear its previous value',
          );
          expect(saved[field], isNull);
        }
        expect(saved['skills'], isEmpty);
        expect(saved['learningInterests'], isEmpty);
      },
    );

    test('AUTH038 rejects profile updates without a signed-in user', () async {
      // Arrange.
      when(() => auth.currentUser).thenReturn(null);
      // Act.
      final result = updateProfile();
      // Assert.
      await expectLater(
        result,
        throwsA(_authFailure('No signed-in user is available.')),
      );
      verifyZeroInteractions(firestore);
      verifyNever(() => user.updateDisplayName(any()));
    });

    test('AUTH039 maps Firestore update errors to a profile failure', () async {
      // Arrange.
      when(() => profile.set(any(), any())).thenThrow(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      // Act.
      final result = updateProfile();
      // Assert.
      await expectLater(
        result,
        throwsA(_authFailure('Unable to update profile. Please try again.')),
      );
      verifyNever(() => user.delete());
    });

    test(
      'AUTH040 stops before saving if the display-name update fails',
      () async {
        // Arrange.
        when(
          () => user.updateDisplayName(any()),
        ).thenThrow(FirebaseAuthException(code: 'requires-recent-login'));
        // Act.
        final result = updateProfile();
        // Assert.
        await expectLater(
          result,
          throwsA(_authFailure('Unable to update profile. Please try again.')),
        );
        verifyZeroInteractions(firestore);
        verifyNever(() => user.delete());
      },
    );

    test(
      'AUTH041 maps unexpected profile update errors to a profile failure',
      () async {
        // Arrange.
        when(
          () => profile.set(any(), any()),
        ).thenThrow(StateError('Unexpected error'));
        // Act.
        final result = updateProfile();
        // Assert.
        await expectLater(
          result,
          throwsA(_authFailure('Unable to update profile. Please try again.')),
        );
      },
    );
  });

  group('Sign out', () {
    test(
      'AUTH042 signs out exactly once without changing profile data',
      () async {
        // Arrange.
        when(() => auth.signOut()).thenAnswer((_) async {});
        // Act.
        await service.signOut();
        // Assert.
        verify(() => auth.signOut()).called(1);
        verifyZeroInteractions(firestore);
      },
    );

    test('AUTH043 propagates sign-out failures to the caller', () async {
      // Arrange.
      final failure = FirebaseAuthException(code: 'network-request-failed');
      when(() => auth.signOut()).thenThrow(failure);
      // Act.
      final result = service.signOut();
      // Assert.
      await expectLater(result, throwsA(same(failure)));
    });
  });
}

// Auth-state gates are exercised without Firebase credentials or network access.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:edupro_mobile_app/features/auth/presentation/screens/login_screen.dart';
import 'package:edupro_mobile_app/features/auth/presentation/screens/register_screen.dart';
import 'package:edupro_mobile_app/features/profile/presentation/screens/shared_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _User implements User {
  _User(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  _Auth([this.currentUser]);

  final _changes = StreamController<User?>.broadcast();
  int watchCount = 0;

  @override
  User? currentUser;

  @override
  Stream<User?> authStateChanges() {
    watchCount++;
    return _changes.stream.map((user) => user);
  }

  void change(User? user) {
    currentUser = user;
    _changes.add(user);
  }

  void fail() => _changes.addError(StateError('Authentication unavailable'));

  Future<void> close() => _changes.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester,
  _Auth auth, {
  String userId = 'shared-author',
  WidgetBuilder? profileBuilder,
}) async {
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: SharedProfileScreen(
        userId: userId,
        firebaseAuth: auth,
        profileBuilder:
            profileBuilder ??
            (_) => const Scaffold(body: Text('Selected author profile')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _activateTextLink(WidgetTester tester, String label) async {
  TapGestureRecognizer? link;
  for (final richText in tester.widgetList<RichText>(find.byType(RichText))) {
    richText.text.visitChildren((span) {
      if (span is TextSpan &&
          span.text == label &&
          span.recognizer is TapGestureRecognizer) {
        link = span.recognizer! as TapGestureRecognizer;
      }
      return true;
    });
  }
  expect(link, isNotNull, reason: 'The $label link must remain available.');
  link!.onTap!();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed-out shared links do not build the profile', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.close);
    var profileBuilds = 0;
    await _open(
      tester,
      auth,
      profileBuilder: (_) {
        profileBuilds++;
        return const Text('Private profile route');
      },
    );

    expect(find.text('Sign in to view this profile.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Private profile route'), findsNothing);
    expect(profileBuilds, 0);
    expect(auth.watchCount, 1);
  });

  testWidgets('signed-in viewers keep the shared author as the target', (
    tester,
  ) async {
    final auth = _Auth(_User('viewer-account'));
    addTearDown(auth.close);
    await _open(tester, auth, userId: 'selected-author');

    expect(find.text('Selected author profile'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);
    expect(
      tester
          .widget<SharedProfileScreen>(find.byType(SharedProfileScreen))
          .userId,
      'selected-author',
    );
    expect(
      find.byKey(
        const ValueKey('shared-profile:selected-author:viewer-account'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('signing out removes the profile and keeps one auth stream', (
    tester,
  ) async {
    final auth = _Auth(_User('viewer-account'));
    addTearDown(auth.close);
    await _open(tester, auth);
    expect(find.text('Selected author profile'), findsOneWidget);

    auth.change(null);
    await tester.pumpAndSettle();
    expect(find.text('Selected author profile'), findsNothing);
    expect(find.text('Sign in to view this profile.'), findsOneWidget);

    auth.change(_User('another-viewer'));
    await tester.pumpAndSettle();
    expect(find.text('Selected author profile'), findsOneWidget);
    expect(auth.watchCount, 1);
  });

  testWidgets('auth errors hide the profile and can be retried', (
    tester,
  ) async {
    final auth = _Auth(_User('viewer-account'));
    addTearDown(auth.close);
    await _open(tester, auth);

    auth.fail();
    await tester.pumpAndSettle();
    expect(find.text('Selected author profile'), findsNothing);
    expect(find.text('Unable to check your sign-in status.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(auth.watchCount, 2);
    auth.change(_User('viewer-account'));
    await tester.pumpAndSettle();
    expect(find.text('Selected author profile'), findsOneWidget);
  });

  testWidgets('sign-in navigation retains the shared profile destination', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.close);
    await _open(tester, auth, userId: 'author-from-link');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    final login = tester.widget<LoginScreen>(find.byType(LoginScreen));
    final destination =
        login.destinationBuilder!(tester.element(find.byType(LoginScreen)))
            as SharedProfileScreen;
    expect(destination.userId, 'author-from-link');
    expect(destination.firebaseAuth, same(auth));
    expect(destination.profileBuilder, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sign-up and return-to-login preserve the same destination', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.close);
    await _open(tester, auth, userId: 'author-from-link');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    final firstLogin = tester.widget<LoginScreen>(find.byType(LoginScreen));

    await _activateTextLink(tester, 'Sign Up');
    final register = tester.widget<RegisterScreen>(find.byType(RegisterScreen));
    expect(register.destinationBuilder, same(firstLogin.destinationBuilder));

    await _activateTextLink(tester, 'Login');
    final returnedLogin = tester.widget<LoginScreen>(find.byType(LoginScreen));
    expect(
      returnedLogin.destinationBuilder,
      same(firstLogin.destinationBuilder),
    );
    final destination =
        returnedLogin.destinationBuilder!(
              tester.element(find.byType(LoginScreen)),
            )
            as SharedProfileScreen;
    expect(destination.userId, 'author-from-link');
    expect(tester.takeException(), isNull);
  });

  test('ordinary authentication screens have no destination override', () {
    expect(const LoginScreen().destinationBuilder, isNull);
    expect(const RegisterScreen().destinationBuilder, isNull);
  });
}

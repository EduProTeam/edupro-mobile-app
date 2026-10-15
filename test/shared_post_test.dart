// Exercise session changes without Firebase credentials or network access.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:edupro_mobile_app/features/auth/presentation/screens/login_screen.dart';
import 'package:edupro_mobile_app/features/auth/presentation/screens/register_screen.dart';
import 'package:edupro_mobile_app/features/posts/presentation/screens/shared_post_screen.dart';
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

  Future<void> close() => _changes.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _open(
  WidgetTester tester,
  _Auth auth, {
  WidgetBuilder? builder,
}) async {
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: SharedPostScreen(
        postId: 'post-from-link',
        firebaseAuth: auth,
        postBuilder:
            builder ?? (_) => const Scaffold(body: Text('Shared lesson')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _activateLink(WidgetTester tester, String label) async {
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
  expect(link, isNotNull);
  link!.onTap!();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('signed-out shared post does not build any post content', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.close);
    var builds = 0;
    await _open(
      tester,
      auth,
      builder: (_) {
        builds++;
        return const Text('Shared lesson');
      },
    );
    expect(find.text('Sign in to view this post.'), findsOneWidget);
    expect(find.text('Shared lesson'), findsNothing);
    expect(builds, 0);
  });

  testWidgets(
    'shared post follows auth state without changing its selected ID',
    (tester) async {
      final auth = _Auth(_User('viewer'));
      addTearDown(auth.close);
      await _open(tester, auth);
      expect(
        find.byKey(const ValueKey('shared-post:post-from-link:viewer')),
        findsOneWidget,
      );
      expect(find.text('Shared lesson'), findsOneWidget);

      auth.change(null);
      await tester.pumpAndSettle();
      expect(find.text('Shared lesson'), findsNothing);
      expect(find.text('Sign in to view this post.'), findsOneWidget);

      auth.change(_User('another-viewer'));
      await tester.pumpAndSettle();
      expect(find.text('Shared lesson'), findsOneWidget);
      expect(
        tester.widget<SharedPostScreen>(find.byType(SharedPostScreen)).postId,
        'post-from-link',
      );
      expect(auth.watchCount, 1);
    },
  );

  testWidgets('post destination survives login and registration navigation', (
    tester,
  ) async {
    final auth = _Auth();
    addTearDown(auth.close);
    await _open(tester, auth);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    final login = tester.widget<LoginScreen>(find.byType(LoginScreen));
    final destinationBuilder = login.destinationBuilder!;

    await _activateLink(tester, 'Sign Up');
    expect(
      tester
          .widget<RegisterScreen>(find.byType(RegisterScreen))
          .destinationBuilder,
      same(destinationBuilder),
    );
    await _activateLink(tester, 'Login');
    final returnedLogin = tester.widget<LoginScreen>(find.byType(LoginScreen));
    expect(returnedLogin.destinationBuilder, same(destinationBuilder));
    final destination =
        returnedLogin.destinationBuilder!(
              tester.element(find.byType(LoginScreen)),
            )
            as SharedPostScreen;
    expect(destination.postId, 'post-from-link');
    expect(destination.firebaseAuth, same(auth));
    expect(destination.postBuilder, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

// Exercise application routing with a signed-out Firebase session.
// ignore_for_file: depend_on_referenced_packages

import 'package:edupro_mobile_app/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:edupro_mobile_app/features/posts/presentation/screens/shared_post_screen.dart';
import 'package:edupro_mobile_app/features/profile/presentation/screens/shared_profile_screen.dart';
import 'package:edupro_mobile_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:edupro_mobile_app/main.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Widget tests have no raster thread; signal the synthetic visible frame.
class _VisibleFrameBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  Future<void> get waitUntilFirstFrameRasterized => Future<void>.value();
}

class _FirebasePlatform extends FirebasePlatform {
  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async => app(name ?? defaultFirebaseAppName);

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) =>
      FirebaseAppPlatform(
        name,
        const FirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test',
        ),
      );
}

class _SignedOutAuthPlatform extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform? get currentUser => null;

  @override
  Stream<UserPlatform?> authStateChanges() => Stream.value(null);
}

void _configure(WidgetTester tester, String initialRoute) {
  final originalCore = FirebasePlatform.instance;
  final originalAuth = FirebaseAuthPlatform.instance;
  FirebasePlatform.instance = _FirebasePlatform();
  FirebaseAuthPlatform.instance = _SignedOutAuthPlatform();
  tester.platformDispatcher.defaultRouteNameTestValue = initialRoute;
  tester.view.physicalSize = const Size(600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    FirebasePlatform.instance = originalCore;
    FirebaseAuthPlatform.instance = originalAuth;
    tester.platformDispatcher.clearDefaultRouteNameTestValue();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void _expectSharedAuthor(WidgetTester tester, String userId) {
  expect(find.byType(SharedProfileScreen), findsOneWidget);
  expect(
    tester.widget<SharedProfileScreen>(find.byType(SharedProfileScreen)).userId,
    userId,
  );
  expect(find.text('Sign in to view this profile.'), findsOneWidget);
}

void _expectSharedPost(WidgetTester tester, String postId) {
  expect(find.byType(SharedPostScreen), findsOneWidget);
  expect(
    tester.widget<SharedPostScreen>(find.byType(SharedPostScreen)).postId,
    postId,
  );
  expect(find.text('Sign in to view this post.'), findsOneWidget);
}

void main() {
  _VisibleFrameBinding();
  for (final route in [
    'edupro://app/post/cold-post',
    '/post/cold-post',
    '/#/post/cold-post',
  ]) {
    testWidgets('cold post route $route opens only the selected post gate', (
      tester,
    ) async {
      _configure(tester, route);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      _expectSharedPost(tester, 'cold-post');
      expect(find.byType(SharedProfileScreen), findsNothing);
      expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      _expectSharedPost(tester, 'cold-post');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a warm post link survives a pending splash timer', (
    tester,
  ) async {
    _configure(tester, '/');
    await tester.pumpWidget(const MyApp());
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed<void>('/post/warm-post');
    await tester.pumpAndSettle();
    _expectSharedPost(tester, 'warm-post');

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    _expectSharedPost(tester, 'warm-post');
    expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen1), findsOneWidget);
    expect(find.byType(SharedPostScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('malformed post links cannot open another document path', (
    tester,
  ) async {
    _configure(tester, 'edupro://app/post/lesson%2Fother');
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('This link is not available.'), findsOneWidget);
    expect(find.byType(SharedPostScreen, skipOffstage: false), findsNothing);
    expect(find.byType(SharedProfileScreen, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final route in [
    'edupro://app/profile/cold-author',
    '/profile/cold-author',
  ]) {
    testWidgets(
      'cold profile route $route does not create a splash underneath',
      (tester) async {
        _configure(tester, route);
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        _expectSharedAuthor(tester, 'cold-author');
        expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        expect(navigator.canPop(), isFalse);

        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        _expectSharedAuthor(tester, 'cold-author');
        expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('a warm profile link survives the pending splash timer', (
    tester,
  ) async {
    _configure(tester, '/');
    await tester.pumpWidget(const MyApp());
    expect(find.byType(SplashScreen), findsOneWidget);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pushNamed<void>('/profile/warm-author');
    await tester.pumpAndSettle();
    _expectSharedAuthor(tester, 'warm-author');
    expect(find.byType(SplashScreen, skipOffstage: false), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    _expectSharedAuthor(tester, 'warm-author');
    expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);

    // Back must reveal the normal signed-out destination, not an old splash.
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen1), findsOneWidget);
    expect(find.byType(SharedProfileScreen), findsNothing);
    expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a malformed profile link opens the unavailable-link screen', (
    tester,
  ) async {
    _configure(tester, 'edupro://app/profile/author%2Fother');
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('This link is not available.'), findsOneWidget);
    expect(find.byType(SharedProfileScreen, skipOffstage: false), findsNothing);
    expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('normal launch still goes from splash to onboarding', (
    tester,
  ) async {
    _configure(tester, '/');
    await tester.pumpWidget(const MyApp());
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen1), findsOneWidget);
    expect(find.byType(SplashScreen, skipOffstage: false), findsNothing);
    expect(find.byType(SharedProfileScreen, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';

import 'package:edupro_mobile_app/core/theme/app_colors.dart';
import 'package:edupro_mobile_app/core/theme/app_theme.dart';

import 'package:edupro_mobile_app/features/home/presentation/screens/home_shell_screen.dart';
import 'package:edupro_mobile_app/features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'package:edupro_mobile_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:edupro_mobile_app/features/splash/presentation/splash_timing.dart';
import 'package:edupro_mobile_app/shared/branding/edupro_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Widget tests have no engine raster thread. Signal their synthetic visible
// frame immediately; production waits for the engine's first rasterized frame.
class _VisibleFrameBinding extends AutomatedTestWidgetsFlutterBinding {
  Future<void>? visibleFrame;

  @override
  Future<void> get waitUntilFirstFrameRasterized =>
      visibleFrame ?? Future<void>.value();
}

class _LaunchObserver extends NavigatorObserver {
  final replacements = <Route<dynamic>>[];

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) replacements.add(newRoute);
  }
}

Future<_LaunchObserver> _launch(
  WidgetTester tester,
  Future<bool> Function() resolve, {
  bool reduceMotion = false,
  ThemeData? theme,
  Size size = const Size(800, 1000),
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final observer = _LaunchObserver();
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      navigatorObservers: [observer],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations: reduceMotion,
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      ),
      home: SplashScreen(resolveSignedIn: resolve),
    ),
  );
  await tester.pump();
  return observer;
}

void main() {
  final binding = _VisibleFrameBinding();

  testWidgets('Native startup time does not count toward the visible hold', (
    tester,
  ) async {
    final visible = Completer<void>();
    binding.visibleFrame = visible.future;
    addTearDown(() => binding.visibleFrame = null);
    final observer = await _launch(tester, () async => false);
    await tester.pump(const Duration(seconds: 5));
    expect(observer.replacements, isEmpty);
    visible.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2799));
    expect(observer.replacements, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(observer.replacements, hasLength(1));
    await tester.pumpAndSettle();
  });
  testWidgets('Fast startup holds branding until 2800ms and replaces once', (
    tester,
  ) async {
    final observer = await _launch(tester, () async => false);
    await tester.pump(const Duration(milliseconds: 2799));
    expect(observer.replacements, isEmpty);
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    expect(observer.replacements, hasLength(1));
    expect(
      (observer.replacements.single as PageRoute).transitionDuration,
      SplashTiming.exitTransition,
    );
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen1), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    await tester.pump(const Duration(seconds: 5));
    expect(observer.replacements, hasLength(1));
  });

  testWidgets('Slow startup routes as soon as ready without another hold', (
    tester,
  ) async {
    final session = Completer<bool>();
    final observer = await _launch(tester, () => session.future);
    await tester.pump(const Duration(seconds: 4));
    expect(observer.replacements, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    session.complete(false);
    await tester.pump();
    expect(observer.replacements, hasLength(1));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen1), findsOneWidget);
  });

  testWidgets('Signed-in readiness chooses the existing home destination', (
    tester,
  ) async {
    final observer = await _launch(tester, () async => true);
    await tester.pump(SplashTiming.minimumDisplay);
    expect(observer.replacements, hasLength(1));
    final route = observer.replacements.single as PageRouteBuilder<void>;
    // Inspect the route before building Firebase-backed home widgets.
    final destination = route.pageBuilder(
      tester.element(find.byType(SplashScreen)),
      const AlwaysStoppedAnimation(1),
      const AlwaysStoppedAnimation(0),
    );
    expect(destination, isA<HomeShellScreen>());
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Timeout permits retry and ignores a late first result', (
    tester,
  ) async {
    final first = Completer<bool>();
    final retry = Completer<bool>();
    var calls = 0;
    final observer = await _launch(
      tester,
      () => ++calls == 1 ? first.future : retry.future,
    );
    await tester.pump(SplashTiming.initializationTimeout);
    expect(find.text('Retry'), findsOneWidget);
    expect(observer.replacements, isEmpty);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    first.complete(true);
    await tester.pump();
    expect(observer.replacements, isEmpty);
    retry.complete(false);
    await tester.pump();
    expect(observer.replacements, hasLength(1));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen1), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('Initialization failure stays usable and retry succeeds', (
    tester,
  ) async {
    var calls = 0;
    final observer = await _launch(tester, () async {
      if (++calls == 1) throw StateError('offline');
      return false;
    });
    expect(find.text('Retry'), findsOneWidget);
    await tester.pump(SplashTiming.minimumDisplay);
    expect(observer.replacements, isEmpty);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(observer.replacements, hasLength(1));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen1), findsOneWidget);
  });

  testWidgets('Reduced motion retains completed branding for the minimum', (
    tester,
  ) async {
    final observer = await _launch(
      tester,
      () async => false,
      reduceMotion: true,
    );
    final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
    expect(opacities.every((opacity) => opacity.opacity == 1), isTrue);
    expect(find.byType(EduProWordmark), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2799));
    expect(observer.replacements, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(observer.replacements, hasLength(1));
    await tester.pumpAndSettle();
  });

  testWidgets('Resume does not restart the animation or launch clock', (
    tester,
  ) async {
    final observer = await _launch(tester, () async => false);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 800));
    expect(observer.replacements, hasLength(1));
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byType(SplashScreen), findsNothing);
    expect(observer.replacements, hasLength(1));
  });

  testWidgets('dark mode preserves readable branding and launch timing', (
    tester,
  ) async {
    final observer = await _launch(
      tester,
      () async => false,
      reduceMotion: true,
      theme: AppTheme.dark,
    );
    final wordmark = tester.widget<Text>(
      find.descendant(
        of: find.byType(EduProWordmark),
        matching: find.byType(Text),
      ),
    );
    final spans = (wordmark.textSpan! as TextSpan).children!;
    expect((spans.first as TextSpan).style!.color, AppPalette.dark.textPrimary);
    final overlay = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
    );
    expect(overlay.value.statusBarIconBrightness, Brightness.light);
    await tester.pump(const Duration(milliseconds: 2799));
    expect(observer.replacements, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(observer.replacements, hasLength(1));
    await tester.pumpAndSettle();
  });

  testWidgets('Disposal cancels timers and ignores pending initialization', (
    tester,
  ) async {
    final session = Completer<bool>();
    await _launch(tester, () => session.future);
    await tester.pumpWidget(const SizedBox());
    session.complete(false);
    await tester.pump(const Duration(seconds: 20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Compact phone fits the composition with larger text', (
    tester,
  ) async {
    final session = Completer<bool>();
    await _launch(
      tester,
      () => session.future,
      size: const Size(320, 568),
      textScale: 2,
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(find.text('Learn. Share. Grow.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.complete(false);
  });
}

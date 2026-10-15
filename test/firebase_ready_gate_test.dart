// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:edupro_mobile_app/core/firebase/app_firebase.dart';
import 'package:edupro_mobile_app/features/auth/presentation/widgets/firebase_ready_gate.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _InitializingFirebasePlatform extends FirebasePlatform {
  int calls = 0;
  FirebaseOptions? lastOptions;
  Completer<FirebaseAppPlatform> pending = Completer<FirebaseAppPlatform>();

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) {
    calls++;
    lastOptions = options;
    return pending.future;
  }
}

void main() {
  test(
    'Firebase startup is shared, retained on success, and retryable on error',
    () async {
      final previous = FirebasePlatform.instance;
      final platform = _InitializingFirebasePlatform();
      FirebasePlatform.instance = platform;
      addTearDown(() => FirebasePlatform.instance = previous);

      final first = AppFirebase.ensureInitialized();
      expect(AppFirebase.ensureInitialized(), same(first));
      expect(platform.calls, 1);
      expect(platform.lastOptions, isNotNull);
      final failure = expectLater(first, throwsStateError);
      platform.pending.completeError(StateError('offline'));
      await failure;

      platform.pending = Completer<FirebaseAppPlatform>();
      final retry = AppFirebase.ensureInitialized();
      expect(retry, isNot(same(first)));
      expect(AppFirebase.ensureInitialized(), same(retry));
      expect(platform.calls, 2);
      platform.pending.complete(
        FirebaseAppPlatform(defaultFirebaseAppName, platform.lastOptions!),
      );
      await retry;
      await AppFirebase.ensureInitialized();
      expect(platform.calls, 2);
    },
  );

  testWidgets(
    'destination builds only after initialization and survives rebuilds',
    (tester) async {
      final ready = Completer<void>();
      var calls = 0;
      var destinationBuilds = 0;
      Future<void> initialize() {
        calls++;
        return ready.future;
      }

      Widget gate(String destination) => MaterialApp(
        home: FirebaseReadyGate(
          initialize: initialize,
          builder: (_) {
            destinationBuilds++;
            return Scaffold(body: Text(destination));
          },
        ),
      );

      await tester.pumpWidget(gate('Selected post'));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(destinationBuilds, 0);
      expect(calls, 1);
      await tester.pumpWidget(gate('Selected profile'));
      expect(calls, 1);
      expect(destinationBuilds, 0);

      ready.complete();
      await tester.pumpAndSettle();
      expect(find.text('Selected profile'), findsOneWidget);
      expect(find.text('Selected post'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(destinationBuilds, greaterThan(0));
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed initialization retries before opening the same destination',
    (tester) async {
      final retry = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: FirebaseReadyGate(
            initialize: () {
              if (++calls == 1) throw StateError('offline');
              return retry.future;
            },
            builder: (_) => const Scaffold(body: Text('Selected post')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to initialize EduPro. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Selected post'), findsNothing);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(calls, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Selected post'), findsNothing);

      retry.complete();
      await tester.pumpAndSettle();
      expect(find.text('Selected post'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final fails in [false, true]) {
    testWidgets(
      'disposal safely ignores late initialization ${fails ? 'failure' : 'success'}',
      (tester) async {
        final ready = Completer<void>();
        var builds = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: FirebaseReadyGate(
              initialize: () => ready.future,
              builder: (_) {
                builds++;
                return const Text('Selected post');
              },
            ),
          ),
        );
        await tester.pumpWidget(const SizedBox());
        if (fails) {
          ready.completeError(StateError('offline'));
        } else {
          ready.complete();
        }
        await tester.pump();
        expect(builds, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

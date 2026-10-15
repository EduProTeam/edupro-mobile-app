import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Shares Firebase startup between the normal launch and incoming app links.
abstract final class AppFirebase {
  static Future<void>? _initialization;
  static bool _initialized = false;

  /// Shares in-flight startup, retains readiness, and permits failed retries.
  static Future<void> ensureInitialized() {
    // Completed futures retain their originating zone. Return a fresh completion
    // in the caller's zone once startup has succeeded, without initializing again.
    if (_initialized) return Future<void>.value();
    return _initialization ??= _initialize().then<void>(
      (_) {
        _initialized = true;
        _initialization = null;
      },
      onError: (Object error, StackTrace stack) {
        _initialization = null;
        Error.throwWithStackTrace(error, stack);
      },
    );
  }

  static Future<void> _initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

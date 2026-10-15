import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/firebase/app_firebase.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/branding/edupro_brand.dart';
import '../../../home/presentation/screens/home_shell_screen.dart';
import '../../../onboarding/presentation/screens/onboarding_screen_1.dart';
import '../splash_timing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.resolveSignedIn});

  final Future<bool> Function()? resolveSignedIn;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = EduProBrand.blue;
  late final AnimationController _entrance;
  bool? _signedIn;
  bool _entranceComplete = false;
  bool _navigated = false;
  bool _failed = false;
  bool _minimumElapsed = false;
  bool _reduceMotion = false;
  bool _visibleSequenceStarted = false;
  Timer? _minimumDisplayTimer;
  Timer? _initializationTimeout;
  Future<void>? _firebaseInitialization;
  StreamSubscription<User?>? _authSubscription;
  Completer<bool>? _authReady;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _entrance =
        AnimationController(vsync: this, duration: SplashTiming.entrance)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _entranceComplete = true;
              _tryNavigate();
            }
          });
    _initialize();
    // Start when the first frame has reached the rasterizer. A post-frame
    // callback alone can run while the native splash is still covering Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
      if (!mounted) return;
      _visibleSequenceStarted = true;
      _minimumDisplayTimer = Timer(SplashTiming.minimumDisplay, () {
        if (!mounted) return;
        setState(() => _minimumElapsed = true);
        _tryNavigate();
      });
      if (!_reduceMotion) _entrance.forward();
    });
  }

  Future<bool> _resolveSignedIn(int attempt) async {
    // Reuse an in-flight native initialization if the user retries a timeout.
    _firebaseInitialization ??= AppFirebase.ensureInitialized();
    try {
      await _firebaseInitialization;
    } catch (_) {
      _firebaseInitialization = null;
      rethrow;
    }
    if (!mounted || attempt != _attempt) throw StateError('Launch cancelled');
    final ready = Completer<bool>();
    _authReady = ready;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (user) {
        if (!ready.isCompleted) ready.complete(user != null);
      },
      onError: (Object error, StackTrace stack) {
        if (!ready.isCompleted) ready.completeError(error, stack);
      },
    );
    try {
      return await ready.future;
    } finally {
      if (identical(_authReady, ready)) _cancelAuthWait();
    }
  }

  void _cancelAuthWait() {
    final subscription = _authSubscription;
    _authSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    final ready = _authReady;
    _authReady = null;
    if (ready != null && !ready.isCompleted) {
      ready.completeError(StateError('Launch cancelled'));
    }
  }

  void _initialize() {
    final attempt = ++_attempt;
    _initializationTimeout?.cancel();
    _cancelAuthWait();
    setState(() {
      _failed = false;
      _signedIn = null;
    });
    _initializationTimeout = Timer(SplashTiming.initializationTimeout, () {
      if (!mounted || attempt != _attempt) return;
      _attempt++;
      _cancelAuthWait();
      setState(() => _failed = true);
    });
    unawaited(_runInitialization(attempt));
  }

  Future<void> _runInitialization(int attempt) async {
    try {
      final signedIn = widget.resolveSignedIn != null
          ? await widget.resolveSignedIn!()
          : await _resolveSignedIn(attempt);
      if (!mounted || attempt != _attempt) return;
      _initializationTimeout?.cancel();
      setState(() => _signedIn = signedIn);
      _tryNavigate();
    } catch (error) {
      if (!mounted || attempt != _attempt) return;
      debugPrint('Launch initialization failed: $error');
      _initializationTimeout?.cancel();
      setState(() => _failed = true);
    }
  }

  void _tryNavigate() {
    if (!mounted || _navigated || !_minimumElapsed || _signedIn == null) {
      return;
    }
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final destination = _signedIn!
          ? const HomeShellScreen()
          : const OnboardingScreen1();
      final navigator = Navigator.of(context);
      final splashRoute = ModalRoute.of(context);
      final nextRoute = PageRouteBuilder<void>(
        pageBuilder: (_, animation, secondaryAnimation) => destination,
        transitionDuration: SplashTiming.exitTransition,
        transitionsBuilder: (_, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      );
      // A shared link can arrive while this launch sequence is still running.
      if (splashRoute != null && !splashRoute.isCurrent) {
        navigator.replace(oldRoute: splashRoute, newRoute: nextRoute);
      } else {
        navigator.pushReplacement(nextRoute);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _entrance.value = 1;
    } else if (_visibleSequenceStarted && _entrance.isDismissed) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _attempt++;
    _minimumDisplayTimer?.cancel();
    _initializationTimeout?.cancel();
    _cancelAuthWait();
    _entrance.dispose();
    super.dispose();
  }

  double _progress(Duration start, Duration end) {
    final elapsed = _entrance.value * SplashTiming.entrance.inMilliseconds;
    return Curves.easeOutCubic.transform(
      ((elapsed - start.inMilliseconds) /
              (end.inMilliseconds - start.inMilliseconds))
          .clamp(0.0, 1.0),
    );
  }

  Widget _reveal(
    Widget child,
    Duration start,
    Duration end, {
    double travel = 10,
  }) {
    final progress = _progress(start, end);
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, travel * (1 - progress)),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: colors.surface,
        statusBarIconBrightness: colors.isDark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: colors.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: colors.isDark
            ? colors.background
            : const Color(0xFFEDF6FF),
        systemNavigationBarIconBrightness: colors.isDark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors.isDark
                  ? [colors.surface, colors.background, colors.primarySoft]
                  : const [Colors.white, Color(0xFFF8FBFF), Color(0xFFEDF6FF)],
              stops: [0, 0.54, 1],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(top: -85, right: -105, child: _glow(240)),
                Positioned(bottom: -150, left: -125, child: _glow(300)),
                Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: AnimatedBuilder(
                            animation: _entrance,
                            builder: (context, _) => FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Transform.translate(
                                offset: const Offset(0, -12),
                                child: _brand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _entrance,
                      builder: (context, _) => _reveal(
                        Text(
                          'A little learning. A world of possibilities.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SplashTiming.finishingStart,
                        SplashTiming.finishingEnd,
                        travel: 5,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _glow(double size) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [Color(0x159BD5FF), Color(0x009BD5FF)],
        ),
      ),
    ),
  );

  Widget _brand() {
    final logoProgress = _progress(
      SplashTiming.logoStart,
      SplashTiming.logoEnd,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: logoProgress,
          child: Transform.scale(
            scale: 0.88 + 0.12 * logoProgress,
            child: Semantics(
              label: 'EduPro',
              image: true,
              child: SizedBox.square(
                dimension: 140,
                child: Stack(
                  children: [
                    // Preserve the source SVG's paint order and viewBox.
                    _logoPiece(
                      EduProBrand.tassel,
                      SplashTiming.tasselStart,
                      SplashTiming.tasselEnd,
                    ),
                    _logoPiece(
                      EduProBrand.letterE,
                      SplashTiming.letterEStart,
                      SplashTiming.letterEEnd,
                    ),
                    _logoPiece(
                      EduProBrand.letterP,
                      SplashTiming.letterPStart,
                      SplashTiming.letterPEnd,
                    ),
                    _logoPiece(
                      EduProBrand.cap,
                      SplashTiming.capStart,
                      SplashTiming.capEnd,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _reveal(
          const EduProWordmark(fontSize: 46),
          SplashTiming.wordmarkStart,
          SplashTiming.wordmarkEnd,
        ),
        const SizedBox(height: 12),
        _reveal(
          Text(
            'Learn. Share. Grow.',
            style: TextStyle(
              color: context.appColors.textSecondary,
              fontSize: 14,
              letterSpacing: 1.1,
            ),
          ),
          SplashTiming.taglineStart,
          SplashTiming.taglineEnd,
        ),
        const SizedBox(height: 20),
        _reveal(
          Container(
            width: 38,
            height: 3,
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SplashTiming.finishingStart,
          SplashTiming.finishingEnd,
          travel: 4,
        ),
        if (_failed) ...[
          const SizedBox(height: 30),
          const Text('Unable to start EduPro. Please try again.'),
          TextButton(onPressed: _initialize, child: const Text('Retry')),
        ] else if (_entranceComplete && _signedIn == null) ...[
          const SizedBox(height: 30),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
          ),
        ],
      ],
    );
  }

  Widget _logoPiece(String asset, Duration start, Duration end) => _reveal(
    SvgPicture.asset(
      asset,
      colorMapper: context.appColors.isDark
          ? const EduProDarkColorMapper()
          : null,
      width: 140,
      height: 140,
      excludeFromSemantics: true,
    ),
    start,
    end,
  );
}

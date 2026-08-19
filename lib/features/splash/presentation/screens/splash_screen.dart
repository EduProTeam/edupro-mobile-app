import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../onboarding/presentation/screens/onboarding_screen_1.dart';
import '../../../home/presentation/screens/home_shell_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _backgroundColor = Color(0xFF3D8FEF);

  @override
  void initState() {
    super.initState();
    _routeFromSplash();
  }

  Future<void> _routeFromSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    if (!mounted) {
      return;
    }

    final nextScreen = FirebaseAuth.instance.currentUser != null
        ? const HomeShellScreen()
        : const OnboardingScreen1();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => nextScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _backgroundColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: _backgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final brandingWidth =
                (constraints.maxWidth * 0.6).clamp(225.0, 300.0).toDouble();

            return Center(
              child: SizedBox(
                width: brandingWidth,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: const _EduProBranding(
                    iconWidth: 78,
                    textSize: 54,
                    spacing: 8,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EduProBranding extends StatelessWidget {
  const _EduProBranding({
    required this.iconWidth,
    required this.textSize,
    required this.spacing,
  });

  final double iconWidth;
  final double textSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/images/edupro_logo.svg',
          width: iconWidth,
          height: iconWidth * (88 / 68),
        ),
        SizedBox(width: spacing),
        RichText(
          textScaler: const TextScaler.linear(1),
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Edu',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: textSize,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.4,
                ),
              ),
              TextSpan(
                text: 'Pro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: textSize,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

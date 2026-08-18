import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _backgroundColor = Color(0xFF3D8FEF);

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
                (constraints.maxWidth * 0.6).clamp(225.0, 300.0);

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

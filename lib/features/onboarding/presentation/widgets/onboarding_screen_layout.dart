import 'package:flutter/material.dart';

class OnboardingScreenLayout extends StatelessWidget {
  const OnboardingScreenLayout({
    super.key,
    required this.imageAssetPath,
    required this.title,
    required this.description,
    required this.activePageIndex,
    required this.primaryButtonLabel,
    required this.onPrimaryButtonPressed,
    required this.onSkipPressed,
  });

  static const primaryBlue = Color(0xFF3D8FEF);
  static const _descriptionColor = Color(0xFF8D8D8D);
  static const _skipColor = Color(0xFF9B9B9B);

  final String imageAssetPath;
  final String title;
  final String description;
  final int activePageIndex;
  final String primaryButtonLabel;
  final VoidCallback onPrimaryButtonPressed;
  final VoidCallback onSkipPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final horizontalPadding =
                (screenWidth * 0.075).clamp(24.0, 30.0).toDouble();
            final illustrationWidth =
                (screenWidth * 0.78).clamp(260.0, 320.0).toDouble();
            final titleSize = screenWidth < 360 ? 38.0 : 41.0;
            final topSpacing =
                (screenHeight * 0.035).clamp(18.0, 30.0).toDouble();
            final titleSpacing =
                (screenHeight * 0.042).clamp(26.0, 38.0).toDouble();
            final indicatorSpacing =
                (screenHeight * 0.038).clamp(22.0, 32.0).toDouble();
            final bottomSpacing =
                (screenHeight * 0.04).clamp(22.0, 34.0).toDouble();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onSkipPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: _skipColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: topSpacing),
                  Center(
                    child: SizedBox(
                      width: illustrationWidth,
                      child: Image.asset(
                        imageAssetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(height: titleSpacing),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _descriptionColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.28,
                      ),
                    ),
                  ),
                  SizedBox(height: indicatorSpacing),
                  _PageIndicators(activePageIndex: activePageIndex),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onPrimaryButtonPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(primaryButtonLabel),
                    ),
                  ),
                  SizedBox(height: bottomSpacing),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  const _PageIndicators({
    required this.activePageIndex,
  });

  final int activePageIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _IndicatorDot(isActive: activePageIndex == 0),
        const SizedBox(width: 8),
        _IndicatorDot(isActive: activePageIndex == 1),
      ],
    );
  }
}

class _IndicatorDot extends StatelessWidget {
  const _IndicatorDot({
    required this.isActive,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: isActive ? OnboardingScreenLayout.primaryBlue : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? OnboardingScreenLayout.primaryBlue : Colors.black,
          width: isActive ? 0 : 1,
        ),
      ),
    );
  }
}

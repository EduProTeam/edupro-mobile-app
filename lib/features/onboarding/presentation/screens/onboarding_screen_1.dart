import 'package:flutter/material.dart';

import '../widgets/onboarding_screen_layout.dart';
import 'onboarding_screen_2.dart';

class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenLayout(
      imageAssetPath: 'assets/images/onboarding/onboarding_1.jpg',
      title: 'Learn Skills\nYour Way',
      description:
          'Explore short lessons, recorded courses, and practical knowledge from skilled people in one learning community.',
      activePageIndex: 0,
      primaryButtonLabel: 'Next',
      onPrimaryButtonPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const OnboardingScreen2(),
          ),
        );
      },
      onSkipPressed: () {
        // TODO(Chenath): Route to the next auth-related screen when it exists.
      },
    );
  }
}

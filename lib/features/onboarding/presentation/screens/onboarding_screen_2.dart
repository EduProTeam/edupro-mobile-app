import 'package:flutter/material.dart';

import '../widgets/onboarding_screen_layout.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenLayout(
      imageAssetPath: 'assets/images/onboarding/onboarding_2.jpg',
      title: 'Share, Connect\n& Grow',
      description:
          'Share your skills, learn from peers, join educational communities, and grow together',
      activePageIndex: 1,
      primaryButtonLabel: 'Get started',
      onPrimaryButtonPressed: () {
        // TODO(Chenath): Route to the login or welcome screen when it exists.
      },
      onSkipPressed: () {
        // TODO(Chenath): Route to the next auth-related screen when it exists.
      },
    );
  }
}

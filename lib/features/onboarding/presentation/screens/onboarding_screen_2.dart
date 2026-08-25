import 'package:flutter/material.dart';

import '../../../auth/presentation/screens/register_screen.dart';
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
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
      },

      onSkipPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const RegisterScreen()));
      },
    );
  }
}

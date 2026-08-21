import 'package:flutter/material.dart';

import '../widgets/onboarding_screen_layout.dart';
import '../screens/chat_list_screen.dart';

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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      },
      onSkipPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
      },
    );
  }
}

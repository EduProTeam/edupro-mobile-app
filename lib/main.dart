import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/onboarding/presentation/screens/onboarding_screen_1.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF3D8FEF),
        useMaterial3: true,
      ),
      home: const OnboardingScreen1(),
    );
  }
}

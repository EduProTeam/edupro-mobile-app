import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/profile/models/profile_link.dart';
import 'features/profile/presentation/screens/shared_profile_screen.dart';
import 'features/posts/models/post_link.dart';
import 'features/posts/presentation/screens/shared_post_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      onGenerateRoute: buildAppRoute,
      // A cold app link must not leave a timed splash route underneath it.
      onGenerateInitialRoutes: (initialRoute) => [
        buildAppRoute(RouteSettings(name: initialRoute)),
      ],
    );
  }
}

Route<void> buildAppRoute(RouteSettings settings) {
  final userId = ProfileLink.userIdFromRoute(settings.name);
  final postId = PostLink.postIdFromRoute(settings.name);
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (context) {
      if (userId != null) return SharedProfileScreen(userId: userId);
      if (postId != null) return SharedPostScreen(postId: postId);
      if (settings.name == '/') return const SplashScreen();
      return Scaffold(
        appBar: AppBar(title: const Text('EduPro')),
        body: const Center(child: Text('This link is not available.')),
      );
    },
  );
}

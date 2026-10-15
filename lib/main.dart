import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';

import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/auth/presentation/widgets/firebase_ready_gate.dart';
import 'features/profile/models/profile_link.dart';
import 'features/profile/presentation/screens/shared_profile_screen.dart';
import 'features/posts/models/post_link.dart';
import 'features/posts/presentation/screens/shared_post_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = await AppThemeController.load();
  runApp(MyApp(themeController: themeController));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.themeController});

  final AppThemeController? themeController;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = widget.themeController ?? AppThemeController();
  }

  @override
  void didUpdateWidget(covariant MyApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeController != widget.themeController) {
      if (oldWidget.themeController == null) _themeController.dispose();
      _themeController = widget.themeController ?? AppThemeController();
    }
  }

  @override
  void dispose() {
    if (widget.themeController == null) _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      controller: _themeController,
      child: ListenableBuilder(
        listenable: _themeController,
        builder: (context, child) => MaterialApp(
          title: 'EduPro',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeController.mode,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.overlayFor(_themeController.isDark),
            child: child!,
          ),
          onGenerateRoute: buildAppRoute,
          // A cold app link must not leave a timed splash route underneath it.
          onGenerateInitialRoutes: (initialRoute) => [
            buildAppRoute(RouteSettings(name: initialRoute)),
          ],
        ),
      ),
    );
  }
}

Route<void> buildAppRoute(RouteSettings settings) {
  final userId = ProfileLink.userIdFromRoute(settings.name);
  final postId = PostLink.postIdFromRoute(settings.name);
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (context) {
      if (userId != null) {
        return FirebaseReadyGate(
          builder: (_) => SharedProfileScreen(userId: userId),
        );
      }
      if (postId != null) {
        return FirebaseReadyGate(
          builder: (_) => SharedPostScreen(postId: postId),
        );
      }
      if (settings.name == '/') return const SplashScreen();
      return Scaffold(
        appBar: AppBar(title: const Text('EduPro')),
        body: const Center(child: Text('This link is not available.')),
      );
    },
  );
}

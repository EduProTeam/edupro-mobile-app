import 'dart:async';

import 'package:edupro_mobile_app/core/theme/app_colors.dart';
import 'package:edupro_mobile_app/core/theme/app_theme.dart';
import 'package:edupro_mobile_app/core/theme/app_theme_controller.dart';
import 'package:edupro_mobile_app/features/courses/presentation/widgets/course_form_widgets.dart';
import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_card.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:edupro_mobile_app/features/profile/presentation/widgets/profile_dashboard.dart';
import 'package:edupro_mobile_app/features/skill_sharing/presentation/widgets/skill_ui.dart';
import 'package:edupro_mobile_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _post = PublishedPost(
  id: 'theme-post',
  userName: 'Author',
  title: 'A readable post',
  category: 'Flutter',
  content: 'Post content in the selected theme.',
  tags: ['Flutter'],
  attachmentType: 'none',
  attachmentUrl: null,
  attachmentName: null,
  linkUrl: null,
  likeCount: 0,
  commentCount: 0,
  createdAt: null,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'theme preference defaults to light and survives controller reloads',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = await AppThemeController.load();
      addTearDown(first.dispose);
      expect(first.mode, ThemeMode.light);
      expect(await first.toggle(), isTrue);
      final restored = await AppThemeController.load();
      addTearDown(restored.dispose);
      expect(restored.mode, ThemeMode.dark);
      expect(await restored.toggle(), isTrue);
      final lightAgain = await AppThemeController.load();
      addTearDown(lightAgain.dispose);
      expect(lightAgain.mode, ThemeMode.light);
    },
  );

  test(
    'rapid toggles save in order and a failed save does not block the next',
    () async {
      final firstWrite = Completer<bool>();
      final writes = <bool>[];
      final controller = AppThemeController(
        saveDarkMode: (value) {
          writes.add(value);
          return writes.length == 1 ? firstWrite.future : Future.value(true);
        },
      );
      addTearDown(controller.dispose);
      final dark = controller.toggle();
      final light = controller.toggle();
      expect(controller.mode, ThemeMode.light);
      await Future<void>.delayed(Duration.zero);
      expect(writes, [true]);
      firstWrite.complete(false);
      expect(await dark, isFalse);
      expect(await light, isTrue);
      expect(writes, [true, false]);
    },
  );

  test('a storage exception leaves the selected mode usable', () async {
    final controller = AppThemeController(
      saveDarkMode: (_) async => throw StateError('Unavailable'),
    );
    addTearDown(controller.dispose);
    expect(await controller.toggle(), isFalse);
    expect(controller.mode, ThemeMode.dark);
  });

  testWidgets(
    'profile toggle sits left of Settings and changes the current app route',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.defaultRouteNameTestValue = '/theme-test';
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
      final controller = AppThemeController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MyApp(themeController: controller));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      var settingsTaps = 0;
      navigator.push<void>(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            body: ProfileDashboard(
              name: 'Theme learner',
              title: 'Student',
              skills: const ['Flutter'],
              interests: const [],
              onSettings: () => settingsTaps++,
              onToggleTheme: () => AppThemeScope.maybeOf(context)!.toggle(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final darkToggle = find.byTooltip('Switch to dark mode');
      expect(
        tester.getCenter(darkToggle).dx,
        lessThan(tester.getCenter(find.byTooltip('Settings')).dx),
      );
      await tester.tap(darkToggle);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Switch to light mode'), findsOneWidget);
      expect(
        Theme.of(tester.element(find.text('Theme learner'))).brightness,
        Brightness.dark,
      );
      expect(navigator.canPop(), isTrue);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      await tester.tap(find.byTooltip('Settings'));
      expect(settingsTaps, 1);
      await tester.tap(find.byTooltip('Switch to light mode'));
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.text('Theme learner'))).brightness,
        Brightness.light,
      );
      expect(find.text('Theme learner'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dark course, skill and post surfaces retain the app theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: SkillPage(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const CourseFormCard(child: Text('Course fields')),
                const SkillCard(child: Text('Skill details')),
                const PostCard(post: _post, readOnly: true),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['Course fields', 'Skill details', 'A readable post']) {
      final context = tester.element(find.text(label));
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(context.appColors.surface, AppPalette.dark.surface);
      expect(
        DefaultTextStyle.of(context).style.color,
        AppPalette.dark.textPrimary,
      );
    }
    expect(
      tester.widget<Text>(find.text('A readable post')).style!.color,
      AppPalette.dark.textPrimary,
    );
    expect(tester.takeException(), isNull);
  });
}

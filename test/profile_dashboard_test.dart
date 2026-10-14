import 'package:edupro_mobile_app/features/profile/presentation/widgets/profile_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget dashboard({
    List<String> skills = const ['Flutter', 'UI/UX Design', 'Dart'],
    List<String> interests = const [
      'Mobile App Development',
      'Web Development',
    ],
    String name = 'Chenath Perera',
    String email = 'bebe@gmail.com',
    double textScale = 1,
    void Function(String)? onAction,
  }) => MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: ProfileDashboard(
          name: name,
          title: 'Student',
          organization: 'SLIIT',
          email: email,
          bio:
              'Passionate about learning and building creative solutions through technology.',
          skills: skills,
          interests: interests,
          onSettings: () => onAction?.call('settings'),
          onPhoto: () => onAction?.call('photo'),
          onEdit: () => onAction?.call('edit'),
          onShare: () => onAction?.call('share'),
          onAddSkill: () => onAction?.call('skill'),
          onAddInterest: () => onAction?.call('interest'),
        ),
      ),
    ),
  );

  testWidgets('profile actions remain usable after scrolling', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final actions = <String>[];
    await tester.pumpWidget(dashboard(onAction: actions.add));
    await tester.pumpAndSettle();

    expect(find.text('Chenath Perera'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.tap(find.byTooltip('Change profile photo'));
    for (final label in [
      'Edit Profile',
      'Share Profile',
      'Add Skill',
      'Add Interest',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(actions, [
      'settings',
      'photo',
      'edit',
      'share',
      'skill',
      'interest',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screens wrap long details and support large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      dashboard(
        name: 'A learner with a longer profile name',
        email: 'a.long.email.address.for.the.profile@example.edu',
        skills: const [
          'An unusually long skill description that needs to wrap',
        ],
        interests: const ['Artificial Intelligence and Machine Learning'],
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.text('Artificial Intelligence and Machine Learning'),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty profiles show prompts without sample skills', (
    tester,
  ) async {
    await tester.pumpWidget(dashboard(skills: const [], interests: const []));
    await tester.pumpAndSettle();
    expect(find.text('No skills added yet'), findsOneWidget);
    expect(find.text('No learning interests selected yet'), findsOneWidget);
    expect(find.text('Flutter'), findsNothing);
    expect(find.text('0'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}

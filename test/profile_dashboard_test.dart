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
    int postCount = 0,
    int courseCount = 0,
    bool readOnly = false,
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
          postCount: postCount,
          courseCount: courseCount,
          readOnly: readOnly,
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
    await tester.pumpWidget(
      dashboard(postCount: 7, courseCount: 2, onAction: actions.add),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chenath Perera'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
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

  testWidgets(
    'read-only profiles show details and stats without editor actions',
    (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final actions = <String>[];
      await tester.pumpWidget(
        dashboard(
          readOnly: true,
          postCount: 7,
          courseCount: 2,
          onAction: actions.add,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chenath Perera'), findsOneWidget);
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('SLIIT'), findsOneWidget);
      expect(find.text('bebe@gmail.com'), findsOneWidget);
      expect(
        find.text(
          'Passionate about learning and building creative solutions through technology.',
        ),
        findsOneWidget,
      );
      expect(find.text('Posts'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Courses'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Skills'), findsNWidgets(2));
      expect(find.text('My Skills'), findsNothing);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('UI/UX Design'), findsOneWidget);
      await tester.ensureVisible(find.text('Web Development'));
      await tester.pumpAndSettle();
      expect(find.text('Learning Interests'), findsOneWidget);
      expect(find.text('Web Development'), findsOneWidget);

      expect(find.byTooltip('Settings'), findsNothing);
      expect(find.byTooltip('Change profile photo'), findsNothing);
      for (final label in [
        'Edit Profile',
        'Share Profile',
        'Add Skill',
        'Add Interest',
      ]) {
        expect(find.text(label), findsNothing);
      }
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
      expect(find.byType(TextButton), findsNothing);
      expect(actions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'read-only profiles accept no owner callbacks and use a neutral bio',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProfileDashboard(
              name: 'A learner',
              title: 'Student',
              skills: [],
              interests: [],
              bio: '   ',
              readOnly: true,
              postLibrary: Text('Published posts'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No bio added yet.'), findsOneWidget);
      expect(
        find.text('Add a bio to tell the community about yourself.'),
        findsNothing,
      );
      expect(find.text('No skills added yet'), findsOneWidget);
      expect(find.text('No learning interests selected yet'), findsOneWidget);
      await tester.ensureVisible(find.text('Published posts'));
      expect(find.text('Published posts'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

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

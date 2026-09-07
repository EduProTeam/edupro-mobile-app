import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edupro_mobile_app/features/courses/models/course_draft.dart';
import 'package:edupro_mobile_app/features/courses/services/course_service.dart';
import 'package:edupro_mobile_app/features/courses/presentation/screens/create_course_screen.dart';
import 'package:edupro_mobile_app/features/courses/presentation/widgets/lesson_editor.dart';

class MemoryCourseService extends CourseService {
  int next = 0;
  CourseDraft? saved;
  @override
  String newId() => 'test-${next++}';
  @override
  String get userId => 'owner';
  @override
  Future<void> save(CourseDraft course, {required bool isNew}) async {
    saved = course;
  }
}

void main() {
  test('paid prices must be finite and positive', () {
    for (final value in ['', 'abc', '0', '-1', 'NaN', 'Infinity']) {
      expect(validateCoursePrice(value), isNotNull);
    }
    expect(validateCoursePrice('1200.50'), isNull);
  });
  test('course round trip preserves direct lessons and remote files', () {
    const media = CourseMedia(
      name: 'intro.mp4',
      path: 'owner/course_x_intro.mp4',
      url: 'https://example.com/video',
    );
    final course = CourseDraft(
      id: 'one',
      title: 'Title',
      category: 'Design',
      description: 'Description',
      language: 'English',
      type: CourseType.free,
      currency: 'USD',
      price: 55,
      status: CourseStatus.draft,
      userId: 'owner',
      lessons: [
        CourseLesson(
          id: 'lesson',
          title: 'Intro',
          video: media,
          materials: [media],
        ),
      ],
    );
    final restored = CourseDraft.fromMap(course.id, course.toMap());
    expect(restored.price, 0);
    expect(restored.lessons.single.video!.path, media.path);
    expect(restored.lessons.single.materials.single.name, media.name);
    expect(course.toMap().containsKey('modules'), isFalse);
    expect(() => restored.lessons.clear(), throwsUnsupportedError);
  });
  testWidgets('mobile lesson add, edit, remove and numbering', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: CreateCourseScreen(service: MemoryCourseService())),
    );
    await tester.scrollUntilVisible(
      find.text('Add Another Lesson'),
      400,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('course-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Lesson 01'), findsOneWidget);
    expect(find.text('Remove Lesson'), findsNothing);
    await tester.tap(find.text('Add Another Lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Create Lesson'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(2), 'Second lesson');
    await tester.tap(find.text('Save Lesson'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Second lesson'),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('course-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Second lesson'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Remove Lesson').first,
      -200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('course-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Remove Lesson').first);
    await tester.pumpAndSettle();
    expect(find.text('Lesson 02'), findsNothing);
    expect(find.text('Remove Lesson'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('incomplete draft saves but incomplete publish is blocked', (
    tester,
  ) async {
    final service = MemoryCourseService();
    await tester.pumpWidget(
      MaterialApp(home: CreateCourseScreen(service: service)),
    );
    await tester.tap(find.text('Publish Course'));
    await tester.pumpAndSettle();
    expect(find.byType(InlineLessonEditor), findsOneWidget);
    expect(service.saved, isNull);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save as Draft'));
    await tester.pumpAndSettle();
    expect(service.saved?.status, CourseStatus.draft);
    expect(service.saved?.lessons.length, 1);
  });
  testWidgets('price fields only appear for Paid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CreateCourseScreen(service: MemoryCourseService())),
    );
    await tester.scrollUntilVisible(
      find.text('Paid'),
      300,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('course-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Currency'), findsNothing);
    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('0.00'),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('course-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('0.00'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Free'),
      -200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('course-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Free'));
    await tester.pumpAndSettle();
    expect(find.text('0.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

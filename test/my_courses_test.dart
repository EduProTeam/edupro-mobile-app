import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edupro_mobile_app/features/courses/models/course_draft.dart';
import 'package:edupro_mobile_app/features/courses/services/course_service.dart';
import 'package:edupro_mobile_app/features/courses/presentation/screens/recorded_courses_screen.dart';
import 'package:edupro_mobile_app/features/courses/presentation/screens/create_course_screen.dart';
import 'package:edupro_mobile_app/features/courses/presentation/widgets/my_courses_tab.dart';

CourseDraft course(String id, String owner, CourseStatus status) => CourseDraft(
  id: id,
  title: id,
  category: 'Design',
  description: 'Description',
  language: 'English',
  type: CourseType.free,
  currency: 'USD',
  price: 0,
  status: status,
  userId: owner,
  lessons: [CourseLesson(id: 'lesson', title: 'Intro')],
);

class CoursesService extends CourseService {
  final changes = StreamController<List<CourseDraft>>.broadcast();
  final courses = [
    course('My draft', 'owner', CourseStatus.draft),
    course('My published', 'owner', CourseStatus.published),
  ];
  int deletions = 0;
  bool failDelete = false;
  bool? lastSaveWasNew;
  @override
  Future<void> save(CourseDraft course, {required bool isNew}) async {
    lastSaveWasNew = isNew;
    final index = courses.indexWhere((item) => item.id == course.id);
    if (index < 0) {
      courses.add(course);
    } else {
      courses[index] = course;
    }
    changes.add(List.of(courses));
  }

  @override
  String get userId => 'owner';
  @override
  Stream<Set<String>> watchEnrolledCourseIds() => Stream.value(<String>{});
  @override
  Stream<List<CourseDraft>> watchCourses({required bool owned}) async* {
    if (owned) {
      yield List.of(courses);
      yield* changes.stream;
    } else {
      yield [course('Other course', 'other', CourseStatus.published)];
    }
  }

  @override
  Future<void> delete(CourseDraft course) async {
    if (failDelete) throw const CourseFailure('Delete failed. Please retry.');
    deletions++;
    courses.removeWhere((item) => item.id == course.id);
    changes.add(List.of(courses));
  }
}

void main() {
  testWidgets(
    'My Courses lists owned drafts and published courses and opens editor',
    (tester) async {
      final service = CoursesService();
      addTearDown(service.changes.close);
      await tester.pumpWidget(
        MaterialApp(
          home: RecordedCoursesScreen(
            service: service,
            onCreateCoursePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Courses'));
      await tester.pumpAndSettle();
      expect(find.text('My draft'), findsOneWidget);
      expect(find.text('My published'), findsOneWidget);
      expect(find.text('Other course'), findsNothing);
      await tester.tap(find.text('Edit').first);
      await tester.pumpAndSettle();
      expect(find.byType(CreateCourseScreen), findsOneWidget);
      expect(find.text('Edit Course'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'My draft'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'My draft'),
        'Updated course',
      );
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(service.lastSaveWasNew, isFalse);
      expect(service.courses.length, 2);
      expect(service.courses.first.id, 'My draft');
      expect(service.courses.first.lessons.single.title, 'Intro');
      expect(find.text('Updated course'), findsOneWidget);
    },
  );

  testWidgets(
    'delete requires confirmation, reports failure and updates list after retry',
    (tester) async {
      final service = CoursesService();
      addTearDown(service.changes.close);
      await tester.pumpWidget(
        MaterialApp(
          home: RecordedCoursesScreen(
            service: service,
            onCreateCoursePressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Courses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(service.deletions, 0);
      service.failDelete = true;
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Delete failed. Please retry.'), findsOneWidget);
      expect(find.text('My draft'), findsOneWidget);
      service.failDelete = false;
      await tester.tap(find.text('Delete').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Delete'),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.deletions, 1);
      expect(find.text('My draft'), findsNothing);
      expect(find.text('My published'), findsOneWidget);
      expect(find.text('1 course'), findsOneWidget);
    },
  );

  testWidgets('status search, sorting, counts and empty create action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = CoursesService();
    addTearDown(service.changes.close);
    var created = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RecordedCoursesScreen(
          service: service,
          onCreateCoursePressed: () => created = true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('My Courses'));
    await tester.pumpAndSettle();
    expect(find.text('2 courses'), findsOneWidget);
    await tester.tap(find.byTooltip('Sort courses'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Published first'));
    await tester.tap(find.text('Published first'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('My published')).dy,
      lessThan(tester.getTopLeft(find.text('My draft')).dy),
    );
    await tester.enterText(find.byType(TextField), 'published');
    await tester.pumpAndSettle();
    expect(find.text('1 course'), findsOneWidget);
    expect(find.text('My draft'), findsNothing);
    await tester.enterText(find.byType(TextField), 'no results');
    await tester.pumpAndSettle();
    expect(find.text('0 courses'), findsOneWidget);
    expect(find.text('No matching courses'), findsOneWidget);
    await tester.tap(find.text('Clear Search'));
    await tester.pumpAndSettle();
    service.courses.clear();
    service.changes.add([]);
    await tester.pumpAndSettle();
    expect(find.text('No courses created yet'), findsOneWidget);
    await tester.tap(find.text('Create Course'));
    expect(created, isTrue);
  });

  testWidgets('management card fits narrow screens and separates taps', (
    tester,
  ) async {
    var opens = 0, edits = 0, deletes = 0;
    for (final width in [320.0, 390.0, 600.0]) {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: MyCourseCard(
                course: course(
                  'A very long course title that must fit on two lines without overflow',
                  'owner',
                  CourseStatus.published,
                ),
                deleting: false,
                onOpen: () => opens++,
                onEdit: () => edits++,
                onDelete: () => deletes++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const ValueKey('course-thumbnail-placeholder')),
        findsOneWidget,
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('course-thumbnail-placeholder')),
        ),
        const Size(88, 88),
      );
      expect(find.text('1 lesson'), findsOneWidget);
      final editLeft = tester.getTopLeft(find.text('Edit')).dx;
      final deleteRight = tester.getTopRight(find.text('Delete')).dx;
      expect(editLeft, greaterThan(80));
      expect(deleteRight, lessThanOrEqualTo(width - 16));
      await tester.tap(find.text('Edit'));
      await tester.tap(find.text('Delete'));
      expect(opens, 0);
    }
    expect(edits, 3);
    expect(deletes, 3);
    await tester.tap(find.text('Published'));
    expect(opens, 1);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

import 'package:edupro_mobile_app/features/courses/models/course_draft.dart';
import 'package:edupro_mobile_app/features/courses/services/course_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Course models', () {
    test('COURSE001 media serializes every stored file field', () {
      // Arrange
      const media = CourseMedia(
        name: 'notes.pdf',
        path: 'owner/notes.pdf',
        url: 'https://example.invalid/notes.pdf',
      );

      // Act
      final data = media.toMap();

      // Assert
      expect(data, {
        'name': 'notes.pdf',
        'path': 'owner/notes.pdf',
        'url': 'https://example.invalid/notes.pdf',
      });
    });

    test('COURSE002 missing and null media fields deserialize as empty', () {
      // Arrange
      final data = <String, dynamic>{'name': null, 'url': null};

      // Act
      final media = CourseMedia.fromMap(data);

      // Assert
      expect(media.name, isEmpty);
      expect(media.path, isEmpty);
      expect(media.url, isEmpty);
    });

    test(
      'COURSE003 lesson without video preserves null and empty defaults',
      () {
        // Arrange
        final data = <String, dynamic>{
          'id': 'lesson-1',
          'title': 'Introduction',
        };

        // Act
        final lesson = CourseLesson.fromMap(data);

        // Assert
        expect(lesson.id, 'lesson-1');
        expect(lesson.title, 'Introduction');
        expect(lesson.description, isEmpty);
        expect(lesson.duration, isEmpty);
        expect(lesson.video, isNull);
        expect(lesson.materials, isEmpty);
        expect(lesson.toMap()['video'], isNull);
      },
    );

    test(
      'COURSE004 lesson round trip preserves descriptions and file details',
      () {
        // Arrange
        final lesson = CourseLesson(
          id: 'lesson-1',
          title: 'Introduction',
          description: 'Getting started',
          duration: '12:30',
          video: const CourseMedia(
            name: 'intro.mp4',
            path: 'video',
            url: 'video-url',
          ),
          materials: const [
            CourseMedia(name: 'notes.pdf', path: 'notes', url: 'notes-url'),
          ],
        );

        // Act
        final restored = CourseLesson.fromMap(lesson.toMap());

        // Assert
        expect(restored.toMap(), lesson.toMap());
        expect(restored.description, 'Getting started');
        expect(restored.duration, '12:30');
        expect(restored.video!.url, 'video-url');
        expect(restored.materials.single.path, 'notes');
      },
    );

    test('COURSE005 lesson defensively copies and locks its materials', () {
      // Arrange
      final materials = <CourseMedia>[];
      final lesson = CourseLesson(
        id: 'lesson',
        title: 'Title',
        materials: materials,
      );

      // Act
      materials.add(
        const CourseMedia(name: 'later', path: 'later', url: 'later'),
      );

      // Assert
      expect(lesson.materials, isEmpty);
      expect(() => lesson.materials.clear(), throwsUnsupportedError);
    });

    test('COURSE006 empty course data uses documented safe defaults', () {
      // Arrange
      final data = <String, dynamic>{};

      // Act
      final course = CourseDraft.fromMap('stored-id', data);

      // Assert
      expect(course.id, 'stored-id');
      expect(course.title, isEmpty);
      expect(course.category, isEmpty);
      expect(course.description, isEmpty);
      expect(course.language, isEmpty);
      expect(course.userId, isEmpty);
      expect(course.currency, 'USD');
      expect(course.level, 'Beginner');
      expect(course.type, CourseType.free);
      expect(course.status, CourseStatus.draft);
      expect(course.price, 0);
      expect(course.rating, 0);
      expect(course.enrollmentCount, 0);
      expect(course.thumbnail, isNull);
      expect(course.lessons, isEmpty);
    });

    test(
      'COURSE007 numeric strings and timestamps preserve paid course metadata',
      () {
        // Arrange
        final data = <String, dynamic>{
          'type': 'paid',
          'status': 'published',
          'price': '1250.50',
          'rating': '4.5',
          'enrollmentCount': 7.9,
          'instructorName': 'Test Instructor',
          'level': 'Advanced',
          'totalDuration': '2h',
        };

        // Act
        final course = CourseDraft.fromMap(
          'course',
          data,
          updatedAt: 200,
          createdAt: 100,
        );

        // Assert
        expect(course.type, CourseType.paid);
        expect(course.status, CourseStatus.published);
        expect(course.price, 1250.5);
        expect(course.rating, 4.5);
        expect(course.enrollmentCount, 7);
        expect(course.instructorName, 'Test Instructor');
        expect(course.level, 'Advanced');
        expect(course.totalDuration, '2h');
        expect(course.updatedAt, 200);
        expect(course.createdAt, 100);
        expect(course.toMap()['price'], 1250.5);
      },
    );

    test('COURSE008 unknown enums and invalid numeric text use fallbacks', () {
      // Arrange
      final data = <String, dynamic>{
        'type': 'unknown',
        'status': 'unknown',
        'price': 'bad',
        'rating': 'bad',
      };

      // Act
      final course = CourseDraft.fromMap('course', data);

      // Assert
      expect(course.type, CourseType.free);
      expect(course.status, CourseStatus.draft);
      expect(course.price, 0);
      expect(course.rating, 0);
    });

    test('COURSE009 course writes omit database-managed fields', () {
      // Arrange
      final course = CourseDraft.fromMap(
        'course',
        {'enrollmentCount': 42},
        createdAt: 100,
        updatedAt: 200,
      );

      // Act
      final data = course.toMap();

      // Assert
      expect(data['schemaVersion'], 2);
      expect(data.containsKey('id'), isFalse);
      expect(data.containsKey('enrollmentCount'), isFalse);
      expect(data.containsKey('createdAt'), isFalse);
      expect(data.containsKey('updatedAt'), isFalse);
    });

    test(
      'COURSE010 enrollment ignores non-string IDs and removes duplicates',
      () {
        // Arrange
        final data = <String, dynamic>{
          'completedLessonIds': ['one', null, 2, 'one', 'two'],
        };

        // Act
        final enrollment = CourseEnrollment.fromMap('course', data);

        // Assert
        expect(enrollment.courseId, 'course');
        expect(enrollment.completedLessonIds, {'one', 'two'});
        expect(
          () => enrollment.completedLessonIds.add('three'),
          throwsUnsupportedError,
        );
      },
    );

    test('COURSE011 missing and null lesson completion lists are empty', () {
      // Arrange
      final maps = [
        <String, dynamic>{},
        <String, dynamic>{'completedLessonIds': null},
      ];

      // Act
      final enrollments = maps.map(
        (data) => CourseEnrollment.fromMap('course', data),
      );

      // Assert
      expect(
        enrollments.every((item) => item.completedLessonIds.isEmpty),
        isTrue,
      );
    });

    test(
      'COURSE012 lesson labels pad single digits without truncating large numbers',
      () {
        // Arrange
        const indices = [0, 8, 9, 99];

        // Act
        final labels = indices.map(lessonLabel).toList();

        // Assert
        expect(labels, ['Lesson 01', 'Lesson 09', 'Lesson 10', 'Lesson 100']);
      },
    );

    test(
      'COURSE013 price accepts whitespace, fractions and the smallest positive value',
      () {
        // Arrange
        const values = [' 0.01 ', '1e-300', '999999999.99'];

        // Act
        final errors = values.map(validateCoursePrice).toList();

        // Assert
        expect(errors, everyElement(isNull));
      },
    );

    test('COURSE014 whitespace and negative infinity prices are rejected', () {
      // Arrange
      const values = ['   ', '-Infinity', '-0.0', '1e9999'];

      // Act
      final errors = values.map(validateCoursePrice).toList();

      // Assert
      expect(errors, everyElement('Enter a price greater than zero.'));
    });
  });

  group('Learning progress', () {
    for (final scenario in [
      (
        id: 'COURSE015',
        name: 'empty courses report zero progress',
        completed: 0,
        total: 0,
        expected: 0.0,
      ),
      (
        id: 'COURSE016',
        name: 'partial completion calculates the fraction',
        completed: 1,
        total: 4,
        expected: 0.25,
      ),
      (
        id: 'COURSE017',
        name: 'all lessons complete reports one',
        completed: 3,
        total: 3,
        expected: 1.0,
      ),
      (
        id: 'COURSE018',
        name: 'excess stored completions clamp to full progress',
        completed: 5,
        total: 3,
        expected: 1.0,
      ),
      (
        id: 'COURSE019',
        name: 'negative completion counts clamp to zero',
        completed: -1,
        total: 3,
        expected: 0.0,
      ),
      (
        id: 'COURSE020',
        name: 'stale completions on empty courses report zero',
        completed: 3,
        total: 0,
        expected: 0.0,
      ),
    ]) {
      test('${scenario.id} ${scenario.name}', () {
        // Arrange
        final completed = scenario.completed;
        final total = scenario.total;

        // Act
        final progress = calculateLearningProgress(
          completedLessons: completed,
          totalLessons: total,
        );

        // Assert
        expect(progress, scenario.expected);
      });
    }
  });
}

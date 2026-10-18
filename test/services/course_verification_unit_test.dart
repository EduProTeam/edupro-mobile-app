import 'package:edupro_mobile_app/features/courses/services/course_verification_service.dart';
import 'package:flutter_test/flutter_test.dart';

Matcher verificationFailure(String message) => isA<CourseVerificationFailure>()
    .having((error) => error.message, 'message', message);

void main() {
  late CourseVerificationService service;

  setUp(() {
    service = CourseVerificationService();
  });

  group('Course verification topic selection', () {
    for (final scenario in [
      (
        id: 'COURSE021',
        title: 'JAVASCRIPT essentials',
        category: 'Development',
        topic: 'JavaScript',
      ),
      (
        id: 'COURSE022',
        title: 'User interface basics',
        category: 'Design & UI/UX',
        topic: 'UI Design',
      ),
      (
        id: 'COURSE023',
        title: 'Search engine optimization',
        category: 'Marketing',
        topic: 'SEO',
      ),
      (
        id: 'COURSE024',
        title: 'Project management basics',
        category: 'Business',
        topic: 'Project Management',
      ),
      (
        id: 'COURSE025',
        title: 'Public speaking skills',
        category: 'Other',
        topic: 'Public Speaking',
      ),
    ]) {
      test(
        '${scenario.id} generates five questions for ${scenario.topic}',
        () async {
          // Arrange
          const courseId = 'test-course';

          // Act
          final quiz = await service.generate(
            title: scenario.title,
            category: scenario.category,
            courseId: courseId,
          );

          // Assert
          expect(quiz.topic, scenario.topic);
          expect(quiz.id, endsWith('-$courseId'));
          expect(quiz.questions, hasLength(5));
          for (final question in quiz.questions) {
            expect(question.question, isNotEmpty);
            expect(question.options, hasLength(4));
            expect(question.options, everyElement(isNotEmpty));
          }
        },
      );
    }

    test(
      'COURSE026 a topic in another category is rejected with supported topics',
      () async {
        // Arrange
        const title = 'Python foundations';

        // Act
        final operation = service.generate(
          title: title,
          category: 'Marketing',
          courseId: 'course',
        );

        // Assert
        await expectLater(
          operation,
          throwsA(
            isA<CourseVerificationFailure>().having(
              (error) => error.message,
              'message',
              allOf(
                contains('supported Marketing topic'),
                contains('SEO'),
                contains('Copywriting'),
              ),
            ),
          ),
        );
      },
    );

    test(
      'COURSE027 empty titles fail without generating a usable quiz',
      () async {
        // Arrange
        const title = '';

        // Act
        final operation = service.generate(
          title: title,
          category: 'Development',
          courseId: 'course',
        );

        // Assert
        await expectLater(
          operation,
          throwsA(
            isA<CourseVerificationFailure>().having(
              (error) => error.message,
              'message',
              contains('Supported topics: JavaScript, C#, Python'),
            ),
          ),
        );
      },
    );

    test('COURSE028 unknown categories report an unavailable topic', () async {
      // Arrange
      const category = 'Unimplemented category';

      // Act
      final operation = service.generate(
        title: 'Flutter',
        category: category,
        courseId: 'course',
      );

      // Assert
      await expectLater(
        operation,
        throwsA(
          verificationFailure(
            'Add a supported $category topic to the course title. Supported topics: .',
          ),
        ),
      );
    });

    test(
      'COURSE029 development aliases choose C sharp rather than an unrelated quiz',
      () async {
        // Arrange
        const title = 'C sharp for beginners';

        // Act
        final quiz = await service.generate(
          title: title,
          category: 'Development',
          courseId: 'course',
        );

        // Assert
        expect(quiz.topic, 'C#');
        expect(quiz.questions.first.question, contains('C#'));
      },
    );
  });

  group('Course verification scoring', () {
    // The predefined Python bank uses option 0 for each correct answer.
    // These fixtures exercise the public scoring contract without exposing or
    // mutating the service's private answer-key storage.
    for (final scenario in [
      (
        id: 'COURSE030',
        name: 'all correct answers pass',
        answers: [0, 0, 0, 0, 0],
        score: 5,
        passed: true,
      ),
      (
        id: 'COURSE031',
        name: 'four correct answers meet the passing boundary',
        answers: [0, 0, 0, 0, 1],
        score: 4,
        passed: true,
      ),
      (
        id: 'COURSE032',
        name: 'three correct answers fail below the boundary',
        answers: [0, 0, 0, 1, 1],
        score: 3,
        passed: false,
      ),
      (
        id: 'COURSE033',
        name: 'all incorrect answers score zero',
        answers: [1, 1, 1, 1, 1],
        score: 0,
        passed: false,
      ),
      (
        id: 'COURSE034',
        name: 'out-of-range choices count as incorrect',
        answers: [-1, 4, 99, -5, 4],
        score: 0,
        passed: false,
      ),
    ]) {
      test('${scenario.id} ${scenario.name}', () async {
        // Arrange
        final quiz = await service.generate(
          title: 'Python basics',
          category: 'Development',
          courseId: 'course',
        );

        // Act
        final result = await service.submit(
          quizId: quiz.id,
          answers: scenario.answers,
        );

        // Assert
        expect(result.score, scenario.score);
        expect(result.passed, scenario.passed);
      });
    }

    test(
      'COURSE035 submitting an unknown quiz returns the regeneration error',
      () async {
        // Arrange
        const quizId = 'missing-quiz';

        // Act
        final operation = service.submit(
          quizId: quizId,
          answers: [0, 0, 0, 0, 0],
        );

        // Assert
        await expectLater(
          operation,
          throwsA(
            verificationFailure(
              'This quiz is no longer available. Please generate a new quiz.',
            ),
          ),
        );
      },
    );

    test('COURSE036 completed quizzes cannot be submitted twice', () async {
      // Arrange
      final quiz = await service.generate(
        title: 'Python basics',
        category: 'Development',
        courseId: 'course',
      );
      await service.submit(quizId: quiz.id, answers: [0, 0, 0, 0, 0]);

      // Act
      final operation = service.submit(
        quizId: quiz.id,
        answers: [0, 0, 0, 0, 0],
      );

      // Assert
      await expectLater(operation, throwsA(isA<CourseVerificationFailure>()));
    });

    for (final scenario in [
      (
        id: 'COURSE037',
        name: 'too few answers consume the quiz and require regeneration',
        answers: <int>[],
      ),
      (
        id: 'COURSE038',
        name: 'too many answers consume the quiz and require regeneration',
        answers: [0, 0, 0, 0, 0, 0],
      ),
    ]) {
      test('${scenario.id} ${scenario.name}', () async {
        // Arrange
        final quiz = await service.generate(
          title: 'Python',
          category: 'Development',
          courseId: 'course',
        );

        // Act
        final operation = service.submit(
          quizId: quiz.id,
          answers: scenario.answers,
        );

        // Assert
        await expectLater(operation, throwsA(isA<CourseVerificationFailure>()));
        await expectLater(
          service.submit(quizId: quiz.id, answers: [0, 0, 0, 0, 0]),
          throwsA(isA<CourseVerificationFailure>()),
        );
      });
    }

    test(
      'COURSE039 quiz keys are isolated between service instances',
      () async {
        // Arrange
        final quiz = await service.generate(
          title: 'Python',
          category: 'Development',
          courseId: 'course',
        );
        final otherService = CourseVerificationService();

        // Act
        final operation = otherService.submit(
          quizId: quiz.id,
          answers: [0, 0, 0, 0, 0],
        );

        // Assert
        await expectLater(operation, throwsA(isA<CourseVerificationFailure>()));
        expect(
          (await service.submit(
            quizId: quiz.id,
            answers: [0, 0, 0, 0, 0],
          )).score,
          5,
        );
      },
    );

    test(
      'COURSE040 separate generated quizzes retain independent answer keys',
      () async {
        // Arrange
        final first = await service.generate(
          title: 'Python',
          category: 'Development',
          courseId: 'first',
        );
        final second = await service.generate(
          title: 'Figma',
          category: 'Design & UI/UX',
          courseId: 'second',
        );

        // Act
        final firstResult = await service.submit(
          quizId: first.id,
          answers: [0, 0, 0, 0, 0],
        );
        final secondResult = await service.submit(
          quizId: second.id,
          answers: [1, 1, 1, 1, 1],
        );

        // Assert
        expect(first.id, isNot(second.id));
        expect(firstResult.score, 5);
        expect(secondResult.score, 0);
      },
    );
  });
}

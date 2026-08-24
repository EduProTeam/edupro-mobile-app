import 'package:flutter/material.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';

class ViewCourseScreen extends StatelessWidget {
  const ViewCourseScreen({
    super.key,
    required this.course,
  });

  final CourseDraft course;

  @override
  Widget build(BuildContext context) {
    final lessonCount = course.modules.fold<int>(
      0,
      (count, module) => count + module.lessons.length,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: const Text('View Course'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE3E6ED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 26,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.ondemand_video_outlined,
                        size: 42,
                        color: OnboardingScreenLayout.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        course.thumbnailPath.isEmpty &&
                                course.promoVideoPath.isEmpty
                            ? 'No thumbnail or promo video added'
                            : 'Thumbnail / Promo media added',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: OnboardingScreenLayout.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Thumbnail: ${course.thumbnailPath.isEmpty ? 'Not added' : course.thumbnailPath}\nPromo Video: ${course.promoVideoPath.isEmpty ? 'Not added' : course.promoVideoPath}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _StatusChip(status: course.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  course.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: OnboardingScreenLayout.primaryBlue,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  course.description.isEmpty
                      ? 'No course description added yet.'
                      : course.description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _DetailCard(
                      label: 'Price',
                      value: '${course.currency} ${course.price}',
                    ),
                    _DetailCard(
                      label: 'Modules',
                      value: '${course.modules.length}',
                    ),
                    _DetailCard(
                      label: 'Lessons',
                      value: '$lessonCount',
                    ),
                    _DetailCard(
                      label: 'Discount',
                      value: course.applyDiscount
                          ? (course.couponCode.isEmpty
                              ? 'Enabled'
                              : course.couponCode)
                          : 'Off',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Curriculum',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (var moduleIndex = 0;
              moduleIndex < course.modules.length;
              moduleIndex++) ...[
            _ModuleViewCard(
              moduleNumber: moduleIndex + 1,
              module: course.modules[moduleIndex],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ModuleViewCard extends StatelessWidget {
  const _ModuleViewCard({
    required this.moduleNumber,
    required this.module,
  });

  final int moduleNumber;
  final CourseModule module;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E6ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Module $moduleNumber',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            module.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: OnboardingScreenLayout.primaryBlue,
            ),
          ),
          const SizedBox(height: 14),
          for (var lessonIndex = 0;
              lessonIndex < module.lessons.length;
              lessonIndex++) ...[
            _LessonTile(
              lessonNumber: lessonIndex + 1,
              lesson: module.lessons[lessonIndex],
            ),
            if (lessonIndex != module.lessons.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lessonNumber,
    required this.lesson,
  });

  final int lessonNumber;
  final CourseLesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E6EE)),
      ),
      child: Row(
        children: [
          Text(
            '${lessonNumber.toString().padLeft(2, '0')}.',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.play_lesson_outlined),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson.duration,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                if (lesson.videoPath.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lesson.videoPath,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final CourseStatus status;

  @override
  Widget build(BuildContext context) {
    final isPublished = status == CourseStatus.published;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isPublished
            ? const Color(0xFFE8F8EE)
            : const Color(0xFFF4F5F8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPublished ? 'Published' : 'Draft',
        style: TextStyle(
          color: isPublished ? const Color(0xFF1B8A43) : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';

class RecordedCoursesScreen extends StatelessWidget {
  const RecordedCoursesScreen({
    super.key,
    required this.courses,
    required this.onCreateCoursePressed,
  });

  final List<CourseDraft> courses;
  final VoidCallback onCreateCoursePressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorded Courses'),
        actions: [
          IconButton(
            onPressed: onCreateCoursePressed,
            icon: const Icon(Icons.add),
            tooltip: 'Create course',
          ),
        ],
      ),
      body: courses.isEmpty
          ? _EmptyRecordedCourses(
              onCreateCoursePressed: onCreateCoursePressed,
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = courses[index];
                final lessonCount = course.modules.fold<int>(
                  0,
                  (count, module) => count + module.lessons.length,
                );

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE3E6ED)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.play_circle_outline,
                              color: OnboardingScreenLayout.primaryBlue,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  course.category,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _StatusChip(status: course.status),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        course.description.isEmpty
                            ? 'No description added yet.'
                            : course.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _DetailPill(
                            icon: Icons.menu_book_outlined,
                            label: '${course.modules.length} modules',
                          ),
                          const SizedBox(width: 8),
                          _DetailPill(
                            icon: Icons.video_library_outlined,
                            label: '$lessonCount lessons',
                          ),
                          const SizedBox(width: 8),
                          _DetailPill(
                            icon: Icons.sell_outlined,
                            label: '${course.currency} ${course.price}',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyRecordedCourses extends StatelessWidget {
  const _EmptyRecordedCourses({
    required this.onCreateCoursePressed,
  });

  final VoidCallback onCreateCoursePressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.video_collection_outlined,
                size: 44,
                color: OnboardingScreenLayout.primaryBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No recorded courses yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Create your first recorded course and it will appear here.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton(
                onPressed: onCreateCoursePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: OnboardingScreenLayout.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Create New Course',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
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

class _DetailPill extends StatelessWidget {
  const _DetailPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';
import 'view_course_screen.dart';

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
    final allCourses = [...courses, ..._demoCourses];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3E6ED)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.black54),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Search courses, topics, instructors...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Icon(Icons.tune, color: Colors.black54),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'Trending', selected: true),
                _FilterChip(label: 'Beginner'),
                _FilterChip(label: 'In Progress'),
                _FilterChip(label: 'Completed'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (courses.isNotEmpty) ...[
            const _SectionTitle(
              title: 'Your Created Courses',
              actionLabel: 'View all',
            ),
            const SizedBox(height: 12),
            ...courses.map((course) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CourseCard(course: course),
                )),
            const SizedBox(height: 10),
          ],
          const _SectionTitle(
            title: 'All Courses',
            actionLabel: 'View all',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allCourses.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              return _CourseGridTile(course: allCourses[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
  });

  final CourseDraft course;

  @override
  Widget build(BuildContext context) {
    final lessonCount = course.modules.fold<int>(
      0,
      (count, module) => count + module.lessons.length,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ViewCourseScreen(course: course),
          ),
        );
      },
      child: Container(
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
      ),
    );
  }
}

class _CourseGridTile extends StatelessWidget {
  const _CourseGridTile({
    required this.course,
  });

  final CourseDraft course;

  @override
  Widget build(BuildContext context) {
    final lessonCount = course.modules.fold<int>(
      0,
      (count, module) => count + module.lessons.length,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ViewCourseScreen(course: course),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE3E6ED)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  size: 38,
                  color: OnboardingScreenLayout.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              course.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              course.category,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$lessonCount lessons',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
                _MiniPriceChip(
                  label: course.price == '0' || course.price == '0.00'
                      ? 'Free'
                      : 'Paid',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
  });

  final String title;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        Text(
          actionLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.selected = false,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? OnboardingScreenLayout.primaryBlue
              : const Color(0xFFE3E6ED),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: selected
              ? OnboardingScreenLayout.primaryBlue
              : Colors.black87,
        ),
      ),
    );
  }
}

class _MiniPriceChip extends StatelessWidget {
  const _MiniPriceChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

final List<CourseDraft> _demoCourses = [
  CourseDraft(
    id: 'demo-uiux',
    title: 'UI/UX Design Fundamentals',
    category: 'Design & UI/UX',
    description: 'Learn the core principles of UI/UX design from scratch.',
    currency: 'USD',
    price: '49.99',
    applyDiscount: false,
    couponCode: '',
    thumbnailPath: '',
    promoVideoPath: '',
    modules: [
      CourseModule(
        title: 'Module 1: UX Basics',
        lessons: [
          CourseLesson(
            title: 'Introduction to UI/UX',
            duration: '04:28 min',
            videoPath: '',
          ),
          CourseLesson(
            title: 'Wireframing Basics',
            duration: '09:10 min',
            videoPath: '',
          ),
        ],
      ),
    ],
    status: CourseStatus.published,
  ),
  CourseDraft(
    id: 'demo-flutter',
    title: 'Flutter for Beginners',
    category: 'Development',
    description: 'Start building mobile apps with Flutter step by step.',
    currency: 'USD',
    price: '0.00',
    applyDiscount: false,
    couponCode: '',
    thumbnailPath: '',
    promoVideoPath: '',
    modules: [
      CourseModule(
        title: 'Module 1: Flutter Setup',
        lessons: [
          CourseLesson(
            title: 'Installing Flutter',
            duration: '07:15 min',
            videoPath: '',
          ),
        ],
      ),
    ],
    status: CourseStatus.published,
  ),
  CourseDraft(
    id: 'demo-python',
    title: 'Python Data Structures',
    category: 'Development',
    description: 'Understand lists, tuples, sets, and dictionaries.',
    currency: 'USD',
    price: '29.99',
    applyDiscount: false,
    couponCode: '',
    thumbnailPath: '',
    promoVideoPath: '',
    modules: [
      CourseModule(
        title: 'Module 1: Core Structures',
        lessons: [
          CourseLesson(
            title: 'Lists and Tuples',
            duration: '11:40 min',
            videoPath: '',
          ),
        ],
      ),
    ],
    status: CourseStatus.published,
  ),
  CourseDraft(
    id: 'demo-marketing',
    title: 'Marketing Basics',
    category: 'Marketing',
    description: 'A simple starter course for digital marketing learners.',
    currency: 'USD',
    price: '19.99',
    applyDiscount: false,
    couponCode: '',
    thumbnailPath: '',
    promoVideoPath: '',
    modules: [
      CourseModule(
        title: 'Module 1: Intro to Marketing',
        lessons: [
          CourseLesson(
            title: 'Marketing Overview',
            duration: '05:32 min',
            videoPath: '',
          ),
        ],
      ),
    ],
    status: CourseStatus.published,
  ),
];

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

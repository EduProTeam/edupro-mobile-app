import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';
import '../widgets/course_form_widgets.dart';
import 'create_course_screen.dart';

class ViewCourseScreen extends StatefulWidget {
  const ViewCourseScreen({super.key, required this.course});
  final CourseDraft course;
  @override
  State<ViewCourseScreen> createState() => _ViewCourseScreenState();
}

class _ViewCourseScreenState extends State<ViewCourseScreen> {
  late CourseDraft _course = widget.course;
  Future<void> _edit() async {
    final result = await Navigator.push<CourseDraft>(
      context,
      MaterialPageRoute(builder: (_) => CreateCourseScreen(course: _course)),
    );
    if (mounted && result != null) setState(() => _course = result);
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        title: const Text('View Course'),
        actions: [
          if (course.userId == FirebaseAuth.instance.currentUser?.uid &&
              course.status == CourseStatus.draft)
            TextButton(onPressed: _edit, child: const Text('Edit Draft')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CourseFormCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (course.thumbnail != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        course.thumbnail!.url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: OnboardingScreenLayout.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  course.title.isEmpty ? 'Untitled course' : course.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Chip(
                  label: Text(
                    course.status == CourseStatus.published
                        ? 'Published'
                        : 'Draft',
                  ),
                ),
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
                  style: const TextStyle(fontSize: 15, height: 1.45),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(
                        course.type == CourseType.free
                            ? 'Free'
                            : '${course.currency} ${course.price.toStringAsFixed(2)}',
                      ),
                    ),
                    Chip(label: Text('${course.lessons.length} lessons')),
                    if (course.language.isNotEmpty)
                      Chip(label: Text(course.language)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Course Lessons',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < course.lessons.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CourseFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lessonLabel(i),
                      style: const TextStyle(
                        color: OnboardingScreenLayout.primaryBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.lessons[i].title.isEmpty
                          ? 'Untitled lesson'
                          : course.lessons[i].title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (course.lessons[i].duration.isNotEmpty)
                      Text(course.lessons[i].duration),
                    if (course.lessons[i].description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(course.lessons[i].description),
                      ),
                    if (course.lessons[i].video != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Video attached',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    if (course.lessons[i].materials.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Learning Materials',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      for (final material in course.lessons[i].materials)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.description_outlined),
                          title: Text(material.name),
                        ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

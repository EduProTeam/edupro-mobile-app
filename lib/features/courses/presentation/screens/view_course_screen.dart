import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';
import '../../services/course_service.dart';
import '../widgets/course_form_widgets.dart';
import '../widgets/lesson_video_player.dart';
import 'create_course_screen.dart';

class ViewCourseScreen extends StatefulWidget {
  const ViewCourseScreen({super.key, required this.course});
  final CourseDraft course;

  @override
  State<ViewCourseScreen> createState() => _ViewCourseScreenState();
}

class _ViewCourseScreenState extends State<ViewCourseScreen>
    with SingleTickerProviderStateMixin {
  late CourseDraft _course = widget.course;
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final CourseService _courseService = CourseService();
  bool _saved = false;
  bool _enrolled = false;
  int? _selectedLessonIndex;

  bool get _isOwner =>
      _course.userId.isNotEmpty &&
      _course.userId == FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final result = await Navigator.push<CourseDraft>(
      context,
      MaterialPageRoute(builder: (_) => CreateCourseScreen(course: _course)),
    );
    if (mounted && result != null) setState(() => _course = result);
  }

  void _enrollOrContinue() {
    if (_isOwner) {
      _edit();
      return;
    }
    if (_enrolled && _course.lessons.isNotEmpty) {
      _showLesson(0);
      return;
    }
    setState(() => _enrolled = true);
    _tabs.animateTo(0);
  }

  void _showLesson(int index) {
    if (index < 0 || index >= _course.lessons.length) return;
    setState(() => _selectedLessonIndex = index);
  }

  void _showCourseOverview() {
    setState(() => _selectedLessonIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FB),
        surfaceTintColor: Colors.transparent,
        leading: _selectedLessonIndex == null
            ? null
            : IconButton(
                tooltip: 'Back to course overview',
                onPressed: _showCourseOverview,
                icon: const Icon(Icons.arrow_back),
              ),
        title: Text(
          _selectedLessonIndex == null
              ? 'Course Overview'
              : lessonLabel(_selectedLessonIndex!),
        ),
        actions: [
          IconButton(
            tooltip: _saved ? 'Remove from saved' : 'Save course',
            onPressed: () => setState(() => _saved = !_saved),
            icon: Icon(
              _saved ? Icons.favorite : Icons.favorite_border,
              color: _saved ? OnboardingScreenLayout.primaryBlue : null,
            ),
          ),
        ],
      ),
      body: _selectedLessonIndex != null
          ? _LessonDetailView(
              key: ValueKey(_selectedLessonIndex),
              course: _course,
              lessonIndex: _selectedLessonIndex!,
              onSelectLesson: _showLesson,
              refreshMediaUrl: _courseService.refreshMediaUrl,
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    children: [
                      _CourseHeader(course: _course),
                      const SizedBox(height: 20),
                      TabBar(
                        controller: _tabs,
                        labelColor: OnboardingScreenLayout.primaryBlue,
                        unselectedLabelColor: const Color(0xFF707B94),
                        indicatorColor: OnboardingScreenLayout.primaryBlue,
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(text: 'Lessons'),
                          Tab(text: 'Description'),
                        ],
                      ),
                      SizedBox(
                        height: 430,
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            _LessonsTab(course: _course, onPlay: _showLesson),
                            _DescriptionTab(course: _course),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE3E6ED))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _BottomCourseInfo(
                            course: _course,
                            enrolled: _enrolled,
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _enrollOrContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: OnboardingScreenLayout.primaryBlue,
                            minimumSize: const Size(148, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(_bottomLabel),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String get _bottomLabel {
    if (_isOwner) return 'Edit Course';
    if (_enrolled) return 'Continue Learning';
    return _course.type == CourseType.free ? 'Enroll for Free' : 'Enroll Now';
  }
}

class _LessonDetailView extends StatelessWidget {
  const _LessonDetailView({
    super.key,
    required this.course,
    required this.lessonIndex,
    required this.onSelectLesson,
    required this.refreshMediaUrl,
  });

  final CourseDraft course;
  final int lessonIndex;
  final ValueChanged<int> onSelectLesson;
  final Future<String> Function(String path) refreshMediaUrl;

  @override
  Widget build(BuildContext context) {
    final lesson = course.lessons[lessonIndex];
    final video = lesson.video;
    final nextLessonIndexes = List<int>.generate(
      course.lessons.length - lessonIndex - 1,
      (offset) => lessonIndex + offset + 1,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        CourseFormCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (video != null && video.url.trim().isNotEmpty)
                LessonVideoPlayer(
                  key: ValueKey(video.url),
                  url: video.url,
                  storagePath: video.path,
                  onRefreshUrl: refreshMediaUrl,
                )
              else
                const _UnavailableLessonVideo(),
              const SizedBox(height: 18),
              Text(
                lessonLabel(lessonIndex),
                style: const TextStyle(
                  color: OnboardingScreenLayout.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                lesson.title.isEmpty ? 'Untitled lesson' : lesson.title,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (lesson.duration.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 18,
                      color: Color(0xFF707B94),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lesson.duration,
                      style: const TextStyle(color: Color(0xFF707B94)),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                lesson.description.trim().isEmpty
                    ? 'No description has been added for this lesson.'
                    : lesson.description,
                style: const TextStyle(height: 1.45, color: Color(0xFF4F5B73)),
              ),
              if (lesson.materials.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Learning Materials',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                for (final material in lesson.materials)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MaterialRow(material: material),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          nextLessonIndexes.isEmpty ? 'Course Lessons' : 'Next Lessons',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (nextLessonIndexes.isEmpty)
          const _NoMoreLessons()
        else
          for (final index in nextLessonIndexes)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NextLessonCard(
                lesson: course.lessons[index],
                index: index,
                onTap: () => onSelectLesson(index),
              ),
            ),
      ],
    );
  }
}

class _UnavailableLessonVideo extends StatelessWidget {
  const _UnavailableLessonVideo();

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE5F1FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 44,
              color: OnboardingScreenLayout.primaryBlue,
            ),
            SizedBox(height: 8),
            Text('No lesson video is available.'),
          ],
        ),
      ),
    ),
  );
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material});

  final CourseMedia material;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE3E6ED)),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.description_outlined,
          color: OnboardingScreenLayout.primaryBlue,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            material.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _NextLessonCard extends StatelessWidget {
  const _NextLessonCard({
    required this.lesson,
    required this.index,
    required this.onTap,
  });

  final CourseLesson lesson;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFE5F1FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: OnboardingScreenLayout.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lessonLabel(index),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF707B94),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lesson.title.isEmpty ? 'Untitled lesson' : lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (lesson.duration.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                lesson.duration,
                style: const TextStyle(fontSize: 12, color: Color(0xFF707B94)),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFF8490A6)),
          ],
        ),
      ),
    ),
  );
}

class _NoMoreLessons extends StatelessWidget {
  const _NoMoreLessons();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Text(
      'You are viewing the final lesson in this course.',
      style: TextStyle(color: Color(0xFF707B94)),
    ),
  );
}

class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.course});
  final CourseDraft course;

  @override
  Widget build(BuildContext context) {
    final validImage =
        Uri.tryParse(course.thumbnail?.url ?? '')?.hasScheme == true;
    return CourseFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: validImage
                  ? Image.network(
                      course.thumbnail!.url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _OverviewPlaceholder(),
                    )
                  : const _OverviewPlaceholder(),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            course.title.isEmpty ? 'Untitled course' : course.title,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          if (course.instructorName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'By ${course.instructorName}',
              style: const TextStyle(color: Color(0xFF707B94)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                icon: Icons.star_rounded,
                label: course.rating == 0
                    ? 'New'
                    : course.rating.toStringAsFixed(1),
                color: const Color(0xFFFFBC00),
              ),
              _InfoPill(
                icon: Icons.schedule_outlined,
                label: course.totalDuration.isEmpty
                    ? 'Self paced'
                    : course.totalDuration,
              ),
              _InfoPill(
                icon: Icons.play_lesson_outlined,
                label: '${course.lessons.length} lessons',
              ),
              _InfoPill(
                icon: Icons.language,
                label: course.language.isEmpty
                    ? 'Language not set'
                    : course.language,
              ),
              _InfoPill(icon: Icons.category_outlined, label: course.category),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewPlaceholder extends StatelessWidget {
  const _OverviewPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFE5F1FF),
    child: const Center(
      child: Icon(
        Icons.play_circle_outline,
        size: 58,
        color: OnboardingScreenLayout.primaryBlue,
      ),
    ),
  );
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F6FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color ?? OnboardingScreenLayout.primaryBlue,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _LessonsTab extends StatelessWidget {
  const _LessonsTab({required this.course, required this.onPlay});
  final CourseDraft course;
  final ValueChanged<int> onPlay;

  @override
  Widget build(BuildContext context) {
    if (course.lessons.isEmpty) {
      return const Center(
        child: Text('Lessons will appear here when they are added.'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 14),
      itemCount: course.lessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final lesson = course.lessons[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onPlay(index),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    color: OnboardingScreenLayout.primaryBlue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${lessonLabel(index)} — ${lesson.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (lesson.duration.isNotEmpty)
                          Text(
                            lesson.duration,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF707B94),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF8490A6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DescriptionTab extends StatelessWidget {
  const _DescriptionTab({required this.course});
  final CourseDraft course;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(top: 16),
    children: [
      Text(
        course.description.isEmpty
            ? 'No course description has been added yet.'
            : course.description,
        style: const TextStyle(height: 1.45),
      ),
      const SizedBox(height: 20),
      if (course.category.isNotEmpty)
        _DescriptionItem(label: 'Category', value: course.category),
      if (course.language.isNotEmpty)
        _DescriptionItem(label: 'Language', value: course.language),
      if (course.level.isNotEmpty)
        _DescriptionItem(label: 'Skill level', value: course.level),
      if (course.instructorName.isNotEmpty)
        _DescriptionItem(label: 'Instructor', value: course.instructorName),
    ],
  );
}

class _DescriptionItem extends StatelessWidget {
  const _DescriptionItem({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: const TextStyle(color: Color(0xFF707B94))),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _BottomCourseInfo extends StatelessWidget {
  const _BottomCourseInfo({required this.course, required this.enrolled});
  final CourseDraft course;
  final bool enrolled;
  @override
  Widget build(BuildContext context) {
    if (enrolled) {
      return const Text(
        'Enrolled',
        style: TextStyle(color: Color(0xFF159447), fontWeight: FontWeight.w800),
      );
    }
    if (course.type == CourseType.free) {
      return const Text(
        'Free',
        style: TextStyle(color: Color(0xFF159447), fontWeight: FontWeight.w800),
      );
    }
    return Text(
      '${course.currency} ${course.price.toStringAsFixed(2)}',
      style: const TextStyle(fontWeight: FontWeight.w800),
    );
  }
}

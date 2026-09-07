import 'package:flutter/material.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';
import '../../services/course_service.dart';
import 'view_course_screen.dart';

class RecordedCoursesScreen extends StatefulWidget {
  const RecordedCoursesScreen({super.key, required this.onCreateCoursePressed});

  final VoidCallback onCreateCoursePressed;

  @override
  State<RecordedCoursesScreen> createState() => _RecordedCoursesScreenState();
}

class _RecordedCoursesScreenState extends State<RecordedCoursesScreen>
    with SingleTickerProviderStateMixin {
  final _service = CourseService();
  final _searchController = TextEditingController();
  final Set<String> _savedIds = <String>{};
  final Map<String, int> _completedLessons = <String, int>{};
  late final TabController _tabs = TabController(length: 3, vsync: this);
  late Stream<List<CourseDraft>> _owned = _service.watchCourses(owned: true);
  late Stream<List<CourseDraft>> _published = _service.watchCourses(
    owned: false,
  );

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAllCourses() => _tabs.animateTo(0);

  void _toggleSaved(String id) {
    setState(() {
      if (!_savedIds.add(id)) _savedIds.remove(id);
    });
    // TODO: Persist saved-course state in a user-specific enrollment repository.
  }

  void _openCourse(CourseDraft course) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ViewCourseScreen(course: course)),
    );
  }

  List<CourseDraft> _publicCourses(List<CourseDraft> remoteCourses) {
    return remoteCourses;
  }

  List<CourseDraft> _matching(List<CourseDraft> courses) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return courses;
    return courses.where((course) {
      return [
        course.title,
        course.category,
        course.instructorName,
        course.level,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CourseDraft>>(
      stream: _owned,
      builder: (context, ownedSnapshot) {
        return StreamBuilder<List<CourseDraft>>(
          stream: _published,
          builder: (context, publishedSnapshot) {
            if (ownedSnapshot.hasError || publishedSnapshot.hasError) {
              return _LoadError(
                onRetry: () {
                  setState(() {
                    _owned = _service.watchCourses(owned: true);
                    _published = _service.watchCourses(owned: false);
                  });
                },
              );
            }
            if (!ownedSnapshot.hasData || !publishedSnapshot.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFFF7F8FB),
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _screen(
              publicCourses: _publicCourses(publishedSnapshot.data!),
              ownedCourses: ownedSnapshot.data!,
            );
          },
        );
      },
    );
  }

  Widget _screen({
    required List<CourseDraft> publicCourses,
    required List<CourseDraft> ownedCourses,
  }) {
    final drafts = ownedCourses
        .where((course) => course.status == CourseStatus.draft)
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F8FB),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Recorded Courses',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 52,
              height: 52,
              child: FilledButton(
                onPressed: widget.onCreateCoursePressed,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: OnboardingScreenLayout.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Icon(Icons.add, size: 30),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            labelColor: OnboardingScreenLayout.primaryBlue,
            unselectedLabelColor: const Color(0xFF707B94),
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            indicatorColor: OnboardingScreenLayout.primaryBlue,
            indicatorWeight: 4,
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: const [
              Tab(text: 'All Courses'),
              Tab(text: 'In Progress'),
              Tab(text: 'Saved'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _AllCoursesTab(
                  courses: _matching(publicCourses),
                  drafts: _matching(drafts),
                  savedIds: _savedIds,
                  onOpen: _openCourse,
                  onToggleSaved: _toggleSaved,
                ),
                _InProgressTab(
                  courses: _matching(
                    publicCourses.where(_completedLessons.containsKey).toList(),
                  ),
                  completedLessons: _completedLessons,
                  onOpen: _openCourse,
                  onBrowse: _showAllCourses,
                ),
                _SavedTab(
                  courses: _matching(
                    publicCourses
                        .where((course) => _savedIds.contains(course.id))
                        .toList(),
                  ),
                  onOpen: _openCourse,
                  onToggleSaved: _toggleSaved,
                  onBrowse: _showAllCourses,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCoursesTab extends StatelessWidget {
  const _AllCoursesTab({
    required this.courses,
    required this.drafts,
    required this.savedIds,
    required this.onOpen,
    required this.onToggleSaved,
  });

  final List<CourseDraft> courses;
  final List<CourseDraft> drafts;
  final Set<String> savedIds;
  final ValueChanged<CourseDraft> onOpen;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty && drafts.isEmpty) {
      return const _EmptyCourses(
        title: 'No matching courses',
        message: 'Try another search term to find a course.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        if (drafts.isNotEmpty) ...[
          const _SectionLabel('Your Drafts'),
          const SizedBox(height: 10),
          for (final course in drafts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCard(
                course: course,
                saved: savedIds.contains(course.id),
                onOpen: onOpen,
                onToggleSaved: onToggleSaved,
                draft: true,
              ),
            ),
          const SizedBox(height: 10),
        ],
        if (courses.isNotEmpty) ...[
          const _SectionLabel('All Courses'),
          const SizedBox(height: 10),
          for (final course in courses)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CourseCard(
                course: course,
                saved: savedIds.contains(course.id),
                onOpen: onOpen,
                onToggleSaved: onToggleSaved,
              ),
            ),
        ],
      ],
    );
  }
}

class _InProgressTab extends StatelessWidget {
  const _InProgressTab({
    required this.courses,
    required this.completedLessons,
    required this.onOpen,
    required this.onBrowse,
  });

  final List<CourseDraft> courses;
  final Map<String, int> completedLessons;
  final ValueChanged<CourseDraft> onOpen;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return _EmptyCourses(
        title: 'No courses in progress',
        message:
            'Enroll in a course and start learning to see your progress here.',
        actionLabel: 'Browse Courses',
        onAction: onBrowse,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final course = courses[index];
        final total = course.lessons.length;
        final completed = (completedLessons[course.id] ?? 0).clamp(0, total);
        final progress = total == 0 ? 0.0 : completed / total;
        return _ProgressCourseCard(
          course: course,
          completed: completed,
          total: total,
          progress: progress,
          onOpen: onOpen,
        );
      },
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab({
    required this.courses,
    required this.onOpen,
    required this.onToggleSaved,
    required this.onBrowse,
  });

  final List<CourseDraft> courses;
  final ValueChanged<CourseDraft> onOpen;
  final ValueChanged<String> onToggleSaved;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return _EmptyCourses(
        title: 'No saved courses',
        message: 'Tap the heart icon on a course to save it for later.',
        actionLabel: 'Browse Courses',
        onAction: onBrowse,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _CourseCard(
        course: courses[index],
        saved: true,
        onOpen: onOpen,
        onToggleSaved: onToggleSaved,
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.saved,
    required this.onOpen,
    required this.onToggleSaved,
    this.draft = false,
  });

  final CourseDraft course;
  final bool saved;
  final bool draft;
  final ValueChanged<CourseDraft> onOpen;
  final ValueChanged<String> onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final hasRemoteThumbnail =
        Uri.tryParse(course.thumbnail?.url ?? '')?.hasScheme == true;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => onOpen(course),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 116,
                  height: 116,
                  child: hasRemoteThumbnail
                      ? Image.network(
                          course.thumbnail!.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _CourseThumbnail(course: course),
                        )
                      : _CourseThumbnail(course: course),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 116,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              course.title.isEmpty
                                  ? 'Untitled course'
                                  : course.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: saved
                                ? 'Remove from saved'
                                : 'Save course',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => onToggleSaved(course.id),
                            icon: Icon(
                              saved ? Icons.favorite : Icons.favorite_border,
                              color: saved
                                  ? OnboardingScreenLayout.primaryBlue
                                  : const Color(0xFF69748B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${course.level}  •  ${course.lessons.length} lessons',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF707B94),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFBC00),
                            size: 23,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            course.rating == 0
                                ? 'New'
                                : course.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              course.totalDuration.isEmpty
                                  ? 'Self paced'
                                  : course.totalDuration,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Color(0xFF707B94)),
                            ),
                          ),
                          const Spacer(),
                          _PriceBadge(course: course, draft: draft),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCourseCard extends StatelessWidget {
  const _ProgressCourseCard({
    required this.course,
    required this.completed,
    required this.total,
    required this.progress,
    required this.onOpen,
  });

  final CourseDraft course;
  final int completed;
  final int total;
  final double progress;
  final ValueChanged<CourseDraft> onOpen;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => onOpen(course),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: _CourseThumbnail(course: course),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$completed of $total lessons completed',
              style: const TextStyle(color: Color(0xFF707B94)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onOpen(course),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Continue Learning'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CourseThumbnail extends StatelessWidget {
  const _CourseThumbnail({required this.course});
  final CourseDraft course;

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFE5F1FF),
    child: Center(
      child: Icon(
        course.category.toLowerCase().contains('market')
            ? Icons.campaign_outlined
            : course.category.toLowerCase().contains('develop')
            ? Icons.code_rounded
            : Icons.design_services_outlined,
        color: OnboardingScreenLayout.primaryBlue,
        size: 46,
      ),
    ),
  );
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.course, required this.draft});
  final CourseDraft course;
  final bool draft;

  @override
  Widget build(BuildContext context) {
    final free = course.type == CourseType.free;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: draft
            ? const Color(0xFFF0F2F5)
            : free
            ? const Color(0xFFDDF9E9)
            : const Color(0xFFE5F1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        draft
            ? 'Draft'
            : free
            ? 'Free'
            : 'Paid',
        style: TextStyle(
          color: draft
              ? const Color(0xFF657084)
              : free
              ? const Color(0xFF159447)
              : OnboardingScreenLayout.primaryBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
  );
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 46,
            color: Color(0xFF8490A6),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF707B94), height: 1.4),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8FB),
    appBar: AppBar(title: const Text('Recorded Courses')),
    body: Center(
      child: TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Unable to load courses. Retry'),
      ),
    ),
  );
}

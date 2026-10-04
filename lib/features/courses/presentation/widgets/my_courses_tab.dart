import 'package:flutter/material.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';

enum CourseSort {
  newest('Newest'),
  oldest('Oldest'),
  title('Course title'),
  published('Published first'),
  draft('Draft first');

  const CourseSort(this.label);
  final String label;
}

class MyCoursesTab extends StatefulWidget {
  const MyCoursesTab({
    super.key,
    required this.courses,
    required this.searching,
    required this.deletingIds,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onCreate,
    required this.onClearSearch,
  });
  final List<CourseDraft> courses;
  final bool searching;
  final Set<String> deletingIds;
  final ValueChanged<CourseDraft> onOpen, onEdit, onDelete;
  final VoidCallback onCreate, onClearSearch;

  @override
  State<MyCoursesTab> createState() => _MyCoursesTabState();
}

class _MyCoursesTabState extends State<MyCoursesTab>
    with AutomaticKeepAliveClientMixin {
  CourseSort _sort = CourseSort.newest;
  @override
  bool get wantKeepAlive => true;

  int _compare(CourseDraft a, CourseDraft b) {
    // Older documents have no createdAt; their last update is the best available date.
    final aTime = a.createdAt == 0 ? a.updatedAt : a.createdAt;
    final bTime = b.createdAt == 0 ? b.updatedAt : b.createdAt;
    final comparison = switch (_sort) {
      CourseSort.newest => bTime.compareTo(aTime),
      CourseSort.oldest => aTime.compareTo(bTime),
      CourseSort.title => a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      ),
      CourseSort.published => b.status.index.compareTo(a.status.index),
      CourseSort.draft => a.status.index.compareTo(b.status.index),
    };
    return comparison != 0 ? comparison : a.id.compareTo(b.id);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final courses = List<CourseDraft>.of(widget.courses)..sort(_compare);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${courses.length} ${courses.length == 1 ? 'course' : 'courses'}',
                  style: const TextStyle(
                    color: Color(0xFF707B94),
                    fontSize: 15,
                  ),
                ),
              ),
              PopupMenuButton<CourseSort>(
                tooltip: 'Sort courses',
                initialValue: _sort,
                icon: const Icon(Icons.sort, color: Color(0xFF59647B)),
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (_) => [
                  for (final value in CourseSort.values)
                    CheckedPopupMenuItem(
                      value: value,
                      checked: value == _sort,
                      child: Text(value.label),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: courses.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.video_library_outlined,
                            size: 52,
                            color: OnboardingScreenLayout.primaryBlue,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.searching
                                ? 'No matching courses'
                                : 'No courses created yet',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.searching
                                ? 'Try another search term.'
                                : 'Create your first course and start sharing your knowledge.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF707B94)),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: widget.searching
                                ? widget.onClearSearch
                                : widget.onCreate,
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  OnboardingScreenLayout.primaryBlue,
                            ),
                            child: Text(
                              widget.searching
                                  ? 'Clear Search'
                                  : 'Create Course',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: courses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final course = courses[index];
                    return MyCourseCard(
                      key: ValueKey(course.id),
                      course: course,
                      deleting: widget.deletingIds.contains(course.id),
                      onOpen: () => widget.onOpen(course),
                      onEdit: () => widget.onEdit(course),
                      onDelete: () => widget.onDelete(course),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class MyCourseCard extends StatelessWidget {
  const MyCourseCard({
    super.key,
    required this.course,
    required this.deleting,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });
  final CourseDraft course;
  final bool deleting;
  final VoidCallback onOpen, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    const blue = OnboardingScreenLayout.primaryBlue;
    const navy = Color(0xFF111B35);
    final published = course.status == CourseStatus.published;
    final statusColor = published
        ? const Color(0xFF239A46)
        : const Color(0xFF9A6B13);
    final uri = Uri.tryParse(course.thumbnail?.url ?? '');
    final remote =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty;
    final placeholder = DecoratedBox(
      key: const ValueKey('course-thumbnail-placeholder'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE5F1FF), Color(0xFFC8DFFF)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.ondemand_video_rounded, color: blue, size: 36),
      ),
    );
    final actions = Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          onPressed: deleting ? null : onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
          style: OutlinedButton.styleFrom(
            foregroundColor: blue,
            side: const BorderSide(color: blue),
            minimumSize: const Size(96, 38),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: deleting ? null : onDelete,
          icon: deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline, size: 18),
          label: Text(deleting ? 'Deleting...' : 'Delete'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD32F2F),
            side: const BorderSide(color: Color(0xFFEF9A9A)),
            minimumSize: const Size(96, 38),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
    final rightAlignedActions = Align(
      alignment: Alignment.centerRight,
      child: actions,
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080E2145),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE8ECF2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: deleting ? null : onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact =
                    constraints.maxWidth < 370 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 88,
                            height: 88,
                            child: remote
                                ? Image.network(
                                    uri.toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => placeholder,
                                    loadingBuilder: (_, child, progress) =>
                                        progress == null ? child : placeholder,
                                  )
                                : placeholder,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        course.title.isEmpty
                                            ? 'Untitled course'
                                            : course.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: navy,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 30,
                                    height: 32,
                                    child: PopupMenuButton<String>(
                                      tooltip: 'Course options',
                                      padding: EdgeInsets.zero,
                                      enabled: !deleting,
                                      icon: const Icon(
                                        Icons.more_horiz,
                                        size: 22,
                                        color: Color(0xFF59647B),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          onEdit();
                                        } else {
                                          onDelete();
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit'),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: published
                                      ? const Color(0xFFE2F7E7)
                                      : const Color(0xFFFFF3D8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  published ? 'Published' : 'Draft',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                runSpacing: 5,
                                children: [
                                  _CardStat(
                                    Icons.menu_book_outlined,
                                    '${course.lessons.length} ${course.lessons.length == 1 ? 'lesson' : 'lessons'}',
                                  ),
                                  _CardStat(
                                    Icons.people_outline,
                                    '${course.enrollmentCount} ${course.enrollmentCount == 1 ? 'student' : 'students'}',
                                  ),
                                ],
                              ),
                              if (!compact) ...[
                                const SizedBox(height: 10),
                                rightAlignedActions,
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (compact) ...[
                      const SizedBox(height: 10),
                      rightAlignedActions,
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: const Color(0xFF707B94)),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF707B94)),
        ),
      ),
    ],
  );
}

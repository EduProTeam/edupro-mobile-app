import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';
import '../../services/course_service.dart';
import '../widgets/course_form_widgets.dart';
import '../widgets/lesson_editor.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key, this.course, this.service});
  final CourseDraft? course;
  final CourseService? service;
  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  late final _service = widget.service ?? CourseService();
  final _formKey = GlobalKey<FormState>();
  late final _id = widget.course?.id ?? _service.newId();
  late final _title = TextEditingController(text: widget.course?.title);
  late final _description = TextEditingController(
    text: widget.course?.description,
  );
  late final _price = TextEditingController(
    text: widget.course?.price.toString() ?? '',
  );
  late String? _category = widget.course?.category.isNotEmpty == true
      ? widget.course!.category
      : null;
  late String? _language = widget.course?.language.isNotEmpty == true
      ? widget.course!.language
      : null;
  late String _currency = widget.course?.currency ?? 'USD';
  late CourseType _type = widget.course?.type ?? CourseType.free;
  late CourseFileSelection? _cover = widget.course?.thumbnail == null
      ? null
      : CourseFileSelection.stored(widget.course!.thumbnail!);
  late final List<LessonFormData> _lessons =
      widget.course?.lessons.isNotEmpty == true
      ? widget.course!.lessons.map(LessonFormData.fromLesson).toList()
      : [LessonFormData(id: _service.newId())];
  bool _busy = false, _picking = false, _publishErrors = false;
  String? _error;
  String _operation = '';
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  String? _required(String? value) =>
      _publishErrors && (value ?? '').trim().isEmpty
      ? 'This field is required.'
      : null;
  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _pickCover() async {
    setState(() => _picking = true);
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image != null && mounted) {
        setState(() => _cover = CourseFileSelection.local(image.path));
      }
    } catch (_) {
      _message('Unable to select the cover image. Please try again.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<LessonFormData?> _showLessonEditor({
    required LessonFormData lesson,
    required int number,
    required bool creating,
  }) {
    return showGeneralDialog<LessonFormData>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Lesson editor',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) => Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
              child: const ColoredBox(color: Color(0x99000000)),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 440,
                      maxHeight: MediaQuery.sizeOf(dialogContext).height * .86,
                    ),
                    child: SingleChildScrollView(
                      child: InlineLessonEditor(
                        lesson: lesson,
                        number: number,
                        heading: creating ? 'Create Lesson' : 'Edit Lesson',
                        showErrors: _publishErrors,
                        onRetry: _upload,
                        onCancel: () => Navigator.of(dialogContext).pop(),
                        onSave: (updated) =>
                            Navigator.of(dialogContext).pop(updated),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: .94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _editLesson(int index) async {
    final updated = await _showLessonEditor(
      lesson: _lessons[index],
      number: index,
      creating: false,
    );
    if (mounted && updated != null) {
      setState(() => _lessons[index] = updated);
    }
  }

  Future<void> _addLesson() async {
    final lesson = await _showLessonEditor(
      lesson: LessonFormData(id: _service.newId()),
      number: _lessons.length,
      creating: true,
    );
    if (mounted && lesson != null) {
      setState(() => _lessons.add(lesson));
    }
  }

  void _removeLesson(int index) => setState(() => _lessons.removeAt(index));

  CourseDraft _buildCourse(CourseStatus status) => CourseDraft(
    id: _id,
    title: _title.text.trim(),
    description: _description.text.trim(),
    category: _category ?? '',
    language: _language ?? '',
    type: _type,
    currency: _currency,
    price: _type == CourseType.free
        ? 0
        : double.tryParse(_price.text.trim()) ?? 0,
    status: status,
    thumbnail: _cover?.media,
    userId: _service.userId,
    instructorName: widget.course?.instructorName ?? '',
    level: widget.course?.level ?? 'Beginner',
    rating: widget.course?.rating ?? 0,
    totalDuration: widget.course?.totalDuration ?? '',
    createdAt: widget.course?.createdAt ?? 0,
    enrollmentCount: widget.course?.enrollmentCount ?? 0,
    lessons: _lessons
        .map(
          (lesson) => CourseLesson(
            id: lesson.id,
            title: lesson.title,
            description: lesson.description,
            duration: lesson.duration,
            video: lesson.video?.media,
            materials: lesson.materials
                .where((material) => material.media != null)
                .map((material) => material.media!)
                .toList(),
          ),
        )
        .toList(),
  );

  Future<void> _upload(CourseFileSelection file) async {
    if (file.media != null) return;
    if (mounted) setState(() => file.status = UploadStatus.uploading);
    try {
      file.media = await _service.upload(_id, file.localPath!);
      file.status = UploadStatus.uploaded;
    } catch (_) {
      file.status = UploadStatus.failed;
      rethrow;
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _retryCover() async {
    setState(() => _busy = true);
    try {
      await _upload(_cover!);
    } on CourseFailure catch (e) {
      _message(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(CourseStatus status) async {
    if (_busy || _picking) return;
    setState(() {
      _publishErrors = status == CourseStatus.published;
      _error = null;
    });
    final validFields = _formKey.currentState!.validate();
    final badLesson = _lessons.indexWhere(
      (l) => l.title.trim().isEmpty || l.video == null,
    );
    if (!validFields ||
        (_publishErrors && (_cover == null || badLesson >= 0))) {
      setState(
        () => _error =
            'Complete the required fields${badLesson >= 0 ? ' and ${lessonLabel(badLesson)}' : ''} before publishing.',
      );
      if (_publishErrors && badLesson >= 0) await _editLesson(badLesson);
      return;
    }
    setState(() {
      _busy = true;
      _operation = 'Saving course draft…';
    });
    try {
      final isNew = widget.course == null;
      if (isNew) {
        await _service.save(_buildCourse(CourseStatus.draft), isNew: true);
      }
      if (!mounted) return;
      setState(() => _operation = 'Uploading course files…');
      final files = [
        ?_cover,
        for (final lesson in _lessons) ...[
          if (lesson.video != null) lesson.video!,
          ...lesson.materials,
        ],
      ];
      for (final file in files) {
        await _upload(file);
      }
      if (!mounted) return;
      setState(() => _operation = 'Saving course…');
      final course = _buildCourse(status);
      await _service.save(course, isNew: false);
      if (mounted) {
        _message(
          widget.course != null
              ? 'Course changes saved.'
              : status == CourseStatus.draft
              ? 'Draft saved.'
              : 'Course published.',
        );
        Navigator.pop(context, course);
      }
    } on CourseFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save the course. Please retry.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _dropdown(
    String label,
    String? value,
    List<String> values,
    ValueChanged<String?> changed,
  ) => CourseField(
    label: label,
    requiredField: true,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: courseInput('Select ${label.toLowerCase()}'),
      items: {
        ...values,
        ?value,
      }.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
      onChanged: changed,
      validator: _required,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: OnboardingScreenLayout.primaryBlue),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FB),
        appBar: AppBar(
          title: Text(
            widget.course == null ? 'Create New Course' : 'Edit Course',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text(
                  widget.course?.status == CourseStatus.published
                      ? 'Published'
                      : 'Draft',
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: AbsorbPointer(
                  absorbing: _busy || _picking,
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _publishErrors
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: SingleChildScrollView(
                      key: const ValueKey('course-scroll'),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CourseFormCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Course Details',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                CourseField(
                                  label: 'Course Thumbnail / Cover Image',
                                  requiredField: true,
                                  child: CourseUploadField(
                                    label: 'Upload cover image',
                                    image: true,
                                    selection: _cover,
                                    onPick: _pickCover,
                                    onRemove: _cover == null
                                        ? null
                                        : () => setState(() => _cover = null),
                                    onRetry: _retryCover,
                                    error: _publishErrors && _cover == null
                                        ? 'Add a cover image before publishing.'
                                        : null,
                                  ),
                                ),
                                CourseField(
                                  label: 'Course Title',
                                  requiredField: true,
                                  child: TextFormField(
                                    controller: _title,
                                    decoration: courseInput(
                                      'Enter course title',
                                    ),
                                    validator: _required,
                                  ),
                                ),
                                CourseField(
                                  label: 'Short Description',
                                  requiredField: true,
                                  child: TextFormField(
                                    controller: _description,
                                    decoration: courseInput(
                                      'Tell learners what your course is about',
                                    ),
                                    maxLines: 3,
                                    validator: _required,
                                  ),
                                ),
                                _dropdown(
                                  'Category',
                                  _category,
                                  [
                                    'Design & UI/UX',
                                    'Development',
                                    'Marketing',
                                    'Business',
                                    'Other',
                                  ],
                                  (v) => setState(() => _category = v),
                                ),
                                _dropdown(
                                  'Language',
                                  _language,
                                  ['English', 'Sinhala', 'Tamil', 'Other'],
                                  (v) => setState(() => _language = v),
                                ),
                                CourseField(
                                  label: 'Course Type',
                                  requiredField: true,
                                  child: SegmentedButton<CourseType>(
                                    segments: const [
                                      ButtonSegment(
                                        value: CourseType.free,
                                        label: Text('Free'),
                                      ),
                                      ButtonSegment(
                                        value: CourseType.paid,
                                        label: Text('Paid'),
                                      ),
                                    ],
                                    selected: {_type},
                                    onSelectionChanged: (v) =>
                                        setState(() => _type = v.first),
                                  ),
                                ),
                                if (_type == CourseType.paid) ...[
                                  _dropdown(
                                    'Currency',
                                    _currency,
                                    ['USD', 'LKR'],
                                    (v) => setState(() => _currency = v!),
                                  ),
                                  CourseField(
                                    label: 'Price',
                                    requiredField: true,
                                    child: TextFormField(
                                      controller: _price,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: courseInput('0.00'),
                                      validator: (v) => _publishErrors
                                          ? validateCoursePrice(v ?? '')
                                          : null,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Lessons',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (var i = 0; i < _lessons.length; i++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CourseFormCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lessonLabel(i),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: OnboardingScreenLayout
                                                .primaryBlue,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _lessons[i].title.isEmpty
                                              ? 'Untitled lesson'
                                              : _lessons[i].title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _lessons[i].video?.name ??
                                              'No video selected',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (_lessons[i].video != null)
                                          Text(
                                            switch (_lessons[i].video!.status) {
                                              UploadStatus.uploading =>
                                                'Uploading…',
                                              UploadStatus.uploaded =>
                                                '✓ Uploaded',
                                              UploadStatus.failed =>
                                                'Upload failed · open Edit to retry',
                                              UploadStatus.selected =>
                                                'Video selected',
                                            },
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        if (_lessons[i].materials.isNotEmpty)
                                          Text(
                                            '${_lessons[i].materials.length} learning materials',
                                          ),
                                        if (_lessons[i].materials.any(
                                          (f) =>
                                              f.status == UploadStatus.failed,
                                        ))
                                          const Text(
                                            'Material upload failed · open Edit to retry',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        if (_publishErrors &&
                                            (_lessons[i].title.isEmpty ||
                                                _lessons[i].video == null))
                                          const Text(
                                            'Lesson title and video are required.',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            TextButton.icon(
                                              onPressed: () => _editLesson(i),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                              ),
                                              label: const Text('Edit'),
                                            ),
                                            if (_lessons.length > 1)
                                              TextButton.icon(
                                                onPressed: () =>
                                                    _removeLesson(i),
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                ),
                                                label: const Text(
                                                  'Remove Lesson',
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: _addLesson,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              side: const BorderSide(
                                color: OnboardingScreenLayout.primaryBlue,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Another Lesson'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE3E6ED))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (_busy) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 6),
                      Text(_operation),
                      const SizedBox(height: 8),
                    ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final buttons = [
                          OutlinedButton(
                            onPressed: _busy || _picking
                                ? null
                                : () => _save(
                                    widget.course?.status == CourseStatus.draft
                                        ? CourseStatus.published
                                        : CourseStatus.draft,
                                  ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              widget.course?.status == CourseStatus.draft
                                  ? 'Publish Course'
                                  : 'Save as Draft',
                            ),
                          ),
                          FilledButton(
                            onPressed: _busy || _picking
                                ? null
                                : () => _save(
                                    widget.course?.status ??
                                        CourseStatus.published,
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  OnboardingScreenLayout.primaryBlue,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              widget.course == null
                                  ? 'Publish Course'
                                  : 'Save Changes',
                            ),
                          ),
                        ];
                        if (constraints.maxWidth < 330 ||
                            MediaQuery.textScalerOf(context).scale(16) > 22) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              buttons[0],
                              const SizedBox(height: 8),
                              buttons[1],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: buttons[0]),
                            const SizedBox(width: 12),
                            Expanded(child: buttons[1]),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

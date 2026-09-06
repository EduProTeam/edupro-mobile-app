import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/course_draft.dart';
import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import 'course_form_widgets.dart';

class LessonFormData {
  LessonFormData({
    required this.id,
    this.title = '',
    this.description = '',
    this.duration = '',
    this.video,
    List<CourseFileSelection>? materials,
  }) : materials = materials ?? [];
  final String id;
  String title, description, duration;
  CourseFileSelection? video;
  final List<CourseFileSelection> materials;
  factory LessonFormData.fromLesson(CourseLesson lesson) => LessonFormData(
    id: lesson.id,
    title: lesson.title,
    description: lesson.description,
    duration: lesson.duration,
    video: lesson.video == null
        ? null
        : CourseFileSelection.stored(lesson.video!),
    materials: lesson.materials.map(CourseFileSelection.stored).toList(),
  );
  LessonFormData copy() => LessonFormData(
    id: id,
    title: title,
    description: description,
    duration: duration,
    video: video,
    materials: [...materials],
  );
}

class LessonEditor extends StatefulWidget {
  const LessonEditor({
    super.key,
    required this.lesson,
    required this.number,
    this.showErrors = false,
    required this.onRetry,
  });
  final LessonFormData lesson;
  final int number;
  final bool showErrors;
  final Future<void> Function(CourseFileSelection) onRetry;
  @override
  State<LessonEditor> createState() => _LessonEditorState();
}

class _LessonEditorState extends State<LessonEditor> {
  late final LessonFormData _lesson = widget.lesson.copy();
  late final _title = TextEditingController(text: _lesson.title);
  late final _description = TextEditingController(text: _lesson.description);
  bool _busy = false;
  final _picker = ImagePicker();
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _pick({bool video = false, int? replace}) async {
    setState(() => _busy = true);
    try {
      if (video) {
        final file = await _picker.pickVideo(source: ImageSource.gallery);
        if (file != null && mounted) {
          setState(() => _lesson.video = CourseFileSelection.local(file.path));
        }
      } else {
        final file = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'docx', 'pptx'],
        );
        if (file != null && file.path != null && mounted) {
          if (![
            'pdf',
            'docx',
            'pptx',
          ].contains(file.name.split('.').last.toLowerCase())) {
            _message('Choose a PDF, DOCX or PPTX file.');
            return;
          }
          setState(() {
            final selection = CourseFileSelection.local(file.path!);
            if (replace == null) {
              _lesson.materials.add(selection);
            } else {
              _lesson.materials[replace] = selection;
            }
          });
        }
      }
    } catch (_) {
      _message('Unable to select this file. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry(CourseFileSelection file) async {
    setState(() {
      _busy = true;
      file.status = UploadStatus.uploading;
    });
    try {
      await widget.onRetry(file);
    } catch (_) {
      _message('Upload failed. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(title: Text('${lessonLabel(widget.number)} — Editor')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: CourseFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CourseField(
                        label: 'Lesson Title',
                        requiredField: true,
                        child: TextField(
                          controller: _title,
                          onChanged: (_) => setState(() {}),
                          decoration: courseInput('Enter lesson title')
                              .copyWith(
                                errorText:
                                    widget.showErrors &&
                                        _title.text.trim().isEmpty
                                    ? 'Enter a lesson title.'
                                    : null,
                              ),
                        ),
                      ),
                      CourseField(
                        label: 'Upload Lesson Video',
                        requiredField: true,
                        child: CourseUploadField(
                          label: 'Select video',
                          selection: _lesson.video,
                          onPick: _busy ? null : () => _pick(video: true),
                          onRemove: _busy || _lesson.video == null
                              ? null
                              : () => setState(() => _lesson.video = null),
                          onRetry: _busy || _lesson.video == null
                              ? null
                              : () => _retry(_lesson.video!),
                          error: widget.showErrors && _lesson.video == null
                              ? 'Add a lesson video before publishing.'
                              : null,
                        ),
                      ),
                      CourseField(
                        label: 'Lesson Description',
                        child: TextField(
                          controller: _description,
                          maxLines: 4,
                          decoration: courseInput('Describe this lesson'),
                        ),
                      ),
                      const Text(
                        'Attach Learning Materials',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'PDF, DOCX, PPTX',
                        style: TextStyle(color: Colors.black54),
                      ),
                      for (var i = 0; i < _lesson.materials.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: CourseUploadField(
                            label: 'Choose file',
                            selection: _lesson.materials[i],
                            onPick: _busy ? null : () => _pick(replace: i),
                            onRemove: _busy
                                ? null
                                : () => setState(
                                    () => _lesson.materials.removeAt(i),
                                  ),
                            onRetry: _busy
                                ? null
                                : () => _retry(_lesson.materials[i]),
                          ),
                        ),
                      TextButton.icon(
                        onPressed: _busy ? null : () => _pick(),
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Choose files'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: OnboardingScreenLayout.primaryBlue,
                        minimumSize: const Size.fromHeight(54),
                      ),
                      onPressed: _busy
                          ? null
                          : () {
                              _lesson.title = _title.text.trim();
                              _lesson.description = _description.text.trim();
                              Navigator.pop(context, _lesson);
                            },
                      child: const Text('Save Lesson'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';

class CreateCourseScreen extends StatefulWidget {
  const CreateCourseScreen({super.key});

  @override
  State<CreateCourseScreen> createState() => _CreateCourseScreenState();
}

class _CreateCourseScreenState extends State<CreateCourseScreen> {
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '99.99');
  final _couponController = TextEditingController();

  int _selectedTab = 0;
  String _category = 'Design & UI/UX';
  String _currency = 'USD (\$)';
  bool _applyDiscount = false;
  String _thumbnailPath = '';
  String _promoVideoPath = '';
  final List<_EditableModule> _modules = [
    _EditableModule(
      title: 'Module 1: Introduction to Figma',
      lessons: [
        _EditableLesson(
          title: '01. Introduction to Figma',
          duration: '04:28 min',
          videoPath: '',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  String _fileName(String path) {
    if (path.isEmpty) {
      return 'Not added';
    }

    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  Future<void> _pickThumbnail() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (file == null || !mounted) {
      return;
    }

    setState(() {
      _thumbnailPath = file.path;
    });
  }

  Future<void> _pickPromoVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);

    if (file == null || !mounted) {
      return;
    }

    setState(() {
      _promoVideoPath = file.path;
    });
  }

  Future<void> _showMediaUploadSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload Course Media',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: const Text('Upload Thumbnail'),
                  subtitle: Text(_fileName(_thumbnailPath)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickThumbnail();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: const Text('Upload Promo Video'),
                  subtitle: Text(_fileName(_promoVideoPath)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _pickPromoVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickLessonVideo(_EditableLesson lesson) async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);

    if (file == null || !mounted) {
      return;
    }

    setState(() {
      lesson.videoPath = file.path;
    });
  }

  Future<void> _editLesson(_EditableLesson lesson) async {
    final titleController = TextEditingController(text: lesson.title);
    final durationController = TextEditingController(text: lesson.duration);

    final updated = await showDialog<_EditableLesson>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Lesson'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Lesson Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.video_library_outlined),
                  title: const Text('Lesson Video'),
                  subtitle: Text(_fileName(lesson.videoPath)),
                  trailing: TextButton(
                    onPressed: () async {
                      await _pickLessonVideo(lesson);
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        await _editLesson(lesson);
                      }
                    },
                    child: const Text('Upload'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _EditableLesson(
                    title: titleController.text.trim().isEmpty
                        ? lesson.title
                        : titleController.text.trim(),
                    duration: durationController.text.trim().isEmpty
                        ? lesson.duration
                        : durationController.text.trim(),
                    videoPath: lesson.videoPath,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated == null) {
      return;
    }

    setState(() {
      lesson
        ..title = updated.title
        ..duration = updated.duration
        ..videoPath = updated.videoPath;
    });
  }

  void _addModule() {
    setState(() {
      _modules.add(
        _EditableModule(
          title: 'Module ${_modules.length + 1}: New Module',
          lessons: [
            _EditableLesson(
              title: '01. New Lesson',
              duration: '00:00 min',
              videoPath: '',
            ),
          ],
        ),
      );
    });
  }

  void _addLesson(_EditableModule module) {
    setState(() {
      module.lessons.add(
        _EditableLesson(
          title: '${module.lessons.length + 1}. New Lesson',
          duration: '00:00 min',
          videoPath: '',
        ),
      );
    });
  }

  void _saveCourse(CourseStatus status) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final course = CourseDraft(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      category: _category,
      description: _descriptionController.text.trim(),
      currency: _currency,
      price: _priceController.text.trim(),
      applyDiscount: _applyDiscount,
      couponCode: _couponController.text.trim(),
      thumbnailPath: _thumbnailPath,
      promoVideoPath: _promoVideoPath,
      modules: _modules
          .map(
            (module) => CourseModule(
              title: module.title,
              lessons: module.lessons
                  .map(
                    (lesson) => CourseLesson(
                      title: lesson.title,
                      duration: lesson.duration,
                      videoPath: lesson.videoPath,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      status: status,
    );

    Navigator.of(context).pop(course);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Create New Course',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => _showMessage('Preview can be connected later.'),
            icon: const Icon(Icons.remove_red_eye_outlined, size: 20),
            label: const Text('Draft'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _saveCourse(CourseStatus.draft),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Color(0xFFD6DCE6)),
                ),
                child: const Text(
                  'Save as Draft',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _saveCourse(CourseStatus.published),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: OnboardingScreenLayout.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Publish Course',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _showMediaUploadSheet,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: OnboardingScreenLayout.primaryBlue,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.photo_camera_outlined,
                      size: 36,
                      color: OnboardingScreenLayout.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '+ Upload Promo Video / Thumbnail',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: OnboardingScreenLayout.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Supported formats: MP4, PNG, JPG (16:9 ratio)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    if (_thumbnailPath.isNotEmpty || _promoVideoPath.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Thumbnail: ${_fileName(_thumbnailPath)}\nPromo Video: ${_fileName(_promoVideoPath)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _FieldLabel('Course Title'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                'Enter engaging course title e.g., Figma Masterclass',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Enter the course title.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Course Category'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: _inputDecoration('Course Category'),
              borderRadius: BorderRadius.circular(18),
              items: const [
                DropdownMenuItem(
                  value: 'Design & UI/UX',
                  child: Text('Design & UI/UX'),
                ),
                DropdownMenuItem(
                  value: 'Development',
                  child: Text('Development'),
                ),
                DropdownMenuItem(
                  value: 'Marketing',
                  child: Text('Marketing'),
                ),
                DropdownMenuItem(
                  value: 'Business',
                  child: Text('Business'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _category = value;
                });
              },
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: _FieldLabel('Course Price'),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Apply Discount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: _applyDiscount,
                      onChanged: (value) {
                        setState(() {
                          _applyDiscount = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: _inputDecoration('Currency'),
                    borderRadius: BorderRadius.circular(18),
                    items: const [
                      DropdownMenuItem(
                        value: 'USD (\$)',
                        child: Text('USD (\$)'),
                      ),
                      DropdownMenuItem(
                        value: 'LKR (Rs)',
                        child: Text('LKR (Rs)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _currency = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('99.99'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Enter price';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            if (_applyDiscount) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _couponController,
                decoration: _inputDecoration('Coupon / discount note'),
              ),
            ],
            const SizedBox(height: 18),
            const _FieldLabel('Course Description'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration(
                'Short description about the course, audience, and outcomes',
              ),
            ),
            const SizedBox(height: 26),
            const Text(
              'Curriculum Builder',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BuilderTab(
                    label: 'Curriculum',
                    selected: _selectedTab == 0,
                    onTap: () {
                      setState(() {
                        _selectedTab = 0;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _BuilderTab(
                    label: 'Settings & Pricing',
                    selected: _selectedTab == 1,
                    onTap: () {
                      setState(() {
                        _selectedTab = 1;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedTab == 0) ...[
              for (final module in _modules) ...[
                _ModuleCard(
                  module: module,
                  onAddLesson: () => _addLesson(module),
                  onDeleteLesson: (lesson) {
                    setState(() {
                      module.lessons.remove(lesson);
                    });
                  },
                  onEditLesson: (lesson) => _editLesson(lesson),
                  onDeleteModule: () {
                    if (_modules.length == 1) {
                      _showMessage('At least one module should remain.');
                      return;
                    }
                    setState(() {
                      _modules.remove(module);
                    });
                  },
                ),
                const SizedBox(height: 12),
              ],
              OutlinedButton.icon(
                onPressed: _addModule,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  side: const BorderSide(
                    color: OnboardingScreenLayout.primaryBlue,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Lesson / Module',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE3E6ED)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings & Pricing',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SettingsInfoRow(
                      label: 'Thumbnail',
                      value: _fileName(_thumbnailPath),
                    ),
                    _SettingsInfoRow(
                      label: 'Promo Video',
                      value: _fileName(_promoVideoPath),
                    ),
                    _SettingsInfoRow(
                      label: 'Category',
                      value: _category,
                    ),
                    _SettingsInfoRow(
                      label: 'Price',
                      value: '$_currency ${_priceController.text.trim()}',
                    ),
                    _SettingsInfoRow(
                      label: 'Discount',
                      value: _applyDiscount
                          ? (_couponController.text.trim().isEmpty
                              ? 'Enabled'
                              : _couponController.text.trim())
                          : 'Off',
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD3D9E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: OnboardingScreenLayout.primaryBlue,
          width: 1.4,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BuilderTab extends StatelessWidget {
  const _BuilderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? OnboardingScreenLayout.primaryBlue
                  : const Color(0xFFD7DCE5),
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: selected
                ? OnboardingScreenLayout.primaryBlue
                : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.onAddLesson,
    required this.onDeleteLesson,
    required this.onEditLesson,
    required this.onDeleteModule,
  });

  final _EditableModule module;
  final VoidCallback onAddLesson;
  final ValueChanged<_EditableLesson> onDeleteLesson;
  final ValueChanged<_EditableLesson> onEditLesson;
  final VoidCallback onDeleteModule;

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
          Row(
            children: [
              const Icon(Icons.drag_indicator, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  module.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: OnboardingScreenLayout.primaryBlue,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDeleteModule,
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < module.lessons.length; index++) ...[
            Builder(
              builder: (context) {
                final lesson = module.lessons[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E6EE)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}'.padLeft(2, '0') + '.',
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
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => onEditLesson(lesson),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => onDeleteLesson(lesson),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          OutlinedButton.icon(
            onPressed: onAddLesson,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: const BorderSide(
                color: OnboardingScreenLayout.primaryBlue,
              ),
            ),
            icon: const Icon(Icons.add),
            label: const Text(
              'Add Lesson / Module',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsInfoRow extends StatelessWidget {
  const _SettingsInfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableModule {
  _EditableModule({
    required this.title,
    required this.lessons,
  });

  String title;
  final List<_EditableLesson> lessons;
}

class _EditableLesson {
  _EditableLesson({
    required this.title,
    required this.duration,
    required this.videoPath,
  });

  String title;
  String duration;
  String videoPath;
}

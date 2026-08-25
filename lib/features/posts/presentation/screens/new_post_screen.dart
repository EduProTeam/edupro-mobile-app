import 'package:flutter/material.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  static const _primaryPurple = Color(0xFF5B2CCF);
  static const _pageBackground = Color(0xFFFCFAFF);
  static const _textPrimary = Color(0xFF1F1B2D);
  static const _textSecondary = Color(0xFF6D687A);
  static const _borderColor = Color(0xFFE3DDEA);

  static const _categories = [
    'Programming',
    'Design',
    'Business',
    'Mathematics',
    'Languages',
    'Technology',
    'Career',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedCategory;
  String _visibility = 'Public';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _submitPost() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _showSnackBar('Post publishing coming soon');
  }

  OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _textSecondary),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: _inputBorder(_borderColor),
      enabledBorder: _inputBorder(_borderColor),
      focusedBorder: _inputBorder(_primaryPurple),
      errorBorder: _inputBorder(Colors.red.shade700),
      focusedErrorBorder: _inputBorder(Colors.red.shade700),
    );
  }

  Widget _attachmentButton({required String label, required IconData icon}) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _showSnackBar('$label attachment coming soon'),
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryPurple,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          side: const BorderSide(color: _borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Share your knowledge with the community.',
                  style: TextStyle(fontSize: 16, color: _textSecondary),
                ),
                const SizedBox(height: 24),
                const _FieldLabel(label: 'Title', isRequired: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    hintText: 'Enter a catchy title for your post...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a post title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const _FieldLabel(label: 'Category', isRequired: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: _inputDecoration(hintText: 'Select a category'),
                  hint: const Text('Select a category'),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const _FieldLabel(label: 'Content', isRequired: true),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  minLines: 8,
                  maxLines: 12,
                  keyboardType: TextInputType.multiline,
                  decoration: _inputDecoration(
                    hintText: 'Write your post content here...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter post content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _attachmentButton(
                      label: 'Image',
                      icon: Icons.image_outlined,
                    ),
                    const SizedBox(width: 8),
                    _attachmentButton(
                      label: 'Video',
                      icon: Icons.videocam_outlined,
                    ),
                    const SizedBox(width: 8),
                    _attachmentButton(label: 'File', icon: Icons.attach_file),
                    const SizedBox(width: 8),
                    _attachmentButton(label: 'Link', icon: Icons.link),
                  ],
                ),
                const SizedBox(height: 24),
                const _FieldLabel(label: 'Tags'),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagsController,
                  textInputAction: TextInputAction.done,
                  decoration: _inputDecoration(
                    hintText:
                        'Add tags (e.g., Python, Tutorial, Web Development)',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Press Enter after each tag',
                  style: TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 24),
                const _FieldLabel(label: 'Who can see this?'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _visibility,
                  decoration: _inputDecoration(hintText: 'Select visibility'),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Public',
                      child: Row(
                        children: [
                          Icon(Icons.public_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Public'),
                        ],
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Followers',
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Followers'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _visibility = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  _visibility == 'Public'
                      ? 'Anyone on EduPro can see this post.'
                      : 'Only your followers can see this post.',
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSnackBar('Post saved as draft'),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save as Draft'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textPrimary,
                          minimumSize: const Size.fromHeight(52),
                          side: const BorderSide(color: _borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _submitPost,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Post'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.isRequired = false});

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          color: _NewPostScreenState._textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        children: [
          if (isRequired)
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red.shade700),
            ),
        ],
      ),
    );
  }
}

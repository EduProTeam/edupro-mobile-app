import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/post_service.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key, this.post, this.postService});

  final PublishedPost? post;
  final PostService? postService;

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
  static const _fileExtensions = ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _mediaPicker = ImagePicker();
  late final _postService = widget.postService ?? PostService();
  bool _removeExistingAttachment = false;
  bool get _isEditing => widget.post != null;
  bool get _hasExistingAttachment =>
      _isEditing &&
      widget.post!.attachmentType != 'none' &&
      !_removeExistingAttachment;

  @override
  void initState() {
    super.initState();
    final post = widget.post;
    if (post != null) {
      _titleController.text = post.title;
      _contentController.text = post.content;
      _tagsController.text = post.tags.join(', ');
      _selectedCategory = post.category;
      _visibility = post.visibility == 'followers' ? 'Followers' : 'Public';
    }
  }

  String? _selectedCategory;
  String _visibility = 'Public';
  PostAttachment? _attachment;
  bool _isSubmitting = false;
  bool _isSavingDraft = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  bool _canAddAttachment() {
    if (_isSubmitting) {
      return false;
    }
    if (_attachment != null || _hasExistingAttachment) {
      _showSnackBar('Only one attachment can be added to a post.');
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    if (!_canAddAttachment()) {
      return;
    }

    try {
      final image = await _mediaPicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (image == null) {
        return;
      }

      final file = File(image.path);
      if (!mounted) {
        return;
      }
      setState(() {
        _attachment = PostAttachment(
          type: PostAttachmentType.image,
          file: file,
          name: _fileName(file),
        );
      });
    } catch (_) {
      _showSnackBar('Unable to select the attachment.');
    }
  }

  Future<void> _pickVideo() async {
    if (!_canAddAttachment()) {
      return;
    }

    try {
      final video = await _mediaPicker.pickVideo(source: ImageSource.gallery);
      if (video == null) {
        return;
      }

      final file = File(video.path);
      final sizeBytes = await file.length();
      if (!mounted) {
        return;
      }
      setState(() {
        _attachment = PostAttachment(
          type: PostAttachmentType.video,
          file: file,
          name: _fileName(file),
          sizeBytes: sizeBytes,
        );
      });
    } catch (_) {
      _showSnackBar('Unable to select the attachment.');
    }
  }

  Future<void> _pickFile() async {
    if (!_canAddAttachment()) {
      return;
    }

    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: _fileExtensions,
      );
      if (pickedFile == null) {
        return;
      }

      if (pickedFile.path == null) {
        _showSnackBar('Unable to select the attachment.');
        return;
      }

      final sizeBytes = await pickedFile.length();
      if (!mounted) {
        return;
      }
      setState(() {
        _attachment = PostAttachment(
          type: PostAttachmentType.file,
          file: File(pickedFile.path!),
          name: pickedFile.name,
          sizeBytes: sizeBytes,
        );
      });
    } catch (_) {
      _showSnackBar('Unable to select the attachment.');
    }
  }

  Future<void> _addLink() async {
    if (!_canAddAttachment()) {
      return;
    }

    final controller = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    final link = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Link'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.url,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'https://example.com',
              ),
              validator: (value) {
                if (!_isValidHttpUrl(value ?? '')) {
                  return 'Enter a valid http:// or https:// URL';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              style: FilledButton.styleFrom(backgroundColor: _primaryPurple),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (link == null || !mounted) {
      return;
    }
    setState(() {
      _attachment = PostAttachment(
        type: PostAttachmentType.link,
        name: link,
        linkUrl: link,
      );
    });
  }

  void _removeAttachment() {
    if (_isSubmitting) {
      return;
    }
    setState(() {
      _attachment = null;
    });
  }

  Future<void> _savePost(String status) async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final isDraft = status == 'draft';
    setState(() {
      _isSubmitting = true;
      _isSavingDraft = isDraft;
    });

    try {
      await _postService.savePost(
        postId: widget.post?.id,
        removeAttachment: _removeExistingAttachment,
        title: _titleController.text,
        category: _selectedCategory!,
        content: _contentController.text,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        visibility: _visibility.toLowerCase(),
        status: status,
        attachment: _attachment,
      );
      if (!mounted) {
        return;
      }
      _showSnackBar(
        _isEditing
            ? 'Post updated successfully'
            : isDraft
            ? 'Post saved as draft'
            : 'Post published successfully',
      );
      Navigator.of(context).pop();
    } on PostFailure catch (error) {
      _showSnackBar(error.message);
    } catch (_) {
      _showSnackBar('Unable to save post. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSavingDraft = false;
        });
      }
    }
  }

  String _fileName(File file) {
    final segments = file.uri.pathSegments;
    return segments.isEmpty ? 'attachment' : segments.last;
  }

  bool _isValidHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasAuthority &&
        (uri.scheme == 'https' || uri.scheme == 'http');
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

  Widget _attachmentButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: _isSubmitting ? null : onPressed,
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
    final attachment = _attachment;

    return Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          _isEditing ? 'Edit Post' : 'New Post',
          style: const TextStyle(fontWeight: FontWeight.w700),
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
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 12),
                const _FieldLabel(label: 'Category', isRequired: true),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: _inputDecoration(hintText: 'Select a category'),
                  hint: const Text('Select a category'),
                  items:
                      {
                            ..._categories,
                            ?_selectedCategory,
                          }
                          .map(
                            (category) => DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
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
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _attachmentButton(
                      label: 'Image',
                      icon: Icons.image_outlined,
                      onPressed: _pickImage,
                    ),
                    const SizedBox(width: 8),
                    _attachmentButton(
                      label: 'Video',
                      icon: Icons.videocam_outlined,
                      onPressed: _pickVideo,
                    ),
                    const SizedBox(width: 8),
                    _attachmentButton(
                      label: 'File',
                      icon: Icons.attach_file,
                      onPressed: _pickFile,
                    ),
                    const SizedBox(width: 8),
                    _attachmentButton(
                      label: 'Link',
                      icon: Icons.link,
                      onPressed: _addLink,
                    ),
                  ],
                ),
                if (attachment != null) ...[
                  const SizedBox(height: 16),
                  _SelectedAttachmentPreview(
                    attachment: attachment,
                    onRemove: _isSubmitting ? null : _removeAttachment,
                  ),
                ],
                if (_hasExistingAttachment) ...[
                  const SizedBox(height: 16),
                  if (widget.post!.attachmentType == 'image' &&
                      widget.post!.attachmentUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        widget.post!.attachmentUrl!,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 80,
                          child: Center(child: Text('Image unavailable')),
                        ),
                      ),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.attachment),
                    title: Text(
                      widget.post!.attachmentName ??
                          widget.post!.linkUrl ??
                          'Current attachment',
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove current attachment',
                      onPressed: _isSubmitting
                          ? null
                          : () => setState(() {
                              _removeExistingAttachment = true;
                            }),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const _FieldLabel(label: 'Tags'),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagsController,
                  textInputAction: TextInputAction.done,
                  enabled: !_isSubmitting,
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
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
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
                        onPressed: _isSubmitting
                            ? null
                            : _isEditing
                            ? () => Navigator.of(context).pop()
                            : () => _savePost('draft'),
                        icon: _isSubmitting && _isSavingDraft
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSubmitting && _isSavingDraft
                              ? 'Saving draft...'
                              : _isEditing
                              ? 'Cancel'
                              : 'Save as Draft',
                        ),
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
                        onPressed: _isSubmitting
                            ? null
                            : () => _savePost('published'),
                        icon: _isSubmitting && !_isSavingDraft
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(
                          _isSubmitting && !_isSavingDraft
                              ? 'Saving...'
                              : _isEditing
                              ? 'Save Changes'
                              : 'Post',
                        ),
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

class _SelectedAttachmentPreview extends StatelessWidget {
  const _SelectedAttachmentPreview({
    required this.attachment,
    required this.onRemove,
  });

  final PostAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachment.type == PostAttachmentType.image) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _NewPostScreenState._borderColor),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(attachment.file!, fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: _RemoveAttachmentButton(onPressed: onRemove),
            ),
          ],
        ),
      );
    }

    final isLink = attachment.type == PostAttachmentType.link;
    final icon = switch (attachment.type) {
      PostAttachmentType.video => Icons.videocam_outlined,
      PostAttachmentType.file => Icons.insert_drive_file_outlined,
      PostAttachmentType.link => Icons.link,
      PostAttachmentType.image => Icons.image_outlined,
    };
    final name = isLink ? attachment.linkUrl! : attachment.name ?? 'Attachment';
    final details = isLink
        ? 'Link attachment'
        : attachment.type == PostAttachmentType.file
        ? '${_fileType(attachment.name)} • ${_formatSize(attachment.sizeBytes)}'
        : _formatSize(attachment.sizeBytes);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _NewPostScreenState._borderColor),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EBFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _NewPostScreenState._primaryPurple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _NewPostScreenState._textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _NewPostScreenState._textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _RemoveAttachmentButton(onPressed: onRemove),
        ],
      ),
    );
  }

  static String _fileType(String? name) {
    final extension = name?.split('.').last.toUpperCase();
    return extension == null || extension == name ? 'FILE' : extension;
  }

  static String _formatSize(int? bytes) {
    if (bytes == null) {
      return 'Size unavailable';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _RemoveAttachmentButton extends StatelessWidget {
  const _RemoveAttachmentButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Remove attachment',
      icon: const Icon(Icons.close),
      color: _NewPostScreenState._textPrimary,
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

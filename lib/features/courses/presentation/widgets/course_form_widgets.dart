import 'dart:io';
import 'package:flutter/material.dart';
import '../../../onboarding/presentation/widgets/onboarding_screen_layout.dart';
import '../../models/course_draft.dart';

enum UploadStatus { selected, uploading, uploaded, failed }

class CourseFileSelection {
  CourseFileSelection.local(this.localPath)
    : media = null,
      status = UploadStatus.selected;
  CourseFileSelection.stored(this.media)
    : localPath = null,
      status = UploadStatus.uploaded;
  final String? localPath;
  CourseMedia? media;
  UploadStatus status;
  String get name =>
      media?.name ?? localPath!.replaceAll('\\', '/').split('/').last;
}

class CourseFormCard extends StatelessWidget {
  const CourseFormCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE3E6ED)),
    ),
    child: child,
  );
}

class CourseField extends StatelessWidget {
  const CourseField({
    super.key,
    required this.label,
    required this.child,
    this.requiredField = false,
  });
  final String label;
  final Widget child;
  final bool requiredField;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            children: [
              if (requiredField)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

InputDecoration courseInput(String hint) => InputDecoration(
  hintText: hint,
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.all(16),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
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
  errorMaxLines: 3,
);

class CourseUploadField extends StatelessWidget {
  const CourseUploadField({
    super.key,
    required this.label,
    required this.onPick,
    this.selection,
    this.onRemove,
    this.onRetry,
    this.error,
    this.image = false,
  });
  final String label;
  final CourseFileSelection? selection;
  final VoidCallback? onPick, onRemove, onRetry;
  final String? error;
  final bool image;
  @override
  Widget build(BuildContext context) {
    final file = selection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: error == null ? const Color(0xFFD3D9E3) : Colors.redAccent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (image && file != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: file.localPath != null
                          ? Image.file(
                              File(file.localPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image_outlined),
                            )
                          : Image.network(
                              file.media!.url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.image_outlined),
                            ),
                    ),
                  ),
                ),
              if (file != null) ...[
                Text(
                  file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  switch (file.status) {
                    UploadStatus.selected => 'Selected · uploads when you save',
                    UploadStatus.uploading => 'Uploading…',
                    UploadStatus.uploaded => '✓ Uploaded',
                    UploadStatus.failed =>
                      'Upload failed. Retry or replace this file.',
                  },
                  style: TextStyle(
                    fontSize: 13,
                    color: file.status == UploadStatus.failed
                        ? Colors.red.shade700
                        : Colors.black54,
                  ),
                ),
                if (file.status == UploadStatus.uploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
              ],
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: onPick,
                    icon: Icon(
                      image ? Icons.image_outlined : Icons.attach_file,
                    ),
                    label: Text(file == null ? label : 'Replace'),
                  ),
                  if (file != null && onRemove != null)
                    TextButton(
                      onPressed: onRemove,
                      child: const Text('Remove'),
                    ),
                  if (file?.status == UploadStatus.failed)
                    TextButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

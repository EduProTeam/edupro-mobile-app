import 'package:flutter/material.dart';
import 'package:edupro_mobile_app/core/theme/app_colors.dart';

import '../../services/post_service.dart';

/// Loads this account's bookmark state. The parent keys it by account and post.
class PostBookmarkButton extends StatefulWidget {
  const PostBookmarkButton({
    super.key,
    required this.postId,
    this.showLabel = false,
  });
  final String postId;
  final bool showLabel;

  @override
  State<PostBookmarkButton> createState() => _PostBookmarkButtonState();
}

class _PostBookmarkButtonState extends State<PostBookmarkButton> {
  final _service = PostService();
  late Stream<bool> _saved = _service.watchPostSaved(widget.postId);

  @override
  Widget build(BuildContext context) => StreamBuilder<bool>(
    stream: _saved,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return IconButton(
          tooltip: 'Retry saved status',
          onPressed: () =>
              setState(() => _saved = _service.watchPostSaved(widget.postId)),
          icon: const Icon(Icons.bookmark_border),
        );
      }
      if (!snapshot.hasData) {
        return const IconButton(
          tooltip: 'Loading saved status',
          onPressed: null,
          icon: Icon(Icons.bookmark_border),
        );
      }
      return PostSaveButton(
        showLabel: widget.showLabel,
        isSaved: snapshot.data!,
        onSave: (saved) => _service.setPostSaved(widget.postId, saved: saved),
      );
    },
  );
}

class PostSaveButton extends StatefulWidget {
  const PostSaveButton({
    super.key,
    required this.isSaved,
    required this.onSave,
    this.showLabel = false,
  });
  final bool isSaved;
  final Future<void> Function(bool saved) onSave;
  final bool showLabel;

  @override
  State<PostSaveButton> createState() => _PostSaveButtonState();
}

class _PostSaveButtonState extends State<PostSaveButton> {
  bool _saving = false;
  bool? _pending;

  @override
  void didUpdateWidget(covariant PostSaveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_saving && widget.isSaved == _pending) _pending = null;
  }

  Future<void> _toggle() async {
    if (_saving) return;
    final messenger = ScaffoldMessenger.of(context);
    final previous = _pending ?? widget.isSaved;
    final saved = !previous;
    setState(() {
      _saving = true;
      _pending = saved;
    });
    try {
      await widget.onSave(saved);
      if (mounted && widget.isSaved == saved) setState(() => _pending = null);
      if (!messenger.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              saved
                  ? 'Post saved. Find it in Profile → Saved.'
                  : 'Post removed from Saved.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    } catch (error) {
      if (mounted) {
        setState(() => _pending = widget.isSaved == previous ? null : previous);
      }
      // A rejected delete may restore a Saved tile after it has unmounted.
      if (!messenger.mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error is PostFailure
                  ? error.message
                  : 'Unable to update saved post. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = _pending ?? widget.isSaved;
    final icon = Icon(
      saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      color: saved
          ? context.appColors.primary
          : context.appColors.textSecondary,
      size: 22,
    );
    final tooltip = saved ? 'Remove from saved posts' : 'Save post';
    return Semantics(
      toggled: saved,
      child: widget.showLabel
          ? Tooltip(
              message: tooltip,
              child: TextButton.icon(
                onPressed: _saving ? null : _toggle,
                icon: icon,
                label: Text(saved ? 'Saved' : 'Save'),
                style: TextButton.styleFrom(
                  foregroundColor: saved
                      ? context.appColors.primary
                      : context.appColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 44),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(fontSize: 11),
                ),
              ),
            )
          : IconButton(
              tooltip: tooltip,
              onPressed: _saving ? null : _toggle,
              icon: icon,
            ),
    );
  }
}

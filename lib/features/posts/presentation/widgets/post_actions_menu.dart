import 'package:flutter/material.dart';

import '../../services/post_service.dart';

class PostActionsMenu extends StatelessWidget {
  const PostActionsMenu({
    super.key,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isOwner;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    if (!isOwner) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Post options',
      icon: const Icon(Icons.more_horiz, color: Color(0xFF1E1E1E)),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit post')),
        PopupMenuItem(value: 'delete', child: Text('Delete post')),
      ],
      onSelected: (action) async {
        if (action == 'edit') {
          onEdit();
          return;
        }
        final deleted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _DeletePostDialog(onDelete: onDelete),
        );
        if (context.mounted && deleted == true) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Post deleted')));
        }
      },
    );
  }
}

class _DeletePostDialog extends StatefulWidget {
  const _DeletePostDialog({required this.onDelete});

  final Future<void> Function() onDelete;

  @override
  State<_DeletePostDialog> createState() => _DeletePostDialogState();
}

class _DeletePostDialogState extends State<_DeletePostDialog> {
  bool _deleting = false;
  String? _error;

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _error = null;
    });
    try {
      await widget.onDelete();
      if (mounted) {
        setState(() => _deleting = false);
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _deleting = false;
          _error = error is PostFailure
              ? error.message
              : 'Unable to delete post. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_deleting,
      child: AlertDialog(
        title: const Text('Delete post?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This post and its comments will no longer be visible in the feed.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _deleting ? null : () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _deleting ? null : _delete,
            child: Text(_deleting ? 'Deleting…' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

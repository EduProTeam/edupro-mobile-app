import 'package:flutter/material.dart';

import '../../models/post_comment.dart';
import '../../services/post_service.dart';

class PostCommentsSheet extends StatefulWidget {
  const PostCommentsSheet({
    super.key,
    required this.watchComments,
    required this.onSubmit,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  final Stream<List<PostComment>> Function() watchComments;
  final Future<void> Function(String text) onSubmit;
  final String? currentUserId;
  final Future<void> Function(String commentId, String text)? onEdit;
  final Future<void> Function(String commentId)? onDelete;

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final _text = TextEditingController();
  late Stream<List<PostComment>> _comments = widget.watchComments();
  bool _sending = false;
  bool _deleting = false;
  String? _error;
  String? _editingId;
  String _newCommentDraft = '';

  Future<void> _delete(PostComment comment) async {
    if (_sending ||
        widget.onDelete == null ||
        widget.currentUserId == null ||
        comment.userId != widget.currentUserId) {
      return;
    }
    setState(() {
      _sending = true;
      _deleting = true;
      _error = null;
    });
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete comment?'),
          content: const Text('This will permanently remove your comment.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await widget.onDelete!(comment.id);
      if (mounted && _editingId == comment.id) _finishEditing();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is PostFailure
              ? error.message
              : 'Unable to delete comment. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _deleting = false;
        });
      }
    }
  }

  void _edit(PostComment comment) {
    if (_sending ||
        widget.onEdit == null ||
        widget.currentUserId == null ||
        comment.userId != widget.currentUserId) {
      return;
    }
    setState(() {
      if (_editingId == null) _newCommentDraft = _text.text;
      _editingId = comment.id;
      _text.text = comment.text;
      _error = null;
    });
  }

  void _finishEditing() {
    _editingId = null;
    _text.text = _newCommentDraft;
    _newCommentDraft = '';
    _error = null;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (_sending || text.isEmpty) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (_editingId != null) {
        await widget.onEdit!(_editingId!, text);
        if (mounted) _finishEditing();
      } else {
        await widget.onSubmit(text);
        if (mounted) _text.clear();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is PostFailure
              ? error.message
              : 'Unable to save comment. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close comments',
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<PostComment>>(
                  stream: _comments,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Unable to load comments.'),
                            TextButton(
                              onPressed: () => setState(() {
                                _comments = widget.watchComments();
                              }),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return const Center(
                        child: Text('No comments yet. Start the conversation!'),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final photo = comment.profileImageUrl;
                        const fallback = CircleAvatar(
                          backgroundColor: Color(0xFFF7F4FF),
                          child: Icon(
                            Icons.person_outline,
                            color: Color(0xFF5B2CCF),
                          ),
                        );
                        return ListTile(
                          trailing:
                              widget.currentUserId != null &&
                                  comment.userId == widget.currentUserId &&
                                  (widget.onEdit != null ||
                                      widget.onDelete != null)
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.onEdit != null)
                                      IconButton(
                                        tooltip: 'Edit comment',
                                        onPressed: _sending
                                            ? null
                                            : () => _edit(comment),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 20,
                                        ),
                                      ),
                                    if (widget.onDelete != null)
                                      IconButton(
                                        tooltip: 'Delete comment',
                                        onPressed: _sending
                                            ? null
                                            : () => _delete(comment),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                      ),
                                  ],
                                )
                              : null,
                          isThreeLine: false,
                          leading: photo == null || photo.isEmpty
                              ? fallback
                              : ClipOval(
                                  child: Image.network(
                                    photo,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => fallback,
                                  ),
                                ),
                          title: Text(
                            comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${comment.text}${comment.updatedAt != null ? ' (edited)' : ''}',
                              style: const TextStyle(
                                color: Color(0xFF1E1E1E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              if (_editingId != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Editing your comment')),
                      TextButton(
                        onPressed: _sending
                            ? null
                            : () => setState(_finishEditing),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        enabled: !_sending,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          hintText: _editingId == null
                              ? 'Add a comment…'
                              : 'Edit your comment…',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      tooltip: _editingId == null
                          ? 'Send comment'
                          : 'Save comment',
                      onPressed: _sending || _text.text.trim().isEmpty
                          ? null
                          : _send,
                      color: const Color(0xFF5B2CCF),
                      icon: _sending && !_deleting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
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
}

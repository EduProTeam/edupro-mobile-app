import 'package:flutter/material.dart';

import '../../models/post_comment.dart';
import '../../services/post_service.dart';

class PostCommentsSheet extends StatefulWidget {
  const PostCommentsSheet({
    super.key,
    required this.watchComments,
    required this.onSubmit,
  });

  final Stream<List<PostComment>> Function() watchComments;
  final Future<void> Function(String text) onSubmit;

  @override
  State<PostCommentsSheet> createState() => _PostCommentsSheetState();
}

class _PostCommentsSheetState extends State<PostCommentsSheet> {
  final _text = TextEditingController();
  late Stream<List<PostComment>> _comments = widget.watchComments();
  bool _sending = false;
  String? _error;

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
      await widget.onSubmit(text);
      if (mounted) _text.clear();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is PostFailure
              ? error.message
              : 'Unable to send comment. Please try again.';
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
                              comment.text,
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
                        decoration: const InputDecoration(
                          hintText: 'Add a comment…',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Send comment',
                      onPressed: _sending || _text.text.trim().isEmpty
                          ? null
                          : _send,
                      color: const Color(0xFF5B2CCF),
                      icon: _sending
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

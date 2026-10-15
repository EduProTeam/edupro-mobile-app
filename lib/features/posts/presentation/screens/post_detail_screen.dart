import 'package:flutter/material.dart';
import 'package:edupro_mobile_app/core/theme/app_colors.dart';

import '../../services/post_service.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({
    super.key,
    required PublishedPost this.post,
    this.readOnly = false,
    this.publicOnly = false,
    this.postService,
  }) : postId = null;

  const PostDetailScreen.fromId({
    super.key,
    required String this.postId,
    this.readOnly = false,
    this.publicOnly = true,
    this.postService,
  }) : post = null;

  final PublishedPost? post;
  final String? postId;
  final bool readOnly;
  final bool publicOnly;
  final PostService? postService;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late final _service = widget.postService ?? PostService();
  String get _postId => widget.postId ?? widget.post!.id;
  late Stream<PublishedPost?> _post = _service.watchPublishedPost(_postId);

  @override
  void didUpdateWidget(covariant PostDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_postId != (oldWidget.postId ?? oldWidget.post!.id)) {
      _post = _service.watchPublishedPost(_postId);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColors.background,
    appBar: AppBar(
      title: const Text('Educational Post'),
      backgroundColor: context.appColors.surface,
      surfaceTintColor: context.appColors.surface,
    ),
    body: StreamBuilder<PublishedPost?>(
      key: ValueKey(_postId),
      stream: _post,
      initialData: widget.post,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load this post.'),
                TextButton(
                  onPressed: () => setState(
                    () => _post = _service.watchPublishedPost(_postId),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData ||
            ((widget.publicOnly || widget.readOnly) &&
                snapshot.data!.visibility != 'public')) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This post is no longer available.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: PostCard(
                post: snapshot.data!,
                showFullContent: true,
                readOnly: widget.readOnly,
              ),
            ),
          ),
        );
      },
    ),
  );
}

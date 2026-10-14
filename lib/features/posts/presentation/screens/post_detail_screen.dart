import 'package:flutter/material.dart';

import '../../services/post_service.dart';
import '../widgets/post_card.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});
  final PublishedPost post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _service = PostService();
  late Stream<PublishedPost?> _post = _service.watchPublishedPost(
    widget.post.id,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9FC),
    appBar: AppBar(
      title: const Text('Educational Post'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
    ),
    body: StreamBuilder<PublishedPost?>(
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
                    () => _post = _service.watchPublishedPost(widget.post.id),
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
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
              child: PostCard(post: snapshot.data!, showFullContent: true),
            ),
          ),
        );
      },
    ),
  );
}

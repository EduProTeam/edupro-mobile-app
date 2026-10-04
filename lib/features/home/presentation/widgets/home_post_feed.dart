import 'package:flutter/material.dart';

import '../../../posts/models/post_categories.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../../posts/services/post_service.dart';

class HomePostFeed extends StatefulWidget {
  const HomePostFeed({
    super.key,
    required this.postsStream,
    required this.onRefresh,
    required this.onRetry,
  });

  final Stream<List<PublishedPost>> postsStream;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;

  @override
  State<HomePostFeed> createState() => _HomePostFeedState();
}

class _HomePostFeedState extends State<HomePostFeed> {
  static const _primaryPurple = Color(0xFF5B2CCF);
  String _selectedCategory = allPostsCategory;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              for (final category in [allPostsCategory, ...postCategories])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    selectedColor: _primaryPurple,
                    backgroundColor: const Color(0xFFF7F4FF),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _selectedCategory == category
                          ? Colors.white
                          : _primaryPurple,
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(color: Color(0xFFE3DDEA)),
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<PublishedPost>>(
            stream: widget.postsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('Published posts feed error: ${snapshot.error}');
                return _FeedMessage(
                  message: 'Unable to load posts.',
                  actionLabel: 'Try again',
                  onAction: widget.onRetry,
                  onRefresh: widget.onRefresh,
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _FeedLoading();
              }

              final allPosts = snapshot.data ?? const <PublishedPost>[];
              final posts = _selectedCategory == allPostsCategory
                  ? allPosts
                  : allPosts
                        .where((post) => post.category == _selectedCategory)
                        .toList(growable: false);
              if (posts.isEmpty) {
                return _FeedMessage(
                  message: _selectedCategory == allPostsCategory
                      ? 'No posts yet'
                      : 'No posts in $_selectedCategory yet',
                  detail: allPosts.isEmpty
                      ? 'Be the first to share something with the EduPro community.'
                      : 'Select another category to see more posts.',
                  onRefresh: widget.onRefresh,
                );
              }

              return RefreshIndicator(
                onRefresh: widget.onRefresh,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
                  itemCount: posts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Educational Posts',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      );
                    }

                    final post = posts[index - 1];
                    return Padding(
                      key: ValueKey(post.id),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PostCard(post: post),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
      children: const [
        Text(
          'Educational Posts',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 96),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 14),
        Center(child: Text('Loading posts...')),
      ],
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.message,
    required this.onRefresh,
    this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 104),
        children: [
          const Text(
            'Educational Posts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 96),
          Center(
            child: Column(
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
                if (actionLabel != null) ...[
                  const SizedBox(height: 14),
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

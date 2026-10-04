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
  final _searchController = TextEditingController();
  String _selectedCategory = allPostsCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PublishedPost> _filterPosts(List<PublishedPost> posts) {
    final keyword = _searchQuery.trim().toLowerCase();
    return posts
        .where((post) {
          final matchesCategory =
              _selectedCategory == allPostsCategory ||
              post.category == _selectedCategory;
          final matchesSearch =
              keyword.isEmpty ||
              post.title.toLowerCase().contains(keyword) ||
              post.content.toLowerCase().contains(keyword);
          return matchesCategory && matchesSearch;
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PublishedPost>>(
      stream: widget.postsStream,
      builder: (context, snapshot) {
        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverFloatingHeader(
                snapMode: FloatingHeaderSnapMode.scroll,
                animationStyle: const AnimationStyle(
                  duration: Duration(milliseconds: 160),
                  reverseDuration: Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeOutCubic,
                ),
                child: Material(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: _buildFilters(),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Educational Posts',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                sliver: _buildFeedSliver(snapshot),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            style: const TextStyle(color: Color(0xFF1F1B2D)),
            decoration: InputDecoration(
              hintText: 'Search posts...',
              hintStyle: const TextStyle(color: Color(0xFF6D687A)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: const Icon(Icons.search, color: _primaryPurple),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, color: _primaryPurple),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3DDEA)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE3DDEA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _primaryPurple),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
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
      ],
    );
  }

  Widget _buildFeedSliver(AsyncSnapshot<List<PublishedPost>> snapshot) {
    if (snapshot.hasError) {
      debugPrint('Published posts feed error: ${snapshot.error}');
      return SliverToBoxAdapter(
        child: _FeedMessage(
          message: 'Unable to load posts.',
          actionLabel: 'Try again',
          onAction: widget.onRetry,
        ),
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverToBoxAdapter(child: _FeedLoading());
    }

    final posts = _filterPosts(snapshot.data ?? const <PublishedPost>[]);
    if (posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: _FeedMessage(message: 'No posts found'),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 16),
      sliver: SliverList.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Padding(
            key: ValueKey(post.id),
            padding: const EdgeInsets.only(bottom: 16),
            child: PostCard(post: post),
          );
        },
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 96),
        Center(child: CircularProgressIndicator()),
        SizedBox(height: 14),
        Center(child: Text('Loading posts...')),
      ],
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              if (actionLabel != null) ...[
                const SizedBox(height: 14),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../posts/models/post_categories.dart';
import '../../../posts/presentation/widgets/post_card.dart';
import '../../../posts/services/post_service.dart';
import '../../models/home_feed_filter.dart';
import 'home_community_widgets.dart';

class HomePostFeed extends StatefulWidget {
  const HomePostFeed({
    super.key,
    required this.postsStream,
    required this.onRefresh,
    required this.onRetry,
    this.userName = 'Learner',
    this.userImageUrl,
    this.onCreatePost,
    this.onOpenProfile,
    this.onOpenSaved,
    this.onOpenPost,
  });

  final Stream<List<PublishedPost>> postsStream;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final String userName;
  final String? userImageUrl;
  final ValueChanged<PostAttachmentType?>? onCreatePost;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSaved;
  final ValueChanged<PublishedPost>? onOpenPost;

  @override
  State<HomePostFeed> createState() => _HomePostFeedState();
}

class _HomePostFeedState extends State<HomePostFeed> {
  static const _blue = Color(0xFF167BFF);
  static const _background = Color(0xFFF8FAFD);
  final _searchController = TextEditingController();
  String _selectedCategory = allPostsCategory;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() {
      _selectedCategory = allPostsCategory;
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _background,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: StreamBuilder<List<PublishedPost>>(
          stream: widget.postsStream,
          builder: (context, snapshot) => RefreshIndicator(
            onRefresh: widget.onRefresh,
            color: _blue,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                _floatingControls(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 12, 0),
                    child: HomeFeedHeader(
                      search: _buildSearch(),
                      userName: widget.userName,
                      imageUrl: widget.userImageUrl,
                      onProfile: widget.onOpenProfile,
                      onSaved: widget.onOpenSaved,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: HomeLearningBanner(),
                  ),
                ),
                _floatingControls(child: _buildCategories()),
                if (widget.onCreatePost != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                    sliver: SliverToBoxAdapter(
                      child: HomePostComposer(
                        userName: widget.userName,
                        imageUrl: widget.userImageUrl,
                        onCreate: widget.onCreatePost!,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Educational Posts',
                            style: TextStyle(
                              color: Color(0xFF0A1638),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Text(
                          'Newest first',
                          style: const TextStyle(
                            color: Color(0xFF7A879D),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: _buildFeedSliver(snapshot),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildSearch() => SizedBox(
    height: MediaQuery.textScalerOf(context).scale(12) * 1.4 + 32,
    child: TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: Color(0xFF243753), fontSize: 12),
      decoration: InputDecoration(
        hintText: 'Search posts...',
        hintStyle: const TextStyle(color: Color(0xFF7B879D), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF0F4FA),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 13,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF62738E),
          size: 21,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 40,
        ),
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close, color: _blue, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: _blue),
        ),
      ),
      onChanged: (value) => setState(() => _searchQuery = value),
    ),
  );

  Widget _floatingControls({required Widget child}) => SliverFloatingHeader(
    // Let both rows occupy layout space when floating, keeping categories
    // directly below the header after the banner has scrolled out of view.
    snapMode: FloatingHeaderSnapMode.scroll,
    animationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 160),
      reverseDuration: Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    ),
    child: Material(color: _background, child: child),
  );

  Widget _buildCategories() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
    child: Row(
      children: [
        for (final category in [allPostsCategory, ...postCategories])
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChoiceChip(
              label: Text(category),
              selected: _selectedCategory == category,
              selectedColor: const Color(0xFFE3F0FF),
              backgroundColor: Colors.white,
              checkmarkColor: _blue,
              labelStyle: TextStyle(
                color: _selectedCategory == category
                    ? _blue
                    : const Color(0xFF62738E),
                fontSize: 11,
                fontWeight: _selectedCategory == category
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
              side: BorderSide(
                color: _selectedCategory == category
                    ? const Color(0xFFA8CEFF)
                    : const Color(0xFFE8EDF5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              onSelected: (_) => setState(() => _selectedCategory = category),
            ),
          ),
      ],
    ),
  );

  Widget _buildFeedSliver(AsyncSnapshot<List<PublishedPost>> snapshot) {
    if (snapshot.hasError) {
      debugPrint('Published posts feed error: ${snapshot.error}');
      return SliverToBoxAdapter(
        child: _FeedMessage(
          message: 'Unable to load posts.',
          detail: 'Check your connection and try again.',
          actionLabel: 'Try again',
          onAction: widget.onRetry,
        ),
      );
    }
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SliverToBoxAdapter(child: _FeedLoading());
    }
    final posts = filterHomePosts(
      snapshot.data ?? [],
      query: _searchQuery,
      category: _selectedCategory,
    );
    if (posts.isEmpty) {
      final filtered =
          _searchQuery.isNotEmpty || _selectedCategory != allPostsCategory;
      return SliverToBoxAdapter(
        child: _FeedMessage(
          message: 'No posts found',
          detail: 'Try another topic or share the first post.',
          actionLabel: filtered ? 'Reset filters' : null,
          onAction: filtered ? _resetFilters : null,
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 12),
      sliver: SliverList.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return Padding(
            key: ValueKey(post.id),
            padding: const EdgeInsets.only(bottom: 14),
            child: PostCard(
              post: post,
              onOpen: widget.onOpenPost == null
                  ? null
                  : () => widget.onOpenPost!(post),
            ),
          );
        },
      ),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        CircularProgressIndicator(color: Color(0xFF167BFF)),
        SizedBox(height: 14),
        Text('Loading posts...', style: TextStyle(color: Color(0xFF727D95))),
      ],
    ),
  );
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.message,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
    child: Column(
      children: [
        const Icon(
          Icons.auto_stories_outlined,
          color: Color(0xFF92AED4),
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF0A1638),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF727D95),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

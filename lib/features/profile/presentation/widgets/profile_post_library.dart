import 'package:flutter/material.dart';

import '../../../posts/presentation/screens/new_post_screen.dart';
import '../../../posts/presentation/screens/post_detail_screen.dart';
import '../../../posts/presentation/widgets/post_save_button.dart';
import '../../../posts/services/post_service.dart';

class ProfilePostLibrary extends StatefulWidget {
  const ProfilePostLibrary({
    super.key,
    this.postService,
    this.onOpenPost,
    this.onCreatePost,
    this.initialTab = 0,
  }) : assert(initialTab == 0 || initialTab == 1);
  final PostService? postService;
  final ValueChanged<PublishedPost>? onOpenPost;
  final VoidCallback? onCreatePost;
  final int initialTab;

  @override
  State<ProfilePostLibrary> createState() => _ProfilePostLibraryState();
}

class _ProfilePostLibraryState extends State<ProfilePostLibrary> {
  static const _blue = Color(0xFF167BFF);
  late final _service = widget.postService ?? PostService();
  late Stream<List<PublishedPost>> _posts = _selected == 0
      ? _service.watchMyPosts()
      : _service.watchSavedPosts();
  late int _selected = widget.initialTab;
  var _revision = 0;
  var _visibleCount = 12;

  void _reload() {
    _posts = _selected == 0
        ? _service.watchMyPosts()
        : _service.watchSavedPosts();
    _revision++;
    _visibleCount = 12;
  }

  void _select(int index) {
    if (_selected == index) return;
    setState(() {
      _selected = index;
      _reload();
    });
  }

  void _open(PublishedPost post) {
    if (widget.onOpenPost != null) {
      widget.onOpenPost!(post);
    } else {
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE8ECF3))),
        ),
        child: Row(
          children: [
            _LibraryTab(
              label: 'Posts',
              icon: Icons.grid_on_rounded,
              selected: _selected == 0,
              onTap: () => _select(0),
            ),
            _LibraryTab(
              label: 'Saved',
              icon: Icons.bookmark_border_rounded,
              selected: _selected == 1,
              onTap: () => _select(1),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      StreamBuilder<List<PublishedPost>>(
        key: ValueKey('$_selected:$_revision'),
        stream: _posts,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _LibraryMessage(
              icon: Icons.cloud_off_outlined,
              title: _selected == 0
                  ? 'Could not load your posts'
                  : 'Could not load saved posts',
              message: 'Check your connection and try again.',
              action: 'Try again',
              onAction: () => setState(_reload),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: _blue)),
            );
          }
          final posts = snapshot.data!;
          if (posts.isEmpty) {
            return _LibraryMessage(
              icon: _selected == 0
                  ? Icons.post_add_rounded
                  : Icons.bookmark_add_outlined,
              title: _selected == 0
                  ? 'Share your first post'
                  : 'Keep something for later',
              message: _selected == 0
                  ? 'Your published educational posts will appear here.'
                  : 'Tap the bookmark on an educational post to save it here. Only you can see this collection.',
              action: _selected == 0 ? 'Create a post' : null,
              onAction: _selected == 0
                  ? widget.onCreatePost ??
                        () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const NewPostScreen(),
                            ),
                          );
                        }
                  : null,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _selected == 0
                    ? '${posts.length} ${posts.length == 1 ? 'post' : 'posts'} · Published by you'
                    : '${posts.length} saved ${posts.length == 1 ? 'post' : 'posts'} · Only you',
                style: const TextStyle(color: Color(0xFF72778F), fontSize: 12),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(12) > 18;
                  final columns = largeText || constraints.maxWidth < 280
                      ? 1
                      : constraints.maxWidth >= 540
                      ? 3
                      : 2;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: posts.length.clamp(0, _visibleCount),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: largeText ? 0.95 : 0.90,
                    ),
                    itemBuilder: (context, index) => _PostPreview(
                      key: ValueKey('profile-post-${posts[index].id}'),
                      post: posts[index],
                      saved: _selected == 1,
                      onSave: (saved) =>
                          _service.setPostSaved(posts[index].id, saved: saved),
                      onTap: () => _open(posts[index]),
                    ),
                  );
                },
              ),
              if (posts.length > _visibleCount) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _visibleCount += 12),
                  icon: const Icon(Icons.expand_more),
                  label: const Text('Show more posts'),
                ),
              ],
            ],
          );
        },
      ),
    ],
  );
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected
                          ? const Color(0xFF167BFF)
                          : const Color(0xFF858A9B),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF167BFF)
                              : const Color(0xFF72778F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 3,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF167BFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LibraryMessage extends StatelessWidget {
  const _LibraryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F9FF),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF167BFF), size: 34),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF090D31),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF72778F),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onAction,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF167BFF),
            ),
            child: Text(action!),
          ),
        ],
      ],
    ),
  );
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({
    super.key,
    required this.post,
    required this.saved,
    required this.onTap,
    required this.onSave,
  });
  final PublishedPost post;
  final bool saved;
  final VoidCallback onTap;
  final Future<void> Function(bool) onSave;

  @override
  Widget build(BuildContext context) {
    final icon = switch (post.attachmentType) {
      'video' => Icons.play_circle_outline_rounded,
      'file' => Icons.description_outlined,
      'link' => Icons.link_rounded,
      _ => Icons.article_outlined,
    };
    final fallback = DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE8F2FF), Color(0xFFF3EDFF)],
        ),
      ),
      child: Center(
        child: Icon(icon, size: 36, color: const Color(0xFF5B72C5)),
      ),
    );
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE8ECF3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (post.attachmentType == 'image' &&
                      post.attachmentUrl != null)
                    Image.network(
                      post.attachmentUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => fallback,
                    )
                  else
                    fallback,
                  if (saved)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: PostSaveButton(isSaved: true, onSave: onSave),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF167BFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF090D31),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

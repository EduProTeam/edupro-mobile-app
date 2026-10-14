import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/post_service.dart';
import '../screens/new_post_screen.dart';
import 'post_actions_menu.dart';
import 'post_like_button.dart';
import 'post_comments_sheet.dart';
import 'post_save_button.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.showFullContent = false,
    this.onOpen,
  });

  static const _primaryBlue = Color(0xFF167BFF);
  static const _textPrimary = Color(0xFF0A1638);
  static const _textSecondary = Color(0xFF727D95);
  static const _borderColor = Color(0xFFF0F3F8);
  static const _attachmentBackground = Color(0xFFEEF5FF);

  final PublishedPost post;
  final bool showFullContent;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final attachment = _attachmentPreview();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1C3A62),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PostAuthorAvatar(
                key: ValueKey(post.userId ?? post.id),
                userId: post.userId,
                savedImageUrl: post.userProfileImage,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${post.category} • ${_relativeTime(post.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                initialData: FirebaseAuth.instance.currentUser,
                builder: (context, snapshot) {
                  if (snapshot.data == null ||
                      snapshot.data!.uid != post.userId) {
                    return const SizedBox.shrink();
                  }
                  return PostActionsMenu(
                    isOwner: true,
                    onDelete: () => PostService().deletePost(post.id),
                    onEdit: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NewPostScreen(post: post),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(6),
            child: Text(
              post.title,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.content,
              maxLines: showFullContent ? null : 3,
              overflow: showFullContent
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (!showFullContent && onOpen != null && post.content.length > 150)
            TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                foregroundColor: _primaryBlue,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Read more'),
            ),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags.take(3).map(_TagChip.new).toList(),
            ),
          ],
          if (attachment != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(12),
              child: attachment,
            ),
          ],
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final labels =
                  constraints.maxWidth >= 300 &&
                  MediaQuery.textScalerOf(context).scale(12) < 17;
              return Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                runSpacing: 4,
                children: [
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    initialData: FirebaseAuth.instance.currentUser,
                    builder: (context, snapshot) => PostLikeButton(
                      key: ValueKey('${post.id}:${snapshot.data?.uid}'),
                      likeCount: post.likeCount,
                      thumbUpStyle: true,
                      isLiked: post.likedBy.contains(snapshot.data?.uid),
                      onLike: (liked) =>
                          PostService().setPostLiked(post.id, liked: liked),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'View comments',
                        icon: const Icon(
                          Icons.chat_bubble_outline,
                          color: _textSecondary,
                        ),
                        onPressed: () {
                          final service = PostService();
                          showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            builder: (_) => StreamBuilder<User?>(
                              stream: FirebaseAuth.instance.authStateChanges(),
                              initialData: FirebaseAuth.instance.currentUser,
                              builder: (context, snapshot) => PostCommentsSheet(
                                key: ValueKey(snapshot.data?.uid),
                                currentUserId: snapshot.data?.uid,
                                watchComments: () =>
                                    service.watchComments(post.id),
                                onSubmit: (text) =>
                                    service.addComment(post.id, text),
                                onEdit: (id, text) =>
                                    service.editComment(post.id, id, text),
                                onDelete: (id) =>
                                    service.deleteComment(post.id, id),
                              ),
                            ),
                          );
                        },
                      ),
                      Text(
                        '${post.commentCount}',
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    initialData: FirebaseAuth.instance.currentUser,
                    builder: (context, snapshot) => snapshot.data == null
                        ? PostSaveButton(
                            showLabel: labels,
                            isSaved: false,
                            onSave: (saved) => PostService().setPostSaved(
                              post.id,
                              saved: saved,
                            ),
                          )
                        : PostBookmarkButton(
                            showLabel: labels,
                            key: ValueKey('${post.id}:${snapshot.data!.uid}'),
                            postId: post.id,
                          ),
                  ),
                  if (labels)
                    TextButton.icon(
                      onPressed: () => _share(context),
                      icon: const Icon(Icons.share_outlined, size: 21),
                      label: const Text('Share'),
                      style: TextButton.styleFrom(
                        foregroundColor: _textSecondary,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 44),
                        textStyle: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(fontSize: 11),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Copy post to share',
                      onPressed: () => _share(context),
                      icon: const Icon(
                        Icons.share_outlined,
                        color: _textSecondary,
                        size: 22,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final text = [
      post.title,
      post.content,
      if (post.linkUrl != null) post.linkUrl!,
      if (post.tags.isNotEmpty)
        post.tags.map((tag) => tag.startsWith('#') ? tag : '#$tag').join(' '),
    ].where((value) => value.isNotEmpty).join('\n\n');
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Post copied. You can paste it to share.'),
          ),
        );
      }
    } catch (_) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Unable to copy this post. Please try again.'),
          ),
        );
      }
    }
  }

  Widget? _attachmentPreview() {
    final attachmentUrl = post.attachmentUrl;

    return switch (post.attachmentType) {
      'image' when attachmentUrl != null => _ImageAttachment(
        url: attachmentUrl,
      ),
      'video' when attachmentUrl != null || post.attachmentName != null =>
        _VideoAttachment(name: post.attachmentName),
      'file' when attachmentUrl != null || post.attachmentName != null =>
        _FileAttachment(name: post.attachmentName),
      'link' when (post.linkUrl ?? attachmentUrl) != null => _LinkAttachment(
        url: post.linkUrl ?? attachmentUrl!,
      ),
      _ => null,
    };
  }

  String _relativeTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Just now';
    }

    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    return '${difference.inDays}d ago';
  }
}

class _PostAuthorAvatar extends StatefulWidget {
  const _PostAuthorAvatar({
    super.key,
    required this.userId,
    required this.savedImageUrl,
  });

  final String? userId;
  final String? savedImageUrl;

  @override
  State<_PostAuthorAvatar> createState() => _PostAuthorAvatarState();
}

class _PostAuthorAvatarState extends State<_PostAuthorAvatar> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _profile =
      widget.userId == null
      ? null
      : FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profile,
      builder: (context, snapshot) {
        final profile = snapshot.data?.data();
        // Explicit null means the author removed their photo. Only use the
        // post's saved photo when the current profile field is unavailable.
        final value = profile != null && profile.containsKey('profileImageUrl')
            ? profile['profileImageUrl']
            : widget.savedImageUrl;
        final imageUrl = value is String && value.trim().isNotEmpty
            ? value.trim()
            : null;
        return _PostAvatar(imageUrl: imageUrl);
      },
    );
  }
}

class _PostAvatar extends StatelessWidget {
  const _PostAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const CircleAvatar(
        radius: 22,
        backgroundColor: PostCard._attachmentBackground,
        child: Icon(Icons.person_outline, color: PostCard._primaryBlue),
      );
    }

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const CircleAvatar(
          radius: 22,
          backgroundColor: PostCard._attachmentBackground,
          child: Icon(Icons.person_outline, color: PostCard._primaryBlue),
        ),
      ),
    );
  }
}

class _ImageAttachment extends StatelessWidget {
  const _ImageAttachment({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return const ColoredBox(
              color: PostCard._attachmentBackground,
              child: Center(
                child: CircularProgressIndicator(color: PostCard._primaryBlue),
              ),
            );
          },
          errorBuilder: (_, _, _) => const ColoredBox(
            color: PostCard._attachmentBackground,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: PostCard._textSecondary,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Image unavailable',
                    style: TextStyle(color: PostCard._textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoAttachment extends StatelessWidget {
  const _VideoAttachment({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: PostCard._attachmentBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: PostCard._primaryBlue,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 10),
            const Text(
              'Video Attachment',
              style: TextStyle(
                color: PostCard._textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (name != null) ...[
              const SizedBox(height: 4),
              Text(
                name!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PostCard._textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FileAttachment extends StatelessWidget {
  const _FileAttachment({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final fileName = name ?? 'File attachment';
    final extension = fileName.contains('.')
        ? fileName.split('.').last.toUpperCase()
        : 'FILE';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PostCard._attachmentBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 28,
            color: PostCard._primaryBlue,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PostCard._textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  extension,
                  style: const TextStyle(
                    color: PostCard._textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkAttachment extends StatelessWidget {
  const _LinkAttachment({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PostCard._attachmentBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, color: PostCard._primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PostCard._primaryBlue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(this.tag);

  final String tag;

  @override
  Widget build(BuildContext context) {
    final label = tag.startsWith('#') ? tag : '#$tag';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PostCard._attachmentBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: PostCard._primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

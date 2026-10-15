import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:edupro_mobile_app/core/theme/app_colors.dart';

import '../../services/post_service.dart';
import '../../../profile/presentation/screens/user_profile_screen.dart';
import '../screens/new_post_screen.dart';
import 'post_actions_menu.dart';
import 'post_like_button.dart';
import 'post_comments_sheet.dart';
import 'post_image_viewer.dart';
import 'post_save_button.dart';
import 'post_share_sheet.dart';

class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    this.showFullContent = false,
    this.onOpen,
    this.readOnly = false,
  });

  static const _primaryBlue = Color(0xFF167BFF);

  final PublishedPost post;
  final bool showFullContent;
  final VoidCallback? onOpen;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final attachment = _attachmentPreview();
    final imageUrl = post.attachmentType == 'image' ? post.attachmentUrl : null;
    final hasAuthor = post.userId?.trim().isNotEmpty == true;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.appColors.border),
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
              InkWell(
                onTap: hasAuthor && !readOnly
                    ? () => _openAuthor(context)
                    : null,
                customBorder: const CircleBorder(),
                child: _PostAuthorAvatar(
                  key: ValueKey(post.userId ?? post.id),
                  userId: post.userId,
                  savedImageUrl: post.userProfileImage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: hasAuthor && !readOnly
                      ? () => _openAuthor(context)
                      : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${post.category} • ${_relativeTime(post.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!readOnly)
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
              style: TextStyle(
                color: context.appColors.textPrimary,
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
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          if (!showFullContent && onOpen != null && post.content.length > 150)
            TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                foregroundColor: context.appColors.primary,
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
              onTap: imageUrl != null
                  ? () => showPostImageViewer(
                      context,
                      imageUrl: imageUrl,
                      imageLabel: post.title,
                    )
                  : onOpen,
              borderRadius: BorderRadius.circular(12),
              child: attachment,
            ),
          ],
          if (!readOnly) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Wrap(
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
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              color: context.appColors.textSecondary,
                            ),
                            onPressed: () {
                              final service = PostService();
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                useSafeArea: true,
                                builder: (_) => StreamBuilder<User?>(
                                  stream: FirebaseAuth.instance
                                      .authStateChanges(),
                                  initialData:
                                      FirebaseAuth.instance.currentUser,
                                  builder: (context, snapshot) =>
                                      PostCommentsSheet(
                                        key: ValueKey(snapshot.data?.uid),
                                        currentUserId: snapshot.data?.uid,
                                        watchComments: () =>
                                            service.watchComments(post.id),
                                        onSubmit: (text) =>
                                            service.addComment(post.id, text),
                                        onEdit: (id, text) => service
                                            .editComment(post.id, id, text),
                                        onDelete: (id) =>
                                            service.deleteComment(post.id, id),
                                      ),
                                ),
                              );
                            },
                          ),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              color: context.appColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  initialData: FirebaseAuth.instance.currentUser,
                  builder: (context, snapshot) => snapshot.data == null
                      ? PostSaveButton(
                          isSaved: false,
                          onSave: (saved) =>
                              PostService().setPostSaved(post.id, saved: saved),
                        )
                      : PostBookmarkButton(
                          key: ValueKey('${post.id}:${snapshot.data!.uid}'),
                          postId: post.id,
                        ),
                ),
                IconButton(
                  tooltip: 'Share post',
                  onPressed: () => showPostShareSheet(
                    context,
                    postId: post.id,
                    postTitle: post.title,
                  ),
                  icon: Icon(
                    Icons.share_outlined,
                    color: context.appColors.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openAuthor(BuildContext context) {
    final userId = post.userId?.trim();
    if (userId == null || userId.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UserProfileScreen(
          userId: userId,
          fallbackName: post.userName,
          fallbackImageUrl: post.userProfileImage,
        ),
      ),
    );
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
      return CircleAvatar(
        radius: 22,
        backgroundColor: context.appColors.primarySoft,
        child: Icon(Icons.person_outline, color: context.appColors.primary),
      );
    }

    return ClipOval(
      child: Image.network(
        imageUrl!,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => CircleAvatar(
          radius: 22,
          backgroundColor: context.appColors.primarySoft,
          child: Icon(Icons.person_outline, color: context.appColors.primary),
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
            return ColoredBox(
              color: context.appColors.primarySoft,
              child: Center(
                child: CircularProgressIndicator(
                  color: context.appColors.primary,
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => ColoredBox(
            color: context.appColors.primarySoft,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: context.appColors.textSecondary,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Image unavailable',
                    style: TextStyle(color: context.appColors.textSecondary),
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
        color: context.appColors.primarySoft,
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
            Text(
              'Video Attachment',
              style: TextStyle(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (name != null) ...[
              const SizedBox(height: 4),
              Text(
                name!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appColors.textSecondary,
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
        color: context.appColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: 28,
            color: context.appColors.primary,
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
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  extension,
                  style: TextStyle(
                    color: context.appColors.textSecondary,
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
        color: context.appColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: context.appColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appColors.primary,
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
        color: context.appColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: context.appColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

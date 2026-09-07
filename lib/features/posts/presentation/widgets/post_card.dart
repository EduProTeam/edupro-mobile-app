import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/post_service.dart';
import 'post_like_button.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});

  static const _primaryPurple = Color(0xFF5B2CCF);
  static const _textPrimary = Color(0xFF1E1E1E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _borderColor = Color(0xFFE5E7EB);
  static const _attachmentBackground = Color(0xFFF7F4FF);

  final PublishedPost post;

  @override
  Widget build(BuildContext context) {
    final attachment = _attachmentPreview();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PostAvatar(imageUrl: post.userProfileImage),
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
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${post.category} • ${_relativeTime(post.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.more_horiz),
                tooltip: 'Post options',
                color: _textPrimary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post.title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              post.content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
          if (attachment != null) ...[const SizedBox(height: 16), attachment],
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.tags.take(3).map(_TagChip.new).toList(),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                initialData: FirebaseAuth.instance.currentUser,
                builder: (context, snapshot) => PostLikeButton(
                  key: ValueKey('${post.id}:${snapshot.data?.uid}'),
                  likeCount: post.likeCount,
                  isLiked: post.likedBy.contains(snapshot.data?.uid),
                  onLike: (liked) =>
                      PostService().setPostLiked(post.id, liked: liked),
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.chat_bubble_outline, color: _textPrimary),
              const SizedBox(width: 6),
              Text(
                '${post.commentCount}',
                style: const TextStyle(color: _textPrimary),
              ),
              const Spacer(),
              const Icon(Icons.bookmark_border, color: _textPrimary),
            ],
          ),
        ],
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

class _PostAvatar extends StatelessWidget {
  const _PostAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const CircleAvatar(
        radius: 22,
        backgroundColor: PostCard._attachmentBackground,
        child: Icon(Icons.person_outline, color: PostCard._primaryPurple),
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
          child: Icon(Icons.person_outline, color: PostCard._primaryPurple),
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
                child: CircularProgressIndicator(
                  color: PostCard._primaryPurple,
                ),
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
              backgroundColor: PostCard._primaryPurple,
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
            color: PostCard._primaryPurple,
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
          const Icon(Icons.link, color: PostCard._primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: PostCard._primaryPurple,
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
          color: PostCard._primaryPurple,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

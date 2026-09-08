import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../supabase_options.dart';
import '../models/post_comment.dart';

enum PostAttachmentType { image, video, file, link }

extension PostAttachmentTypeValue on PostAttachmentType {
  String get value {
    return switch (this) {
      PostAttachmentType.image => 'image',
      PostAttachmentType.video => 'video',
      PostAttachmentType.file => 'file',
      PostAttachmentType.link => 'link',
    };
  }
}

class PostAttachment {
  const PostAttachment({
    required this.type,
    this.file,
    this.name,
    this.sizeBytes,
    this.linkUrl,
  }) : assert(
         type == PostAttachmentType.link
             ? linkUrl != null && file == null
             : file != null && linkUrl == null,
       );

  final PostAttachmentType type;
  final File? file;
  final String? name;
  final int? sizeBytes;
  final String? linkUrl;

  bool get needsStorageUpload => type != PostAttachmentType.link;
}

/// The Firestore representation written by [PostService.savePost].
///
/// This keeps the feed aligned with the post-creation field names without
/// introducing another storage structure.
class PublishedPost {
  const PublishedPost({
    required this.id,
    required this.userName,
    required this.title,
    required this.category,
    required this.content,
    required this.tags,
    required this.attachmentType,
    required this.attachmentUrl,
    required this.attachmentName,
    required this.linkUrl,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    this.userProfileImage,
    this.userId,
    this.likedBy = const [],
    this.visibility = 'public',
  });

  factory PublishedPost.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return PublishedPost(
      id: _stringValue(data['postId']) ?? document.id,
      userName: _stringValue(data['userName']) ?? 'EduPro user',
      userId: _stringValue(data['userId']),
      visibility: _stringValue(data['visibility']) ?? 'public',
      userProfileImage: _stringValue(data['userProfileImage']),
      title: _stringValue(data['title']) ?? 'Untitled post',
      category: _stringValue(data['category']) ?? 'General',
      content: _stringValue(data['content']) ?? '',
      tags: _stringList(data['tags']),
      attachmentType: _stringValue(data['attachmentType']) ?? 'none',
      attachmentUrl: _stringValue(data['attachmentUrl']),
      attachmentName: _stringValue(data['attachmentName']),
      linkUrl: _stringValue(data['linkUrl']),
      likeCount: _countValue(data['likeCount']),
      likedBy: _stringList(data['likedBy']),
      commentCount: _countValue(data['commentCount']),
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
    );
  }

  final String id;
  final String userName;
  final String? userId;
  final String visibility;
  final String? userProfileImage;
  final String title;
  final String category;
  final String content;
  final List<String> tags;
  final String attachmentType;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? linkUrl;
  final int likeCount;
  final List<String> likedBy;
  final int commentCount;
  final Timestamp? createdAt;

  static String? _stringValue(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) {
      return const [];
    }

    return value
        .whereType<String>()
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(growable: false);
  }

  static int _countValue(Object? value) {
    return switch (value) {
      int() => value,
      num() => value.toInt(),
      _ => 0,
    };
  }
}

class PostService {
  PostService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<List<PostComment>> watchComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(PostComment.fromDocument)
              .toList(growable: false),
        );
  }

  Future<void> addComment(String postId, String text) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const PostFailure('Please log in to comment.');
    }
    final content = text.trim();
    if (content.isEmpty || content.length > 2000) {
      throw const PostFailure(
        'Enter a comment between 1 and 2,000 characters.',
      );
    }
    try {
      final profile = await _firestore.collection('users').doc(user.uid).get();
      final post = _firestore.collection('posts').doc(postId);
      final comment = post.collection('comments').doc();
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(post);
        final data = snapshot.data();
        if (data == null || data['status'] != 'published') {
          throw const PostFailure('This post is no longer available.');
        }
        transaction.set(comment, {
          'userId': user.uid,
          'userName':
              _firstNonEmpty([
                profile.data()?['fullName'],
                user.displayName,
                user.email?.split('@').first,
              ]) ??
              'EduPro user',
          'profileImageUrl': _firstNonEmpty([
            profile.data()?['profileImageUrl'],
            user.photoURL,
          ]),
          'text': content,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(post, {
          'commentCount': PublishedPost._countValue(data['commentCount']) + 1,
          'lastCommentId': comment.id,
        });
      });
    } on PostFailure {
      rethrow;
    } catch (_) {
      throw const PostFailure('Unable to send comment. Please try again.');
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const PostFailure('Please log in to delete your comment.');
    }
    final post = _firestore.collection('posts').doc(postId);
    final comment = post.collection('comments').doc(commentId);
    try {
      await _firestore.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(post);
        final snapshot = await transaction.get(comment);
        if (!snapshot.exists) return;
        if (snapshot.data()?['userId'] != user.uid) {
          throw const PostFailure('You can only delete your own comments.');
        }
        if (postSnapshot.data()?['status'] != 'published') {
          throw const PostFailure('This post is no longer available.');
        }
        transaction.delete(comment);
        transaction.update(post, {
          'commentCount':
              (PublishedPost._countValue(postSnapshot.data()?['commentCount']) -
                      1)
                  .clamp(0, 0x7FFFFFFFFFFFFFFF),
          'lastDeletedCommentId': comment.id,
        });
      });
    } on PostFailure {
      rethrow;
    } catch (_) {
      throw const PostFailure('Unable to delete comment. Please try again.');
    }
  }

  Future<void> editComment(String postId, String commentId, String text) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const PostFailure('Please log in to edit your comment.');
    }
    final content = text.trim();
    if (content.isEmpty || content.length > 2000) {
      throw const PostFailure(
        'Enter a comment between 1 and 2,000 characters.',
      );
    }
    final post = _firestore.collection('posts').doc(postId);
    final comment = post.collection('comments').doc(commentId);
    try {
      await _firestore.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(post);
        final snapshot = await transaction.get(comment);
        if (postSnapshot.data()?['status'] != 'published' || !snapshot.exists) {
          throw const PostFailure('This comment is no longer available.');
        }
        if (snapshot.data()?['userId'] != user.uid) {
          throw const PostFailure('You can only edit your own comments.');
        }
        transaction.update(comment, {
          'text': content,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on PostFailure {
      rethrow;
    } catch (_) {
      throw const PostFailure('Unable to save comment. Please try again.');
    }
  }

  Future<void> setPostLiked(String postId, {required bool liked}) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const PostFailure('Please log in to like a post.');
    }

    final reference = _firestore.collection('posts').doc(postId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);
        final data = snapshot.data();
        if (data == null || data['status'] != 'published') {
          throw const PostFailure('This post is no longer available.');
        }
        final likedBy = PublishedPost._stringList(data['likedBy']);
        if (likedBy.contains(user.uid) == liked) return;

        transaction.update(reference, {
          'likedBy': liked
              ? FieldValue.arrayUnion([user.uid])
              : FieldValue.arrayRemove([user.uid]),
          'likeCount':
              (PublishedPost._countValue(data['likeCount']) + (liked ? 1 : -1))
                  .clamp(0, 0x7FFFFFFFFFFFFFFF),
        });
      });
    } on PostFailure {
      rethrow;
    } catch (_) {
      throw const PostFailure('Unable to update like. Please try again.');
    }
  }

  Stream<List<PublishedPost>> watchPublishedPosts() {
    return _firestore
        .collection('posts')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) {
          final posts = snapshot.docs
              .map(PublishedPost.fromDocument)
              .toList(growable: false);
          posts.sort((newer, older) {
            final newerTime = newer.createdAt?.millisecondsSinceEpoch ?? 0;
            final olderTime = older.createdAt?.millisecondsSinceEpoch ?? 0;
            return olderTime.compareTo(newerTime);
          });
          return posts;
        });
  }

  SupabaseClient get _supabase => SupabaseClient(
    SupabaseOptions.url,
    SupabaseOptions.publishableKey,
    accessToken: () async {
      final user = _firebaseAuth.currentUser;
      return user?.getIdToken();
    },
  );

  Future<void> savePost({
    String? postId,
    bool removeAttachment = false,
    required String title,
    required String category,
    required String content,
    required List<String> tags,
    required String visibility,
    required String status,
    PostAttachment? attachment,
  }) async {
    if (postId != null) {
      return _updatePost(
        postId: postId,
        title: title,
        category: category,
        content: content,
        tags: tags,
        visibility: visibility,
        attachment: attachment,
        removeAttachment: removeAttachment,
      );
    }
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const PostFailure('You must be logged in to publish a post.');
    }

    final profile = await _loadProfile(user.uid);
    final postDocument = _firestore.collection('posts').doc();
    _StoredAttachment? storedAttachment;

    if (attachment != null && attachment.needsStorageUpload) {
      storedAttachment = await _uploadAttachment(
        userId: user.uid,
        postId: postDocument.id,
        attachment: attachment,
      );
    }

    final linkUrl = attachment?.type == PostAttachmentType.link
        ? attachment!.linkUrl
        : null;

    try {
      await postDocument.set({
        'postId': postDocument.id,
        'userId': user.uid,
        'userName':
            _firstNonEmpty([
              profile?['fullName'],
              user.displayName,
              user.email?.split('@').first,
            ]) ??
            'User',
        'userProfileImage': _firstNonEmpty([
          profile?['profileImageUrl'],
          user.photoURL,
        ]),
        'title': title.trim(),
        'category': category,
        'content': content.trim(),
        'tags': tags,
        'visibility': visibility,
        'attachmentType': attachment?.type.value ?? 'none',
        'attachmentUrl': storedAttachment?.url ?? linkUrl,
        'attachmentPath': storedAttachment?.path,
        'attachmentName': storedAttachment?.name ?? attachment?.name,
        'linkUrl': linkUrl,
        'status': status,
        'likeCount': 0,
        'likedBy': <String>[],
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (error) {
      debugPrint('Post save Firestore error: ${error.code}');
      if (storedAttachment != null) {
        debugPrint(
          'Post metadata failed after uploading ${storedAttachment.path}.',
        );
      }
      throw const PostFailure('Unable to publish post. Please try again.');
    } catch (_) {
      if (storedAttachment != null) {
        debugPrint(
          'Post metadata failed after uploading ${storedAttachment.path}.',
        );
      }
      throw const PostFailure('Unable to publish post. Please try again.');
    }
  }

  Future<void> _updatePost({
    required String postId,
    required String title,
    required String category,
    required String content,
    required List<String> tags,
    required String visibility,
    required bool removeAttachment,
    PostAttachment? attachment,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const PostFailure('Please log in to edit your post.');
    }
    if (title.trim().isEmpty ||
        title.trim().length > 100 ||
        content.trim().isEmpty ||
        category.trim().isEmpty ||
        !['public', 'followers'].contains(visibility)) {
      throw const PostFailure('Please complete the required post fields.');
    }
    final reference = _firestore.collection('posts').doc(postId);
    void verifyOwner(DocumentSnapshot<Map<String, dynamic>> snapshot) {
      if (!snapshot.exists) {
        throw const PostFailure('This post is no longer available.');
      }
      if (snapshot.data()?['userId'] != user.uid) {
        throw const PostFailure('You can only edit your own posts.');
      }
    }

    try {
      verifyOwner(await reference.get());
      final changes = <String, dynamic>{
        'title': title.trim(),
        'category': category,
        'content': content.trim(),
        'tags': tags,
        'visibility': visibility,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (attachment != null || removeAttachment) {
        final stored = attachment?.needsStorageUpload == true
            ? await _uploadAttachment(
                userId: user.uid,
                postId: postId,
                attachment: attachment!,
              )
            : null;
        final link = attachment?.linkUrl;
        changes.addAll({
          'attachmentType': attachment?.type.value ?? 'none',
          'attachmentUrl': stored?.url ?? link,
          'attachmentPath': stored?.path,
          'attachmentName': stored?.name ?? attachment?.name,
          'linkUrl': link,
        });
      }
      await _firestore.runTransaction((transaction) async {
        verifyOwner(await transaction.get(reference));
        transaction.update(reference, changes);
      });
    } on PostFailure {
      rethrow;
    } catch (_) {
      throw const PostFailure('Unable to update post. Please try again.');
    }
  }

  Future<Map<String, dynamic>?> _loadProfile(String userId) async {
    try {
      final document = await _firestore.collection('users').doc(userId).get();
      return document.data();
    } on FirebaseException catch (error) {
      debugPrint('Post profile lookup Firestore error: ${error.code}');
      throw const PostFailure('Unable to publish post. Please try again.');
    } catch (_) {
      throw const PostFailure('Unable to publish post. Please try again.');
    }
  }

  Future<_StoredAttachment> _uploadAttachment({
    required String userId,
    required String postId,
    required PostAttachment attachment,
  }) async {
    final file = attachment.file;
    if (file == null) {
      throw const PostFailure('Failed to upload attachment. Please try again.');
    }

    final originalName = attachment.name?.trim().isNotEmpty == true
        ? attachment.name!.trim()
        : file.uri.pathSegments.last;
    final safeName = _safeFileName(originalName);
    final objectPath =
        '$userId/post_${postId}_${DateTime.now().millisecondsSinceEpoch}_$safeName';

    try {
      await _supabase.storage
          .from(SupabaseOptions.mediaBucket)
          .upload(
            objectPath,
            file,
            fileOptions: FileOptions(contentType: _contentTypeFor(safeName)),
          );
      final url = await _supabase.storage
          .from(SupabaseOptions.mediaBucket)
          .createSignedUrl(objectPath, 60 * 60 * 24 * 365);
      return _StoredAttachment(path: objectPath, url: url, name: originalName);
    } on StorageException catch (error) {
      debugPrint('Post attachment storage error: ${error.message}');
      throw const PostFailure('Failed to upload attachment. Please try again.');
    } catch (_) {
      throw const PostFailure('Failed to upload attachment. Please try again.');
    }
  }

  String _safeFileName(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return sanitized.isEmpty ? 'attachment' : sanitized;
  }

  String? _contentTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'avi' => 'video/x-msvideo',
      'mkv' => 'video/x-matroska',
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt' => 'text/plain',
      _ => null,
    };
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

class _StoredAttachment {
  const _StoredAttachment({
    required this.path,
    required this.url,
    required this.name,
  });

  final String path;
  final String url;
  final String name;
}

class PostFailure implements Exception {
  const PostFailure(this.message);

  final String message;
}

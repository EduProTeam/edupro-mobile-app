import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/posts/models/post_comment.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/post_firebase_mocks.dart';

void main() {
  test('POST101 absent document data uses safe published-post defaults', () {
    // Arrange
    final snapshot = postSnapshot(null);
    // Act
    final post = PublishedPost.fromDocument(snapshot);
    // Assert
    expect(post.userName, 'EduPro user');
    expect(post.title, 'Untitled post');
    expect(post.category, 'General');
    expect(post.content, isEmpty);
    expect(post.tags, isEmpty);
    expect(post.likeCount, 0);
    expect(post.createdAt, isNull);
    expect(post.visibility, 'public');
  });
  test(
    'POST102 post decoding trims strings and removes malformed list entries',
    () {
      // Arrange
      final snapshot = postSnapshot({
        'title': ' Lesson ',
        'tags': [' Flutter ', '', 1, null, 'Dart'],
        'likedBy': [' user ', false],
      });
      // Act
      final post = PublishedPost.fromDocument(snapshot);
      // Assert
      expect(post.title, 'Lesson');
      expect(post.tags, ['Flutter', 'Dart']);
      expect(post.likedBy, ['user']);
    },
  );
  test(
    'POST103 malformed post fields and nonnumeric counters use defaults',
    () {
      // Arrange
      final snapshot = postSnapshot({
        'title': 12,
        'userName': ' ',
        'tags': 'Flutter',
        'likeCount': '4',
        'commentCount': null,
        'createdAt': 'yesterday',
      });
      // Act
      final post = PublishedPost.fromDocument(snapshot);
      // Assert
      expect(post.title, 'Untitled post');
      expect(post.userName, 'EduPro user');
      expect(post.tags, isEmpty);
      expect(post.likeCount, 0);
      expect(post.commentCount, 0);
      expect(post.createdAt, isNull);
    },
  );
  test(
    'POST104 numeric counts and Firebase timestamps retain their stored meaning',
    () {
      // Arrange
      final time = Timestamp.fromMillisecondsSinceEpoch(1000);
      final snapshot = postSnapshot({
        'likeCount': 3.8,
        'commentCount': 2,
        'createdAt': time,
      });
      // Act
      final post = PublishedPost.fromDocument(snapshot);
      // Assert
      expect(post.likeCount, 3);
      expect(post.commentCount, 2);
      expect(post.createdAt, time);
    },
  );
  test(
    'POST105 missing comment data uses safe optional fields and author defaults',
    () {
      // Arrange
      final snapshot = postSnapshot(null, id: 'comment');
      // Act
      final comment = PostComment.fromDocument(snapshot);
      // Assert
      expect(comment.id, 'comment');
      expect(comment.userName, 'EduPro user');
      expect(comment.text, isEmpty);
      expect(comment.userId, isNull);
      expect(comment.createdAt, isNull);
      expect(comment.updatedAt, isNull);
    },
  );
  test(
    'POST106 comment decoding preserves valid fields and rejects wrong optional types',
    () {
      // Arrange
      final time = Timestamp.fromMillisecondsSinceEpoch(2000);
      final snapshot = postSnapshot({
        'userId': 'student',
        'userName': 'Learner',
        'text': 'Hello',
        'createdAt': time,
        'updatedAt': 42,
        'profileImageUrl': false,
      });
      // Act
      final comment = PostComment.fromDocument(snapshot);
      // Assert
      expect(comment.userId, 'student');
      expect(comment.userName, 'Learner');
      expect(comment.text, 'Hello');
      expect(comment.createdAt, time);
      expect(comment.updatedAt, isNull);
      expect(comment.profileImageUrl, isNull);
    },
  );
  test(
    'POST107 attachment upload requirement follows the actual attachment type',
    () {
      // Arrange
      const link = PostAttachment(
        type: PostAttachmentType.link,
        linkUrl: 'https://example.invalid',
      );
      final file = PostAttachment(
        type: PostAttachmentType.file,
        file: File('unused.pdf'),
      );
      // Act / Assert
      expect(link.needsStorageUpload, isFalse);
      expect(file.needsStorageUpload, isTrue);
      expect(PostAttachmentType.values.map((type) => type.value), [
        'image',
        'video',
        'file',
        'link',
      ]);
    },
  );
}

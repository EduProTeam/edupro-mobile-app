import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/post_firebase_mocks.dart';

Matcher failure(String message) =>
    isA<PostFailure>().having((error) => error.message, 'message', message);

void main() {
  late PostHarness h;
  setUpAll(
    () => registerFallbackValue((Transaction transaction) async => null),
  );
  setUp(() => h = PostHarness());

  group('Post publication and editing', () {
    test(
      'POST001 creation trims text, uses profile identity and initializes counters',
      () async {
        // Arrange: a signed-in student and a valid post are provided by the harness.
        // Act
        await h.save();
        // Assert
        expect(h.postWrites.single, containsPair('title', 'A useful lesson'));
        expect(h.postWrites.single, containsPair('content', 'Learn Flutter'));
        expect(h.postWrites.single, containsPair('userId', 'student'));
        expect(h.postWrites.single, containsPair('userName', 'Profile name'));
        expect(h.postWrites.single, containsPair('likeCount', 0));
        expect(h.postWrites.single, containsPair('commentCount', 0));
        expect(h.postWrites.single['likedBy'], isEmpty);
        expect(h.postWrites.single['createdAt'], isA<FieldValue>());
      },
    );
    test(
      'POST002 link attachment persists metadata without uploading a file',
      () async {
        // Arrange
        const attachment = PostAttachment(
          type: PostAttachmentType.link,
          linkUrl: 'https://example.invalid/lesson',
          name: 'Resource',
        );
        // Act
        await h.save(attachment: attachment);
        // Assert
        expect(h.postWrites.single['attachmentType'], 'link');
        expect(h.postWrites.single['linkUrl'], attachment.linkUrl);
        expect(h.postWrites.single['attachmentUrl'], attachment.linkUrl);
        expect(h.postWrites.single['attachmentPath'], isNull);
      },
    );
    test(
      'POST003 missing profile falls back to the Firebase display name',
      () async {
        // Arrange
        when(
          () => h.profile.get(),
        ).thenAnswer((_) async => postSnapshot(null, exists: false));
        // Act
        await h.save();
        // Assert
        expect(h.postWrites.single['userName'], 'Display name');
      },
    );
    test(
      'POST004 missing display name falls back to the email local part',
      () async {
        // Arrange
        when(() => h.profile.get()).thenAnswer((_) async => postSnapshot(null));
        when(() => h.user.displayName).thenReturn(' ');
        // Act
        await h.save();
        // Assert
        expect(h.postWrites.single['userName'], 'learner');
      },
    );
    test(
      'POST005 missing all identity details uses the existing generic author',
      () async {
        // Arrange
        when(() => h.profile.get()).thenAnswer((_) async => postSnapshot(null));
        when(() => h.user.displayName).thenReturn(null);
        when(() => h.user.email).thenReturn(null);
        // Act
        await h.save();
        // Assert
        expect(h.postWrites.single['userName'], 'User');
      },
    );
    test('POST006 profile lookup failures prevent publication', () async {
      // Arrange
      when(
        () => h.profile.get(),
      ).thenThrow(FirebaseException(plugin: 'test', code: 'unavailable'));
      // Act / Assert
      await expectLater(
        h.save(),
        throwsA(failure('Unable to publish post. Please try again.')),
      );
      expect(h.postWrites, isEmpty);
    });
    test(
      'POST007 failed metadata writes become a publication failure',
      () async {
        // Arrange
        when(() => h.post.set(any())).thenThrow(StateError('offline'));
        // Act / Assert
        await expectLater(
          h.save(),
          throwsA(failure('Unable to publish post. Please try again.')),
        );
      },
    );
    test('POST008 signed-out publication never queries the database', () async {
      // Arrange
      when(() => h.auth.currentUser).thenReturn(null);
      // Act / Assert
      await expectLater(
        h.save(),
        throwsA(failure('You must be logged in to publish a post.')),
      );
      verifyNever(() => h.db.collection(any()));
    });
    test(
      'POST009 owner edit changes only editable fields and preserves engagement',
      () async {
        // Arrange: the current student owns the published post.
        // Act
        await h.save(id: 'post');
        // Assert
        expect(h.postUpdates.single['title'], 'A useful lesson');
        expect(
          h.postUpdates.single.keys,
          unorderedEquals([
            'title',
            'category',
            'content',
            'tags',
            'visibility',
            'updatedAt',
          ]),
        );
        expect(h.postWrites, isEmpty);
      },
    );
    test(
      'POST010 explicit attachment removal clears every attachment field',
      () async {
        // Arrange / Act
        await h.save(id: 'post', removeAttachment: true);
        // Assert
        expect(h.postUpdates.single['attachmentType'], 'none');
        for (final key in [
          'attachmentUrl',
          'attachmentPath',
          'attachmentName',
          'linkUrl',
        ]) {
          expect(h.postUpdates.single, containsPair(key, isNull), reason: key);
        }
      },
    );
    for (final scenario in [
      (
        'POST011',
        <String, dynamic>{'userId': 'other', 'status': 'published'},
        'You can only edit your own posts.',
      ),
      (
        'POST012',
        <String, dynamic>{'userId': 'student', 'status': 'deleted'},
        'This post has been deleted.',
      ),
    ]) {
      test(
        '${scenario.$1} invalid ownership or status prevents an edit',
        () async {
          // Arrange
          h.setPost(scenario.$2);
          // Act / Assert
          await expectLater(h.save(id: 'post'), throwsA(failure(scenario.$3)));
          expect(h.postUpdates, isEmpty);
        },
      );
    }
    test('POST013 missing post cannot be edited', () async {
      // Arrange
      h.setPost(null, exists: false);
      // Act / Assert
      await expectLater(
        h.save(id: 'post'),
        throwsA(failure('This post is no longer available.')),
      );
      expect(h.postUpdates, isEmpty);
    });
    test('POST014 ownership is checked again inside the transaction', () async {
      // Arrange
      when(() => h.transaction.get(h.post)).thenAnswer(
        (_) async => postSnapshot({'userId': 'other', 'status': 'published'}),
      );
      // Act / Assert
      await expectLater(
        h.save(id: 'post'),
        throwsA(failure('You can only edit your own posts.')),
      );
      expect(h.postUpdates, isEmpty);
    });
    for (final scenario in [
      ('POST015', '', 'public'),
      ('POST016', 'x' * 101, 'public'),
      ('POST017', 'Valid title', 'private'),
    ]) {
      test(
        '${scenario.$1} invalid edit fields are rejected before database access',
        () async {
          // Arrange / Act / Assert
          await expectLater(
            h.save(id: 'post', title: scenario.$2, visibility: scenario.$3),
            throwsA(failure('Please complete the required post fields.')),
          );
          verifyNever(() => h.db.collection(any()));
        },
      );
    }
    test('POST018 the maximum 100-character edit title is accepted', () async {
      // Arrange
      final title = 'x' * 100;
      // Act
      await h.save(id: 'post', title: title);
      // Assert
      expect(h.postUpdates.single['title'], title);
    });
  });

  group('Post deletion', () {
    test(
      'POST019 deleting an owned post writes a tombstone and timestamps',
      () async {
        // Arrange / Act
        await h.service.deletePost('post');
        // Assert
        expect(h.postUpdates.single['status'], 'deleted');
        expect(h.postUpdates.single['deletedAt'], isA<FieldValue>());
        expect(h.postUpdates.single['updatedAt'], isA<FieldValue>());
        verifyNever(() => h.transaction.delete(h.post));
      },
    );
    test('POST020 deleting an already deleted post is idempotent', () async {
      // Arrange
      h.setPost({'userId': 'student', 'status': 'deleted'});
      // Act
      await h.service.deletePost('post');
      // Assert
      expect(h.postUpdates, isEmpty);
    });
    test('POST021 another author cannot delete a post', () async {
      // Arrange
      h.setPost({'userId': 'other', 'status': 'published'});
      // Act / Assert
      await expectLater(
        h.service.deletePost('post'),
        throwsA(failure('You can only delete your own posts.')),
      );
      expect(h.postUpdates, isEmpty);
    });
    test('POST022 a missing post reports that it is unavailable', () async {
      // Arrange
      h.setPost(null, exists: false);
      // Act / Assert
      await expectLater(
        h.service.deletePost('post'),
        throwsA(failure('This post is no longer available.')),
      );
    });
  });

  group('Like mutations', () {
    test(
      'POST023 liking adds the current user and increments the persisted count',
      () async {
        // Arrange / Act
        await h.service.setPostLiked('post', liked: true);
        // Assert
        expect(h.postUpdates.single['likeCount'], 3);
        expect(
          h.postUpdates.single['likedBy'],
          FieldValue.arrayUnion(['student']),
        );
      },
    );
    test(
      'POST024 unliking removes only the current user and decrements the count',
      () async {
        // Arrange
        h.setPost({
          'status': 'published',
          'likedBy': ['student', 'other'],
          'likeCount': 2,
        });
        // Act
        await h.service.setPostLiked('post', liked: false);
        // Assert
        expect(h.postUpdates.single['likeCount'], 1);
        expect(
          h.postUpdates.single['likedBy'],
          FieldValue.arrayRemove(['student']),
        );
      },
    );
    for (final liked in [true, false]) {
      test(
        '${liked ? 'POST025' : 'POST026'} repeated like state does not change counters',
        () async {
          // Arrange
          h.setPost({
            'status': 'published',
            'likedBy': liked ? ['student'] : [],
            'likeCount': 1,
          });
          // Act
          await h.service.setPostLiked('post', liked: liked);
          // Assert
          expect(h.postUpdates, isEmpty);
        },
      );
    }
    test(
      'POST027 unliking a stale zero count never creates a negative count',
      () async {
        // Arrange
        h.setPost({
          'status': 'published',
          'likedBy': ['student'],
          'likeCount': 0,
        });
        // Act
        await h.service.setPostLiked('post', liked: false);
        // Assert
        expect(h.postUpdates.single['likeCount'], 0);
      },
    );
    test('POST028 unpublished posts cannot receive likes', () async {
      // Arrange
      h.setPost({'status': 'draft'});
      // Act / Assert
      await expectLater(
        h.service.setPostLiked('post', liked: true),
        throwsA(failure('This post is no longer available.')),
      );
      expect(h.postUpdates, isEmpty);
    });
  });

  group('Comment mutations', () {
    test(
      'POST029 a comment is trimmed and atomically increases the post count',
      () async {
        // Arrange / Act
        await h.service.addComment('post', '  Helpful lesson!  ');
        // Assert
        expect(h.commentWrites.single['text'], 'Helpful lesson!');
        expect(h.commentWrites.single['userName'], 'Profile name');
        expect(
          h.commentWrites.single['profileImageUrl'],
          'https://example.invalid/avatar.png',
        );
        expect(h.postUpdates.single, {
          'commentCount': 2,
          'lastCommentId': 'comment',
        });
      },
    );
    for (final entry in [
      ('POST030', ''),
      ('POST031', ' \n\t '),
      ('POST032', 'x' * 2001),
    ]) {
      test(
        '${entry.$1} invalid comment text is rejected without database access',
        () async {
          // Arrange / Act / Assert
          await expectLater(
            h.service.addComment('post', entry.$2),
            throwsA(failure('Enter a comment between 1 and 2,000 characters.')),
          );
          verifyNever(() => h.db.collection(any()));
        },
      );
    }
    for (final length in [1, 2000]) {
      test(
        '${length == 1 ? 'POST033' : 'POST034'} comment length $length is accepted at the boundary',
        () async {
          // Arrange
          final text = 'x' * length;
          // Act
          await h.service.addComment('post', text);
          // Assert
          expect(h.commentWrites.single['text'], text);
        },
      );
    }
    test(
      'POST035 comments on withdrawn posts do not write comment metadata',
      () async {
        // Arrange
        h.setPost({'status': 'deleted'});
        // Act / Assert
        await expectLater(
          h.service.addComment('post', 'Helpful'),
          throwsA(failure('This post is no longer available.')),
        );
        expect(h.commentWrites, isEmpty);
        expect(h.postUpdates, isEmpty);
      },
    );
    test(
      'POST036 deleting an owned comment clamps a stale count at zero',
      () async {
        // Arrange
        h.setPost({'status': 'published', 'commentCount': 0});
        // Act
        await h.service.deleteComment('post', 'comment');
        // Assert
        verify(() => h.transaction.delete(h.comment)).called(1);
        expect(h.postUpdates.single, {
          'commentCount': 0,
          'lastDeletedCommentId': 'comment',
        });
      },
    );
    test('POST037 deleting a missing comment is idempotent', () async {
      // Arrange
      h.setComment(null, exists: false);
      // Act
      await h.service.deleteComment('post', 'comment');
      // Assert
      verifyNever(() => h.transaction.delete(h.comment));
      expect(h.postUpdates, isEmpty);
    });
    test('POST038 another author cannot delete a comment', () async {
      // Arrange
      h.setComment({'userId': 'other'});
      // Act / Assert
      await expectLater(
        h.service.deleteComment('post', 'comment'),
        throwsA(failure('You can only delete your own comments.')),
      );
      verifyNever(() => h.transaction.delete(h.comment));
    });
    test(
      'POST039 editing an owned comment updates text without changing counters',
      () async {
        // Arrange / Act
        await h.service.editComment('post', 'comment', '  Revised  ');
        // Assert
        expect(h.commentUpdates.single['text'], 'Revised');
        expect(h.commentUpdates.single['updatedAt'], isA<FieldValue>());
        expect(h.postUpdates, isEmpty);
      },
    );
    test('POST040 another author cannot edit a comment', () async {
      // Arrange
      h.setComment({'userId': 'other'});
      // Act / Assert
      await expectLater(
        h.service.editComment('post', 'comment', 'Revised'),
        throwsA(failure('You can only edit your own comments.')),
      );
      expect(h.commentUpdates, isEmpty);
    });
    test('POST041 a missing comment cannot be edited', () async {
      // Arrange
      h.setComment(null, exists: false);
      // Act / Assert
      await expectLater(
        h.service.editComment('post', 'comment', 'Revised'),
        throwsA(failure('This comment is no longer available.')),
      );
    });
    test('POST042 whitespace-only comment edits are rejected', () async {
      // Arrange / Act / Assert
      await expectLater(
        h.service.editComment('post', 'comment', ' '),
        throwsA(failure('Enter a comment between 1 and 2,000 characters.')),
      );
      expect(h.commentUpdates, isEmpty);
    });
  });

  final actions = <String, (String, Future<void> Function(PostHarness))>{
    'POST043': ('delete your post', (h) => h.service.deletePost('post')),
    'POST044': (
      'like a post',
      (h) => h.service.setPostLiked('post', liked: true),
    ),
    'POST045': ('comment', (h) => h.service.addComment('post', 'Hi')),
    'POST046': (
      'delete your comment',
      (h) => h.service.deleteComment('post', 'comment'),
    ),
    'POST047': (
      'edit your comment',
      (h) => h.service.editComment('post', 'comment', 'Hi'),
    ),
  };
  for (final entry in actions.entries) {
    test('${entry.key} signed-out users cannot ${entry.value.$1}', () async {
      // Arrange
      when(() => h.auth.currentUser).thenReturn(null);
      // Act / Assert
      await expectLater(
        entry.value.$2(h),
        throwsA(failure('Please log in to ${entry.value.$1}.')),
      );
      verifyNever(() => h.db.collection(any()));
    });
  }
  for (final entry in <String, (String, Future<void> Function(PostHarness))>{
    'POST048': (
      'Unable to delete post. Please try again.',
      (h) => h.service.deletePost('post'),
    ),
    'POST049': (
      'Unable to update like. Please try again.',
      (h) => h.service.setPostLiked('post', liked: true),
    ),
    'POST050': (
      'Unable to send comment. Please try again.',
      (h) => h.service.addComment('post', 'Hi'),
    ),
    'POST051': (
      'Unable to delete comment. Please try again.',
      (h) => h.service.deleteComment('post', 'comment'),
    ),
    'POST052': (
      'Unable to save comment. Please try again.',
      (h) => h.service.editComment('post', 'comment', 'Hi'),
    ),
    'POST053': (
      'Unable to update post. Please try again.',
      (h) => h.save(id: 'post'),
    ),
  }.entries) {
    test(
      '${entry.key} transaction errors become an actionable domain failure',
      () async {
        // Arrange
        when(
          () => h.db.runTransaction<Null>(any()),
        ).thenThrow(StateError('offline'));
        // Act / Assert
        await expectLater(entry.value.$2(h), throwsA(failure(entry.value.$1)));
        expect(h.postUpdates, isEmpty);
        expect(h.commentUpdates, isEmpty);
      },
    );
  }
}

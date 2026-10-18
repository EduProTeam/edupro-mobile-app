// Firestore interfaces are mocked at the SDK boundary; no Firebase app is used.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/posts/models/blocked_word_filter.dart';
import 'package:edupro_mobile_app/features/posts/services/post_moderation_service.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

class PostMockAuth extends Mock implements FirebaseAuth {}

class PostMockUser extends Mock implements User {}

class PostMockFirestore extends Mock implements FirebaseFirestore {}

class PostMockCollection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class PostMockReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class PostMockSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class PostMockTransaction extends Mock implements Transaction {}

PostMockSnapshot postSnapshot(
  Map<String, dynamic>? data, {
  String id = 'post',
  bool exists = true,
}) {
  final snapshot = PostMockSnapshot();
  when(() => snapshot.id).thenReturn(id);
  when(() => snapshot.exists).thenReturn(exists);
  when(() => snapshot.data()).thenReturn(data);
  return snapshot;
}

/// A fresh harness per test executes the real service transaction callback.
/// It records intended writes, leaving Firestore's own implementation untested.
class PostHarness {
  final auth = PostMockAuth();
  final user = PostMockUser();
  final db = PostMockFirestore();
  final posts = PostMockCollection();
  final users = PostMockCollection();
  final comments = PostMockCollection();
  final post = PostMockReference();
  final profile = PostMockReference();
  final comment = PostMockReference();
  final transaction = PostMockTransaction();
  final postUpdates = <Map<String, dynamic>>[];
  final commentUpdates = <Map<String, dynamic>>[];
  final postWrites = <Map<String, dynamic>>[];
  final commentWrites = <Map<String, dynamic>>[];
  late final PostService service;

  PostHarness() {
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('student');
    when(() => user.displayName).thenReturn('Display name');
    when(() => user.email).thenReturn('learner@example.invalid');
    when(() => user.photoURL).thenReturn(null);
    when(() => db.collection('posts')).thenReturn(posts);
    when(() => db.collection('users')).thenReturn(users);
    when(() => posts.doc('post')).thenReturn(post);
    when(() => posts.doc()).thenReturn(post);
    when(() => users.doc('student')).thenReturn(profile);
    when(() => post.id).thenReturn('post');
    when(() => post.collection('comments')).thenReturn(comments);
    when(() => comments.doc()).thenReturn(comment);
    when(() => comments.doc('comment')).thenReturn(comment);
    when(() => comment.id).thenReturn('comment');
    when(() => profile.get()).thenAnswer(
      (_) async => postSnapshot({
        'fullName': 'Profile name',
        'profileImageUrl': 'https://example.invalid/avatar.png',
      }),
    );
    setPost({
      'userId': 'student',
      'status': 'published',
      'likeCount': 2,
      'commentCount': 1,
      'likedBy': <String>[],
    });
    setComment({'userId': 'student', 'text': 'Original'});
    when(() => transaction.update(post, any())).thenAnswer((call) {
      postUpdates.add(
        Map<String, dynamic>.from(call.positionalArguments[1] as Map),
      );
      return transaction;
    });
    when(() => transaction.update(comment, any())).thenAnswer((call) {
      commentUpdates.add(
        Map<String, dynamic>.from(call.positionalArguments[1] as Map),
      );
      return transaction;
    });
    // Match the nullable values inferred for the comment map literal.
    when(
      () => transaction.set<Map<String, Object?>>(comment, any()),
    ).thenAnswer((call) {
      commentWrites.add(
        Map<String, dynamic>.from(call.positionalArguments[1] as Map),
      );
      return transaction;
    });
    when(() => transaction.delete(comment)).thenReturn(transaction);
    when(() => post.set(any())).thenAnswer((call) async {
      postWrites.add(
        Map<String, dynamic>.from(call.positionalArguments[0] as Map),
      );
    });
    // The service's callbacks have no return value, so Dart infers Null.
    when(() => db.runTransaction<Null>(any())).thenAnswer((call) async {
      await (call.positionalArguments.first as TransactionHandler<Null>)(
        transaction,
      );
      return null;
    });
    service = PostService(
      firebaseAuth: auth,
      firestore: db,
      moderationService: PostModerationService(
        loadFilter: () async => BlockedWordFilter(['forbidden']),
      ),
    );
  }

  void setPost(Map<String, dynamic>? data, {bool exists = true}) {
    final snapshot = postSnapshot(data, exists: exists);
    when(() => post.get()).thenAnswer((_) async => snapshot);
    when(() => transaction.get(post)).thenAnswer((_) async => snapshot);
  }

  void setComment(Map<String, dynamic>? data, {bool exists = true}) {
    final snapshot = postSnapshot(data, id: 'comment', exists: exists);
    when(() => transaction.get(comment)).thenAnswer((_) async => snapshot);
  }

  Future<void> save({
    String? id,
    String title = ' A useful lesson ',
    String content = ' Learn Flutter ',
    String visibility = 'public',
    bool removeAttachment = false,
    PostAttachment? attachment,
  }) => service.savePost(
    postId: id,
    title: title,
    category: 'Programming',
    content: content,
    tags: ['Flutter'],
    visibility: visibility,
    status: 'published',
    removeAttachment: removeAttachment,
    attachment: attachment,
  );
}

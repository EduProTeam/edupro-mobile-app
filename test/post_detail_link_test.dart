// Live detail states are exercised without Firebase credentials.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:edupro_mobile_app/features/posts/presentation/screens/post_detail_screen.dart';
import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_card.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Posts implements PostService {
  _Posts(this.watch);
  final Stream<PublishedPost?> Function(String) watch;
  final requestedIds = <String>[];

  @override
  Stream<PublishedPost?> watchPublishedPost(String postId) {
    requestedIds.add(postId);
    return watch(postId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PublishedPost _post(String id, {String visibility = 'public'}) => PublishedPost(
  id: id,
  userName: 'Author',
  title: 'Lesson $id',
  category: 'Flutter',
  content: 'Full lesson content for $id.',
  tags: const [],
  attachmentType: 'none',
  attachmentUrl: null,
  attachmentName: null,
  linkUrl: null,
  likeCount: 0,
  commentCount: 0,
  createdAt: null,
  visibility: visibility,
);

Widget _app(_Posts posts, {String id = 'selected', bool readOnly = true}) =>
    MaterialApp(
      home: PostDetailScreen.fromId(
        postId: id,
        postService: posts,
        publicOnly: true,
        readOnly: readOnly,
      ),
    );

void main() {
  testWidgets('post link waits for its result and rejects non-public content', (
    tester,
  ) async {
    final changes = StreamController<PublishedPost?>();
    addTearDown(changes.close);
    final posts = _Posts((_) => changes.stream);
    await tester.pumpWidget(_app(posts, readOnly: false));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('This post is no longer available.'), findsNothing);
    expect(posts.requestedIds, ['selected']);

    changes.add(_post('selected', visibility: 'followers'));
    await tester.pumpAndSettle();
    expect(find.byType(PostCard), findsNothing);
    expect(find.text('Lesson selected'), findsNothing);
    expect(find.text('This post is no longer available.'), findsOneWidget);
  });

  testWidgets('live withdrawal and visibility changes remove shared content', (
    tester,
  ) async {
    final changes = StreamController<PublishedPost?>();
    addTearDown(changes.close);
    await tester.pumpWidget(_app(_Posts((_) => changes.stream)));
    changes.add(_post('selected'));
    await tester.pumpAndSettle();
    expect(find.text('Full lesson content for selected.'), findsOneWidget);

    changes.add(_post('selected', visibility: 'followers'));
    await tester.pumpAndSettle();
    expect(find.byType(PostCard), findsNothing);

    changes.add(_post('selected'));
    await tester.pumpAndSettle();
    expect(find.byType(PostCard), findsOneWidget);
    changes.add(null);
    await tester.pumpAndSettle();
    expect(find.byType(PostCard), findsNothing);
    expect(find.text('This post is no longer available.'), findsOneWidget);
  });

  testWidgets('failed link loads retry the same selected post', (tester) async {
    var attempts = 0;
    final posts = _Posts(
      (_) => ++attempts == 1
          ? Stream.error(StateError('Offline'))
          : Stream.value(_post('selected')),
    );
    await tester.pumpWidget(_app(posts));
    await tester.pumpAndSettle();
    expect(find.text('Could not load this post.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson selected'), findsOneWidget);
    expect(posts.requestedIds, ['selected', 'selected']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing the target clears the previous post while loading', (
    tester,
  ) async {
    final next = StreamController<PublishedPost?>();
    addTearDown(next.close);
    final posts = _Posts(
      (id) => id == 'first' ? Stream.value(_post(id)) : next.stream,
    );
    await tester.pumpWidget(_app(posts, id: 'first'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson first'), findsOneWidget);
    await tester.pumpWidget(_app(posts, id: 'second'));
    expect(find.text('Lesson first'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    next.add(_post('second'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson second'), findsOneWidget);
    expect(posts.requestedIds, ['first', 'second']);
    expect(tester.takeException(), isNull);
  });
}

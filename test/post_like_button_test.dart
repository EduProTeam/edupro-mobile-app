import 'dart:async';

import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_like_button.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required Future<void> Function(bool) onLike,
    bool isLiked = false,
    int count = 2,
  }) => MaterialApp(
    home: Scaffold(
      body: PostLikeButton(likeCount: count, isLiked: isLiked, onLike: onLike),
    ),
  );

  testWidgets('rapid taps save once and snapshot does not double count', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    Future<void> like(bool liked) {
      calls++;
      return pending.future;
    }

    await tester.pumpWidget(host(onLike: like));
    await tester.tap(find.byType(IconButton));
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.pumpWidget(host(onLike: like, isLiked: true, count: 3));
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('persisted like can be unliked and liked again', (tester) async {
    var calls = 0;
    final states = <bool>[];
    await tester.pumpWidget(
      host(
        onLike: (liked) async {
          calls++;
          states.add(liked);
        },
        isLiked: true,
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(states, [false, true]);
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets('failed save preserves count and allows retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        onLike: (liked) async {
          calls++;
          if (calls == 1) {
            throw const PostFailure('Please log in to like a post.');
          }
        },
      ),
    );
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(find.text('Please log in to like a post.'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('3'), findsOneWidget);
  });
}

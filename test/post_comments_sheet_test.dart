import 'dart:async';

import 'package:edupro_mobile_app/features/posts/models/post_comment.dart';
import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_comments_sheet.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required Future<void> Function(String) submit,
    List<PostComment> comments = const [],
  }) => MaterialApp(
    home: Scaffold(
      body: PostCommentsSheet(
        watchComments: () => Stream.value(comments),
        onSubmit: submit,
      ),
    ),
  );

  testWidgets('empty comments and whitespace cannot be submitted', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        submit: (_) async {
          calls++;
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No comments yet. Start the conversation!'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    await tester.tap(find.byTooltip('Send comment'));
    expect(calls, 0);
  });

  testWidgets('submits once while pending and clears successful comment', (
    tester,
  ) async {
    final pending = Completer<void>();
    final sent = <String>[];
    await tester.pumpWidget(
      host(
        submit: (text) {
          sent.add(text);
          return pending.future;
        },
        comments: const [
          PostComment(id: '1', userName: 'Teacher', text: 'Welcome!'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Welcome!'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Thank you!  ');
    await tester.pump();
    await tester.tap(find.byTooltip('Send comment'));
    await tester.tap(find.byTooltip('Send comment'));
    await tester.pump();
    expect(sent, ['Thank you!']);
    pending.complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('failed submission preserves draft and supports retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        submit: (_) async {
          if (++calls == 1) {
            throw const PostFailure(
              'Unable to send comment. Please try again.',
            );
          }
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My comment');
    await tester.pump();
    await tester.tap(find.byTooltip('Send comment'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to send comment. Please try again.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'My comment',
    );
    await tester.tap(find.byTooltip('Send comment'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });
}

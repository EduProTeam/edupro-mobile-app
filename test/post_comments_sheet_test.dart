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
    String? currentUserId,
    Future<void> Function(String, String)? edit,
    Future<void> Function(String)? delete,
  }) => MaterialApp(
    home: Scaffold(
      body: PostCommentsSheet(
        watchComments: () => Stream.value(comments),
        onSubmit: submit,
        currentUserId: currentUserId,
        onEdit: edit,
        onDelete: delete,
      ),
    ),
  );

  const editableComments = [
    PostComment(id: 'mine', userId: 'me', userName: 'Me', text: 'Original'),
    PostComment(
      id: 'theirs',
      userId: 'other',
      userName: 'Other',
      text: 'Other comment',
    ),
    PostComment(id: 'legacy', userName: 'Unknown', text: 'No owner'),
  ];

  testWidgets('only own comment has delete and cancelling leaves it intact', (
    tester,
  ) async {
    final deleted = <String>[];
    await tester.pumpWidget(
      host(
        submit: (_) async {},
        currentUserId: 'me',
        comments: editableComments,
        delete: (id) async {
          deleted.add(id);
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Delete comment'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete comment'));
    await tester.pumpAndSettle();
    expect(find.text('Delete comment?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleted, isEmpty);
    await tester.tap(find.byTooltip('Delete comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(deleted, ['mine']);
  });

  testWidgets('failed deletion leaves comment and permits retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        submit: (_) async {},
        currentUserId: 'me',
        comments: editableComments,
        delete: (_) async {
          if (++calls == 1) {
            throw const PostFailure('Unable to delete comment.');
          }
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to delete comment.'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    await tester.tap(find.byTooltip('Delete comment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets(
    'only own comment can be edited and save does not submit a new one',
    (tester) async {
      var submissions = 0;
      final edits = <String>[];
      await tester.pumpWidget(
        host(
          submit: (_) async {
            submissions++;
          },
          currentUserId: 'me',
          comments: editableComments,
          edit: (id, text) async {
            edits.add('$id:$text');
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Edit comment'), findsOneWidget);
      await tester.tap(find.byTooltip('Edit comment'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Original',
      );
      await tester.enterText(find.byType(TextField), '  Updated  ');
      await tester.pump();
      await tester.tap(find.byTooltip('Save comment'));
      await tester.pumpAndSettle();
      expect(edits, ['mine:Updated']);
      expect(submissions, 0);
      expect(find.text('Editing your comment'), findsNothing);
    },
  );

  testWidgets('failed edit keeps text and cancel restores new comment draft', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        submit: (_) async {},
        currentUserId: 'me',
        comments: editableComments,
        edit: (_, _) async {
          throw const PostFailure('Unable to save comment.');
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Unsent draft');
    await tester.tap(find.byTooltip('Edit comment'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Revised text');
    await tester.pump();
    await tester.tap(find.byTooltip('Save comment'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to save comment.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Revised text',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Unsent draft',
    );
  });

  testWidgets('signed out users have no edit actions', (tester) async {
    await tester.pumpWidget(
      host(
        submit: (_) async {},
        comments: editableComments,
        edit: (_, _) async {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Edit comment'), findsNothing);
  });

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

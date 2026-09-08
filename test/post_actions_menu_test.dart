import 'dart:async';

import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_actions_menu.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({bool isOwner = true, required Future<void> Function() delete}) =>
      MaterialApp(
        home: Scaffold(
          body: PostActionsMenu(
            isOwner: isOwner,
            onEdit: () {},
            onDelete: delete,
          ),
        ),
      );

  Future<void> openDelete(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Post options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete post'));
    await tester.pumpAndSettle();
  }

  testWidgets('other users have no post actions', (tester) async {
    await tester.pumpWidget(host(isOwner: false, delete: () async {}));
    expect(find.byTooltip('Post options'), findsNothing);
    expect(find.byType(PopupMenuButton<String>), findsNothing);
  });

  testWidgets('cancel does not delete and confirmed repeated taps save once', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      host(
        delete: () {
          calls++;
          return pending.future;
        },
      ),
    );
    await openDelete(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    await openDelete(tester);
    final button = find.widgetWithText(TextButton, 'Delete');
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    expect(find.text('Deleting…'), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('Delete post?'), findsNothing);
    expect(find.text('Post deleted'), findsOneWidget);
  });

  testWidgets('failed deletion keeps confirmation open for retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        delete: () async {
          if (++calls == 1) {
            throw const PostFailure('Unable to delete post. Please try again.');
          }
        },
      ),
    );
    await openDelete(tester);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to delete post. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Post deleted'), findsNothing);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Post deleted'), findsOneWidget);
  });
}

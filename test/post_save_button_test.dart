import 'dart:async';

import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_save_button.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required Future<void> Function(bool) save,
    bool saved = false,
  }) => MaterialApp(
    home: Scaffold(
      body: PostSaveButton(isSaved: saved, onSave: save),
    ),
  );

  testWidgets('save is immediate, rapid taps write once, and unsave works', (
    tester,
  ) async {
    final pending = Completer<void>();
    final changes = <bool>[];
    Future<void> save(bool value) {
      changes.add(value);
      return pending.future;
    }

    await tester.pumpWidget(host(save: save));
    await tester.tap(find.byType(IconButton));
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(changes, [true]);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(
      find.text('Post saved. Find it in Profile → Saved.'),
      findsOneWidget,
    );
    await tester.pumpWidget(host(save: save, saved: true));
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
  });

  testWidgets('failure rolls back and a second tap can retry', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        save: (_) async {
          if (++calls == 1) {
            throw const PostFailure('Please log in to save a post.');
          }
        },
      ),
    );
    await tester.tap(find.byTooltip('Save post'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
    expect(find.text('Please log in to save a post.'), findsOneWidget);
    await tester.tap(find.byTooltip('Save post'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
  });

  testWidgets(
    'live bookmark changes update the button after a completed save',
    (tester) async {
      Future<void> save(bool _) async {}
      await tester.pumpWidget(host(save: save));
      await tester.tap(find.byTooltip('Save post'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host(save: save, saved: true));
      await tester.pumpWidget(host(save: save, saved: false));
      expect(find.byTooltip('Save post'), findsOneWidget);
    },
  );

  testWidgets(
    'failed removal reports an error even after its tile disappears',
    (tester) async {
      final pending = Completer<void>();
      final visible = ValueNotifier(true);
      addTearDown(visible.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<bool>(
              valueListenable: visible,
              builder: (context, show, _) => show
                  ? PostSaveButton(isSaved: true, onSave: (_) => pending.future)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Remove from saved posts'));
      visible.value = false;
      await tester.pump();
      pending.completeError(
        const PostFailure('Unable to remove saved post. Please try again.'),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to remove saved post. Please try again.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

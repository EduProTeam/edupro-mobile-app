import 'package:edupro_mobile_app/features/home/presentation/widgets/home_post_feed.dart';
import 'package:edupro_mobile_app/features/posts/presentation/screens/new_post_screen.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home shortcuts and composer buttons invoke their real actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final attachments = <PostAttachmentType?>[];
    var profiles = 0;
    var saved = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePostFeed(
            postsStream: Stream.value([]),
            onRefresh: () async {},
            onRetry: () {},
            userName: 'A learner',
            onCreatePost: attachments.add,
            onOpenProfile: () => profiles++,
            onOpenSaved: () => saved++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Saved posts'));
    await tester.tap(find.byTooltip('Open your profile'));
    for (final label in ['Photo', 'Video', 'File', 'Link', 'Post']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
    }
    expect(attachments, [
      PostAttachmentType.image,
      PostAttachmentType.video,
      PostAttachmentType.file,
      PostAttachmentType.link,
      null,
    ]);
    expect([profiles, saved], [1, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home stays usable at 320px and doubled text size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: HomePostFeed(
              postsStream: Stream.value([]),
              onRefresh: () async {},
              onRetry: () {},
              userName: 'A learner with a long name',
              onCreatePost: (_) {},
              onOpenProfile: () {},
              onOpenSaved: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Post'),
      160,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Link composer intent opens the link form in the post editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NewPostScreen(initialAttachmentType: PostAttachmentType.link),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add Link'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('New Post'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

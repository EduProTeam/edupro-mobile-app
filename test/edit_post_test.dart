import 'package:edupro_mobile_app/features/posts/presentation/screens/new_post_screen.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingPostService implements PostService {
  Map<String, Object?>? saved;
  bool fail = false;

  @override
  Future<void> savePost({
    String? postId,
    bool removeAttachment = false,
    required String title,
    required String category,
    required String content,
    required List<String> tags,
    required String visibility,
    required String status,
    PostAttachment? attachment,
  }) async {
    saved = {
      'postId': postId,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'visibility': visibility,
      'removeAttachment': removeAttachment,
      'attachment': attachment,
    };
    if (fail) throw const PostFailure('Unable to update post.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const post = PublishedPost(
    id: 'post1',
    userId: 'owner',
    userName: 'Author',
    title: 'Existing title',
    category: 'Programming',
    content: 'Existing content',
    tags: ['Flutter'],
    attachmentType: 'file',
    attachmentUrl: 'https://example.com/file.pdf',
    attachmentName: 'lesson.pdf',
    linkUrl: null,
    likeCount: 3,
    commentCount: 2,
    createdAt: null,
    visibility: 'followers',
  );

  Future<void> open(WidgetTester tester, _RecordingPostService service) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      NewPostScreen(post: post, postService: service),
                ),
              ),
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'edit prefills post and saves same id while retaining attachment',
    (tester) async {
      final service = _RecordingPostService();
      await open(tester, service);
      expect(find.text('Edit Post'), findsOneWidget);
      expect(find.text('Existing title'), findsOneWidget);
      expect(find.text('Existing content'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, 'Changed title');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(service.saved?['postId'], 'post1');
      expect(service.saved?['title'], 'Changed title');
      expect(service.saved?['visibility'], 'followers');
      expect(service.saved?['tags'], ['Flutter']);
      expect(service.saved?['removeAttachment'], false);
      expect(service.saved?['attachment'], isNull);
      expect(find.text('Open editor'), findsOneWidget);
    },
  );

  testWidgets(
    'attachment removal is explicit and failed save keeps editor open',
    (tester) async {
      final service = _RecordingPostService()..fail = true;
      await open(tester, service);
      await tester.ensureVisible(find.byTooltip('Remove current attachment'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove current attachment'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save Changes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();
      expect(service.saved?['removeAttachment'], true);
      expect(find.text('Edit Post'), findsOneWidget);
      expect(find.text('Unable to update post.'), findsOneWidget);
    },
  );
}

// Test doubles verify that rejected posts never reach Firebase or media storage.
// ignore_for_file: subtype_of_sealed_class

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/posts/models/blocked_word_filter.dart';
import 'package:edupro_mobile_app/features/posts/presentation/screens/new_post_screen.dart';
import 'package:edupro_mobile_app/features/posts/services/post_moderation_service.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _cleanTitle = 'A useful lesson';
const _cleanContent = 'Learn how to build a Flutter app.';

PostModerationService _moderation() => PostModerationService(
  loadFilter: () async => BlockedWordFilter(['forbidden']),
);

String _fieldError(String field) =>
    'Remove inappropriate language from the $field before saving your post.';

class _UnusedAuth implements FirebaseAuth {
  int accesses = 0;

  @override
  User? get currentUser {
    accesses++;
    throw StateError('Rejected text must not reach authentication.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedFirestore implements FirebaseFirestore {
  int accesses = 0;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    accesses++;
    throw StateError('Rejected text must not reach Firestore.');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingPostService implements PostService {
  final saved = <Map<String, Object?>>[];

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
    saved.add({
      'postId': postId,
      'title': title,
      'content': content,
      'tags': List<String>.of(tags),
      'status': status,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _existingPost = PublishedPost(
  id: 'existing-post',
  userName: 'Author',
  title: _cleanTitle,
  category: 'Flutter',
  content: _cleanContent,
  tags: ['helpful'],
  attachmentType: 'none',
  attachmentUrl: null,
  attachmentName: null,
  linkUrl: null,
  likeCount: 0,
  commentCount: 0,
  createdAt: null,
);

Future<void> _openEditor(
  WidgetTester tester,
  _RecordingPostService service,
  PostModerationService moderation, {
  bool editing = false,
}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NewPostScreen(
                  postService: service,
                  moderationService: moderation,
                  post: editing ? _existingPost : null,
                ),
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
  if (!editing) {
    await tester.enterText(find.byType(TextFormField).at(0), _cleanTitle);
    await tester.enterText(find.byType(TextFormField).at(1), _cleanContent);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flutter').last);
    await tester.pumpAndSettle();
  }
}

Finder _input(String field) => find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.hintText ==
          switch (field) {
            'title' => 'Enter a catchy title for your post...',
            'content' => 'Write your post content here...',
            _ => 'Add tags (e.g., Python, Tutorial, Web Development)',
          },
);

Future<void> _submit(WidgetTester tester, String label) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(label));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('moderation reports each field and reuses the loaded policy', () async {
    var loads = 0;
    final moderation = PostModerationService(
      loadFilter: () async {
        loads++;
        return BlockedWordFilter(['forbidden']);
      },
    );
    expect(
      await moderation.validatePostText(
        title: 'FORBIDDEN title',
        content: 'A forbidden phrase.',
        tags: ['helpful', 'forbidden'],
      ),
      {
        'title': _fieldError('title'),
        'content': _fieldError('content'),
        'tags': _fieldError('tags'),
      },
    );
    expect(
      await moderation.validatePostText(
        title: _cleanTitle,
        content: _cleanContent,
        tags: ['helpful'],
      ),
      isEmpty,
    );
    expect(loads, 1);
  });

  test('failed policy loads block validation and can be retried', () async {
    var loads = 0;
    final moderation = PostModerationService(
      loadFilter: () async {
        if (++loads == 1) throw const FormatException('Invalid policy');
        return BlockedWordFilter(['forbidden']);
      },
    );
    await expectLater(
      moderation.validatePostText(
        title: _cleanTitle,
        content: _cleanContent,
        tags: [],
      ),
      throwsA(isA<PostModerationUnavailable>()),
    );
    expect(
      await moderation.validatePostText(
        title: 'forbidden',
        content: _cleanContent,
        tags: [],
      ),
      {'title': _fieldError('title')},
    );
    expect(loads, 2);
  });

  for (final mode in ['published', 'draft', 'edit']) {
    for (final field in ['title', 'content', 'tags']) {
      test('$mode rejects blocked $field before Firebase or upload', () async {
        final auth = _UnusedAuth();
        final db = _UnusedFirestore();
        final service = PostService(
          firebaseAuth: auth,
          firestore: db,
          moderationService: _moderation(),
        );
        await expectLater(
          service.savePost(
            postId: mode == 'edit' ? 'existing-post' : null,
            title: field == 'title' ? 'FORBIDDEN title' : _cleanTitle,
            category: 'Flutter',
            content: field == 'content' ? 'forbidden content' : _cleanContent,
            tags: field == 'tags' ? ['helpful', 'forbidden'] : ['helpful'],
            visibility: 'public',
            status: mode == 'draft' ? 'draft' : 'published',
            attachment: PostAttachment(
              type: PostAttachmentType.image,
              file: File('nonexistent-moderation-test-image.png'),
              name: 'image.png',
            ),
          ),
          throwsA(
            isA<PostFailure>().having(
              (failure) => failure.fieldErrors,
              'field errors',
              {field: _fieldError(field)},
            ),
          ),
        );
        expect(auth.accesses, 0);
        expect(db.accesses, 0);
      });
    }
  }

  test('policy load failure prevents saving clean text', () async {
    final auth = _UnusedAuth();
    final db = _UnusedFirestore();
    final service = PostService(
      firebaseAuth: auth,
      firestore: db,
      moderationService: PostModerationService(
        loadFilter: () async => throw const FormatException('Invalid policy'),
      ),
    );
    await expectLater(
      service.savePost(
        title: _cleanTitle,
        category: 'Flutter',
        content: _cleanContent,
        tags: [],
        visibility: 'public',
        status: 'published',
      ),
      throwsA(
        isA<PostFailure>().having(
          (failure) => failure.message,
          'message',
          PostModerationService.unavailableMessage,
        ),
      ),
    );
    expect(auth.accesses, 0);
    expect(db.accesses, 0);
  });

  for (final scenario in [
    ('title', 'Post', 'published', false),
    ('content', 'Save as Draft', 'draft', false),
    ('tags', 'Save Changes', 'published', true),
  ]) {
    final (field, buttonLabel, status, editing) = scenario;
    testWidgets('$buttonLabel keeps blocked $field until corrected', (
      tester,
    ) async {
      final service = _RecordingPostService();
      await _openEditor(tester, service, _moderation(), editing: editing);
      await tester.enterText(_input('tags'), 'helpful');
      await tester.enterText(_input(field), 'forbidden');
      await _submit(tester, buttonLabel);

      expect(service.saved, isEmpty);
      expect(find.text(_fieldError(field)), findsOneWidget);
      for (final name in ['title', 'content', 'tags']) {
        expect(
          tester.widget<TextField>(_input(name)).controller!.text,
          name == field
              ? 'forbidden'
              : name == 'title'
              ? _cleanTitle
              : name == 'content'
              ? _cleanContent
              : 'helpful',
        );
        expect(tester.widget<TextField>(_input(name)).enabled, isTrue);
      }
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(
                OutlinedButton,
                editing ? 'Cancel' : 'Save as Draft',
              ),
            )
            .onPressed,
        isNotNull,
      );

      await tester.enterText(_input(field), 'Helpful replacement');
      await _submit(tester, buttonLabel);
      expect(service.saved, hasLength(1));
      expect(service.saved.single['status'], status);
      expect(service.saved.single['postId'], editing ? 'existing-post' : null);
      expect(find.text('Open editor'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('policy load failure keeps text and offers a working retry', (
    tester,
  ) async {
    var loads = 0;
    final moderation = PostModerationService(
      loadFilter: () async {
        if (++loads == 1) throw const FormatException('Invalid policy');
        return BlockedWordFilter(['forbidden']);
      },
    );
    final service = _RecordingPostService();
    await _openEditor(tester, service, moderation);
    await _submit(tester, 'Post');
    expect(service.saved, isEmpty);
    expect(find.text(PostModerationService.unavailableMessage), findsOneWidget);
    expect(
      tester.widget<TextField>(_input('title')).controller!.text,
      _cleanTitle,
    );
    expect(
      tester.widget<TextField>(_input('content')).controller!.text,
      _cleanContent,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await _submit(tester, 'Post');
    expect(loads, 2);
    expect(service.saved, hasLength(1));
    expect(find.text('Open editor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

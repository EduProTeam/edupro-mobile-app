// Test doubles exercise the existing Firebase services without credentials.
// ignore_for_file: subtype_of_sealed_class, depend_on_referenced_packages

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/home/presentation/widgets/home_post_feed.dart';
import 'package:edupro_mobile_app/features/posts/models/post_categories.dart';
import 'package:edupro_mobile_app/features/posts/presentation/screens/new_post_screen.dart';
import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_card.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryFirestore implements FirebaseFirestore {
  final documents = <String, Map<String, dynamic>>{};
  int nextId = 0;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _MemoryCollection(this, path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryCollection implements CollectionReference<Map<String, dynamic>> {
  _MemoryCollection(this.db, this.path);
  final _MemoryFirestore db;
  @override
  final String path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _MemoryReference(db, '$path/${id ?? 'post${db.nextId++}'}');

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      expect(invocation.positionalArguments.single, 'status');
      expect(invocation.namedArguments[#isEqualTo], 'published');
      return _PublishedQuery(db);
    }
    return super.noSuchMethod(invocation);
  }
}

class _MemoryReference implements DocumentReference<Map<String, dynamic>> {
  _MemoryReference(this.db, this.path);
  final _MemoryFirestore db;
  @override
  final String path;
  @override
  String get id => path.split('/').last;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    db.documents[path] = Map.of(data);
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _Snapshot(id, db.documents[path]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this.id, this.value);
  @override
  final String id;
  final Map<String, dynamic>? value;
  @override
  bool get exists => value != null;
  @override
  Map<String, dynamic>? data() => value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QueryDocument extends _Snapshot
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  _QueryDocument(super.id, Map<String, dynamic> super.value);
  @override
  Map<String, dynamic> data() => value!;
}

class _PublishedQuery implements Query<Map<String, dynamic>> {
  _PublishedQuery(this.db);
  final _MemoryFirestore db;

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.value(
    _QuerySnapshot([
      for (final entry in db.documents.entries)
        if (entry.key.startsWith('posts/') &&
            entry.value['status'] == 'published')
          _QueryDocument(entry.key.split('/').last, entry.value),
    ]),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _QuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  @override
  User get currentUser => _User();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  @override
  String get uid => 'author';
  @override
  String get displayName => 'Author';
  @override
  String get email => 'author@example.com';
  @override
  String? get photoURL => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingPostService implements PostService {
  String? savedCategory;
  String? savedStatus;

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
    savedCategory = category;
    savedStatus = status;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) =>
      FirebaseAppPlatform(
        name,
        const FirebaseOptions(
          apiKey: 'test',
          appId: 'test',
          messagingSenderId: 'test',
          projectId: 'test',
        ),
      );
}

class _AuthPlatform extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;
  @override
  UserPlatform? get currentUser => null;
  @override
  Stream<UserPlatform?> authStateChanges() => Stream.value(null);
}

PublishedPost _post(
  String id,
  Object? category, {
  List<String> tags = const [],
}) => PublishedPost.fromDocument(
  _Snapshot(id, {'title': id, 'category': ?category, 'tags': tags}),
);

Future<void> _save(PostService service, String category) => service.savePost(
  title: 'A lesson',
  category: category,
  content: 'Lesson content',
  tags: const [],
  visibility: 'public',
  status: 'published',
);

Future<void> _openEditor(
  WidgetTester tester,
  _RecordingPostService service, {
  PublishedPost? post,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NewPostScreen(postService: service, post: post),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'each category is saved to Firestore and read back by the feed',
    () async {
      final db = _MemoryFirestore();
      final service = PostService(firebaseAuth: _Auth(), firestore: db);
      for (final category in postCategories) {
        await _save(service, category);
      }
      expect(
        db.documents.values.map((data) => data['category']),
        orderedEquals(postCategories),
      );
      expect(
        (await service.watchPublishedPosts().first).map(
          (post) => post.category,
        ),
        unorderedEquals(postCategories),
      );
    },
  );

  test('missing, invalid and All categories cannot be saved', () async {
    final db = _MemoryFirestore();
    final service = PostService(firebaseAuth: _Auth(), firestore: db);
    for (final category in ['', ' ', allPostsCategory, 'Design']) {
      await expectLater(_save(service, category), throwsA(isA<PostFailure>()));
    }
    expect(db.documents, isEmpty);
  });

  test(
    'legacy category data loads safely without inventing a new category',
    () {
      for (final value in [null, '', ' ', 42]) {
        expect(_post('legacy', value).category, 'General');
      }
      expect(_post('older', 'Design').category, 'Design');
    },
  );

  testWidgets('New Post requires a selection and publishes that category', (
    tester,
  ) async {
    final service = _RecordingPostService();
    await _openEditor(tester, service);
    final dropdown = find.byType(DropdownButtonFormField<String>).first;
    final button = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: dropdown,
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(button.items!.map((item) => item.value), [
      'Programming',
      'Flutter',
      'Web Development',
      'Mobile Development',
      'UI/UX',
      'Database',
      'AI',
    ]);
    await tester.enterText(find.byType(TextFormField).at(0), 'A lesson');
    await tester.enterText(find.byType(TextFormField).at(1), 'Lesson content');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Post'));
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(service.savedCategory, isNull);
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    expect(find.text('Please select a category'), findsOneWidget);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flutter').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Post'));
    await tester.tap(find.text('Post'));
    await tester.pumpAndSettle();
    expect(service.savedCategory, 'Flutter');
    expect(service.savedStatus, 'published');
    expect(find.text('Open editor'), findsOneWidget);
  });

  testWidgets('editing a legacy post offers only supported categories', (
    tester,
  ) async {
    final service = _RecordingPostService();
    await _openEditor(tester, service, post: _post('legacy', null));
    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>).first,
    );
    expect(dropdown.initialValue, isNull);
    final button = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: find.byType(DropdownButtonFormField<String>).first,
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(button.items!.map((item) => item.value), postCategories);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home filters by saved category, keeps All and handles live posts',
    (tester) async {
      final originalCore = FirebasePlatform.instance;
      final originalAuth = FirebaseAuthPlatform.instance;
      FirebasePlatform.instance = _FirebasePlatform();
      FirebaseAuthPlatform.instance = _AuthPlatform();
      addTearDown(() {
        FirebasePlatform.instance = originalCore;
        FirebaseAuthPlatform.instance = originalAuth;
      });
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final changes = StreamController<List<PublishedPost>>();
      addTearDown(changes.close);
      final posts = [
        _post('Flutter lesson', 'Flutter'),
        _post(
          'Flutter in a web post title',
          'Web Development',
          tags: ['Flutter'],
        ),
        _post('Uncategorized lesson', null),
        _post('Older design lesson', 'Design'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePostFeed(
              postsStream: changes.stream,
              onRefresh: () async {},
              onRetry: () {},
            ),
          ),
        ),
      );
      changes.add(posts);
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsNWidgets(4));
      expect(
        tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .map((chip) => (chip.label as Text).data),
        [allPostsCategory, ...postCategories],
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Flutter'));
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsOneWidget);
      expect(
        tester.widget<PostCard>(find.byType(PostCard)).post.id,
        'Flutter lesson',
      );
      changes.add([...posts, _post('Another Flutter lesson', 'Flutter')]);
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsNWidgets(2));
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'AI'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'AI'));
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsNothing);
      expect(find.text('No posts in AI yet'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    },
  );
}

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
import 'package:flutter/rendering.dart';
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
  String content = '',
}) => PublishedPost.fromDocument(
  _Snapshot(id, {
    'title': id,
    'category': ?category,
    'content': content,
    'tags': tags,
  }),
);

void _configureHomeTest(WidgetTester tester) {
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
}

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
      _configureHomeTest(tester);
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
      expect(find.text('No posts found'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'All'), findsOneWidget);
      await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Home searches titles and content together with category and live updates',
    (tester) async {
      _configureHomeTest(tester);
      final changes = StreamController<List<PublishedPost>>();
      addTearDown(changes.close);
      final posts = [
        _post('Flutter Widgets Basics', 'Flutter'),
        _post(
          'Layout lesson',
          'Flutter',
          content: 'Build reusable WIDGETS from scratch.',
        ),
        _post('Dart futures', 'Flutter', content: 'Asynchronous programming'),
        _post('Web widgets', 'Web Development'),
        _post('Legacy lesson', null, content: 'Widgets in an older post'),
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

      final search = find.byType(TextField);
      final searchField = tester.widget<TextField>(search);
      expect(searchField.decoration!.hintText, 'Search posts...');
      expect(
        find.descendant(of: search, matching: find.byIcon(Icons.search)),
        findsOneWidget,
      );
      expect(find.byTooltip('Clear search'), findsNothing);
      expect(
        tester.getRect(search).bottom,
        lessThan(tester.getRect(find.widgetWithText(ChoiceChip, 'All')).top),
      );
      expect(
        tester.getRect(find.widgetWithText(ChoiceChip, 'All')).bottom,
        lessThan(tester.getRect(find.text('Educational Posts')).top),
      );

      Iterable<String> displayedIds() => tester
          .widgetList<PostCard>(find.byType(PostCard))
          .map((card) => card.post.id);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Flutter'));
      await tester.pumpAndSettle();
      expect(displayedIds(), [
        'Flutter Widgets Basics',
        'Layout lesson',
        'Dart futures',
      ]);
      await tester.enterText(search, ' WiDgEtS ');
      await tester.pumpAndSettle();
      expect(displayedIds(), ['Flutter Widgets Basics', 'Layout lesson']);
      expect(find.byTooltip('Clear search'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();
      expect(displayedIds(), [
        'Flutter Widgets Basics',
        'Layout lesson',
        'Web widgets',
        'Legacy lesson',
      ]);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Web Development'));
      await tester.pumpAndSettle();
      expect(displayedIds(), ['Web widgets']);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Flutter'));
      await tester.pumpAndSettle();
      expect(displayedIds(), ['Flutter Widgets Basics', 'Layout lesson']);

      await tester.enterText(search, 'no matching lesson');
      await tester.pumpAndSettle();
      expect(find.byType(PostCard), findsNothing);
      expect(find.text('No posts found'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      expect(find.byTooltip('Clear search'), findsNothing);
      expect(displayedIds(), [
        'Flutter Widgets Basics',
        'Layout lesson',
        'Dart futures',
      ]);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Flutter'))
            .selected,
        isTrue,
      );

      await tester.enterText(search, 'widget');
      await tester.pumpAndSettle();
      changes.add([
        ...posts,
        _post('Live lesson', 'Flutter', content: 'A new widget example'),
        _post('Other live lesson', 'AI', content: 'A widget example'),
      ]);
      await tester.pumpAndSettle();
      expect(displayedIds(), [
        'Flutter Widgets Basics',
        'Layout lesson',
        'Live lesson',
      ]);

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.text('Search posts...'), findsOneWidget);
      expect(find.byTooltip('Clear search'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'filters collapse down and reveal up smoothly without losing state',
    (tester) async {
      _configureHomeTest(tester);
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Home')),
            bottomNavigationBar: BottomNavigationBar(
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Feed'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
            body: HomePostFeed(
              postsStream: Stream.value([
                for (var index = 0; index < 24; index++)
                  _post(
                    'Flutter lesson $index',
                    'Flutter',
                    content: 'Widgets tutorial',
                  ),
                _post(
                  'Unrelated lesson',
                  'Web Development',
                  content: 'Widgets tutorial',
                ),
              ]),
              onRefresh: () async {},
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final search = find.byType(TextField);
      final view = find.byType(CustomScrollView);
      final verticalScrollable = find
          .descendant(of: view, matching: find.byType(Scrollable))
          .first;
      final position = tester
          .state<ScrollableState>(verticalScrollable)
          .position;
      final header = tester.renderObject<RenderSliver>(
        find.byType(SliverFloatingHeader),
      );
      final expandedHeight = header.geometry!.paintExtent;
      expect(expandedHeight, greaterThan(0));
      expect(
        find.widgetWithText(ChoiceChip, 'All').hitTestable(),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, 'Flutter'));
      await tester.enterText(search, 'Widgets');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final firstPost = find.byWidgetPredicate(
        (widget) => widget is PostCard && widget.post.id == 'Flutter lesson 0',
      );
      final firstPostTop = tester.getTopLeft(firstPost).dy;
      final headerRect = tester.getRect(find.byType(AppBar));
      final navigationRect = tester.getRect(find.byType(BottomNavigationBar));

      final downGesture = await tester.startGesture(const Offset(195, 600));
      await downGesture.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(position.pixels, greaterThan(0));
      expect(header.geometry!.paintExtent, inExclusiveRange(0, expandedHeight));
      expect(
        tester.getTopLeft(firstPost).dy,
        closeTo(firstPostTop - position.pixels, 1),
      );
      await downGesture.up();
      await tester.pumpAndSettle();
      await tester.drag(view, const Offset(0, -430));
      await tester.pumpAndSettle();
      expect(header.geometry!.paintExtent, 0);
      expect(search.hitTestable(), findsNothing);
      expect(
        find.widgetWithText(ChoiceChip, 'Flutter').hitTestable(),
        findsNothing,
      );
      expect(position.pixels, greaterThan(expandedHeight));

      final upGesture = await tester.startGesture(const Offset(195, 300));
      await upGesture.moveBy(const Offset(0, 40));
      await tester.pump();
      final partialHeight = header.geometry!.paintExtent;
      expect(partialHeight, inExclusiveRange(0, expandedHeight));
      expect(position.pixels, greaterThan(expandedHeight));
      await upGesture.up();
      await tester.pump(const Duration(milliseconds: 80));
      expect(header.geometry!.paintExtent, greaterThanOrEqualTo(partialHeight));
      await tester.pumpAndSettle();
      expect(header.geometry!.paintExtent, closeTo(expandedHeight, 1));
      expect(search.hitTestable(), findsOneWidget);
      expect(
        find.widgetWithText(ChoiceChip, 'Flutter').hitTestable(),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(search).controller!.text, 'Widgets');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Flutter'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widgetList<PostCard>(find.byType(PostCard))
            .every((card) => card.post.category == 'Flutter'),
        isTrue,
      );
      expect(tester.getRect(find.byType(AppBar)), headerRect);
      expect(tester.getRect(find.byType(BottomNavigationBar)), navigationRect);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('filters, retry and refresh remain usable in feed states', (
    tester,
  ) async {
    _configureHomeTest(tester);
    tester.view.physicalSize = const Size(390, 844);
    final changes = StreamController<List<PublishedPost>>();
    addTearDown(changes.close);
    var retries = 0;
    var refreshes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePostFeed(
            postsStream: changes.stream,
            onRefresh: () async {
              refreshes++;
            },
            onRetry: () {
              retries++;
            },
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Loading posts...'), findsOneWidget);
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    changes.addError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Unable to load posts.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
    changes.add(const []);
    await tester.pumpAndSettle();
    expect(find.text('No posts found'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(refreshes, 1);
    expect(find.byType(TextField).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

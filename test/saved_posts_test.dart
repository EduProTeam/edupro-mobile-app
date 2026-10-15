// Exercise the real services without Firebase credentials.
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_save_button.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:edupro_mobile_app/features/profile/presentation/widgets/profile_post_library.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Database implements FirebaseFirestore {
  final docs = <String, Map<String, dynamic>>{};
  final changes = StreamController<void>.broadcast(sync: true);
  final queries = <List<_Filter>>[];
  bool failWrites = false;
  int activeListeners = 0;
  int clock = 0;
  void emit() => changes.add(null);

  Stream<T> watch<T>(T Function() value) => Stream<T>.multi((controller) {
    activeListeners++;
    controller.add(value());
    final subscription = changes.stream.listen(
      (_) => controller.add(value()),
      onError: controller.addError,
    );
    controller.onCancel = () async {
      activeListeners--;
      await subscription.cancel();
    };
  });

  void write(String path, Map<String, dynamic> data) {
    docs[path] = data.map(
      (key, value) => MapEntry(
        key,
        value is FieldValue
            ? Timestamp.fromMillisecondsSinceEpoch(++clock)
            : value,
      ),
    );
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(this, path);
  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> handler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) async {
    final transaction = _Transaction(this);
    final result = await handler(transaction);
    if (failWrites) throw StateError('Offline');
    for (final write in transaction.writes) {
      write();
    }
    emit();
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Filter {
  _Filter(this.field, this.equal, this.included);
  final Object field;
  final Object? equal;
  final Iterable<Object?>? included;
}

class _Query implements Query<Map<String, dynamic>> {
  _Query(this.db, this.path, [this.filters = const []]);
  final _Database db;
  final String path;
  final List<_Filter> filters;

  _QuerySnapshot snapshot() => _QuerySnapshot([
    for (final entry in db.docs.entries)
      if (entry.key.startsWith('$path/') &&
          entry.key.split('/').length == path.split('/').length + 1 &&
          filters.every((filter) {
            final value = filter.field == FieldPath.documentId
                ? entry.key.split('/').last
                : entry.value[filter.field];
            return filter.included != null
                ? filter.included!.contains(value)
                : value == filter.equal;
          }))
        _QueryDocument(entry.key.split('/').last, Map.of(entry.value)),
  ]);

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    db.queries.add(filters);
    return db.watch(snapshot);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #where) {
      return _Query(db, path, [
        ...filters,
        _Filter(
          invocation.positionalArguments.first as Object,
          invocation.namedArguments[#isEqualTo],
          invocation.namedArguments[#whereIn] as Iterable<Object?>?,
        ),
      ]);
    }
    return super.noSuchMethod(invocation);
  }
}

class _Collection extends _Query
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(super.db, super.path);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _Reference(db, '$path/$id');
}

class _Reference implements DocumentReference<Map<String, dynamic>> {
  _Reference(this.db, this.path);
  final _Database db;
  @override
  final String path;
  @override
  String get id => path.split('/').last;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(db, '${this.path}/$path');
  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => db.watch(() => _Snapshot(id, db.docs[path]));
  @override
  Future<void> delete() async {
    if (db.failWrites) throw StateError('Offline');
    db.docs.remove(path);
    db.emit();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transaction implements Transaction {
  _Transaction(this.db);
  final _Database db;
  final writes = <void Function()>[];
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) async =>
      _Snapshot(documentReference.id, db.docs[documentReference.path])
          as DocumentSnapshot<T>;
  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    writes.add(
      () => db.write(
        documentReference.path,
        Map<String, dynamic>.from(data as Map),
      ),
    );
    return this;
  }

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

class _QuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  _QuerySnapshot(this.docs);
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Auth implements FirebaseAuth {
  @override
  User? currentUser = _User('alice');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _post(
  String owner,
  String title, {
  String status = 'published',
  int time = 1,
}) => {
  'userId': owner,
  'userName': owner,
  'title': title,
  'status': status,
  'category': 'Programming',
  'content': 'Educational content',
  'createdAt': Timestamp.fromMillisecondsSinceEpoch(time),
};

Future<void> _flush() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _LibraryService implements PostService {
  int attempts = 0;
  bool fail = false;
  List<PublishedPost> posts = [];
  @override
  Stream<List<PublishedPost>> watchMyPosts() {
    attempts++;
    return fail ? Stream.error(StateError('Offline')) : Stream.value(posts);
  }

  @override
  Stream<List<PublishedPost>> watchSavedPosts() => Stream.value([]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Database db;
  late _Auth auth;
  late PostService service;
  setUp(() {
    db = _Database();
    auth = _Auth();
    service = PostService(firebaseAuth: auth, firestore: db);
  });
  tearDown(() async => db.changes.close());

  test(
    'bookmarks persist, are idempotent, and are separate for each account',
    () async {
      db.docs['posts/lesson'] = _post('bob', 'Learn Flutter');
      await service.setPostSaved('lesson', saved: true);
      final savedAt = db.docs['users/alice/savedPosts/lesson']!['savedAt'];
      await service.setPostSaved('lesson', saved: true);
      expect(db.docs['users/alice/savedPosts/lesson']!['savedAt'], savedAt);
      expect(await service.watchPostSaved('lesson').first, isTrue);
      expect(
        await PostService(
          firebaseAuth: auth,
          firestore: db,
        ).watchPostSaved('lesson').first,
        isTrue,
      );
      auth.currentUser = _User('bob');
      expect(await service.watchPostSaved('lesson').first, isFalse);
      await service.setPostSaved('lesson', saved: true);
      await service.setPostSaved('lesson', saved: false);
      expect(db.docs.containsKey('users/bob/savedPosts/lesson'), isFalse);
      expect(db.docs.containsKey('users/alice/savedPosts/lesson'), isTrue);
      expect(db.docs['posts/lesson']!.containsKey('savedBy'), isFalse);
    },
  );

  test(
    'failed writes, missing posts, drafts and signed-out users do not save',
    () async {
      db.docs['posts/draft'] = _post('alice', 'Draft', status: 'draft');
      await expectLater(
        service.setPostSaved('draft', saved: true),
        throwsA(isA<PostFailure>()),
      );
      await expectLater(
        service.setPostSaved('missing', saved: true),
        throwsA(isA<PostFailure>()),
      );
      db.docs['posts/lesson'] = _post('bob', 'Lesson');
      db.failWrites = true;
      await expectLater(
        service.setPostSaved('lesson', saved: true),
        throwsA(isA<PostFailure>()),
      );
      expect(
        db.docs.keys.where((path) => path.contains('/savedPosts/')),
        isEmpty,
      );
      auth.currentUser = null;
      await expectLater(
        service.setPostSaved('lesson', saved: true),
        throwsA(isA<PostFailure>()),
      );
      expect(await service.watchMyPosts().first, isEmpty);
      expect(await service.watchSavedPosts().first, isEmpty);
    },
  );

  test(
    'Posts contains only this account’s published posts, newest first',
    () async {
      db.docs.addAll({
        'posts/old': _post('alice', 'Older', time: 1),
        'posts/new': _post('alice', 'Newer', time: 2),
        'posts/followers': {
          ..._post('alice', 'Followers post', time: 3),
          'visibility': 'followers',
        },
        'posts/other': _post('bob', 'Other'),
        'posts/draft': _post('alice', 'Draft', status: 'draft'),
        'posts/deleted': _post('alice', 'Deleted', status: 'deleted'),
      });
      expect((await service.watchMyPosts().first).map((post) => post.id), [
        'followers',
        'new',
        'old',
      ]);
    },
  );

  test('blank author IDs do not query any posts', () async {
    for (final userId in ['', ' ', '\n\t']) {
      expect(await service.watchPostsByUser(userId).first, isEmpty);
    }
    expect(db.queries, isEmpty);
    expect(db.activeListeners, 0);
  });

  test(
    'public author posts stay isolated and update live without followers posts',
    () async {
      db.docs.addAll({
        'posts/viewer': _post('alice', 'Viewer post', time: 99),
        'posts/old': _post('bob', 'Older author post', time: 1),
        'posts/new': _post('bob', 'Newer author post', time: 2),
        'posts/followers': {
          ..._post('bob', 'Followers post', time: 99),
          'visibility': 'followers',
        },
        'posts/draft': _post('bob', 'Author draft', status: 'draft'),
        'posts/deleted': _post('bob', 'Deleted author post', status: 'deleted'),
        'posts/other': _post('charlie', 'Another author post', time: 100),
      });
      final updates = <List<PublishedPost>>[];
      final subscription = service
          .watchPostsByUser('bob', publicOnly: true)
          .listen(updates.add);
      try {
        await _flush();
        expect(auth.currentUser!.uid, 'alice');
        expect(updates.last.map((post) => post.id), ['new', 'old']);
        expect(updates.last.every((post) => post.userId == 'bob'), isTrue);
        expect(
          (await service.watchPostsByUser('bob').first).map((post) => post.id),
          ['followers', 'new', 'old'],
        );

        // Created and published posts arrive; both deletion paths remove them.
        db.docs['posts/draft']!['status'] = 'published';
        db.docs['posts/draft']!['createdAt'] =
            Timestamp.fromMillisecondsSinceEpoch(3);
        db.docs['posts/old']!['status'] = 'deleted';
        db.docs.remove('posts/new');
        db.docs['posts/created'] = _post('bob', 'New author post', time: 4);
        db.docs['posts/another-viewer'] = _post('alice', 'New viewer post');
        db.emit();
        await _flush();
        expect(updates.last.map((post) => post.id), ['created', 'draft']);
        expect(updates.last.every((post) => post.userId == 'bob'), isTrue);

        db.docs['posts/draft']!['status'] = 'deleted';
        db.docs.remove('posts/created');
        db.emit();
        await _flush();
        expect(updates.last, isEmpty);
      } finally {
        await subscription.cancel();
      }
      expect(db.activeListeners, 0);
    },
  );

  test(
    'Saved streams batches in saved order and excludes unavailable posts',
    () async {
      for (var i = 0; i < 23; i++) {
        db.docs['posts/p$i'] = _post('bob', 'Lesson $i');
        db.docs['users/alice/savedPosts/p$i'] = {
          'postId': 'p$i',
          'savedAt': Timestamp.fromMillisecondsSinceEpoch(i),
        };
      }
      db.docs['users/bob/savedPosts/private'] = {'postId': 'private'};
      final updates = <List<PublishedPost>>[];
      final subscription = service.watchSavedPosts().listen(updates.add);
      await _flush();
      expect(updates.last.map((post) => post.id), [
        for (var i = 22; i >= 0; i--) 'p$i',
      ]);
      expect(
        db.queries
            .where((query) => query.any((filter) => filter.included != null))
            .length,
        3,
      );
      db.docs['posts/p22']!['status'] = 'deleted';
      db.docs['posts/p21']!['title'] = 'Updated title';
      db.emit();
      await _flush();
      expect(updates.last.first.id, 'p21');
      expect(updates.last.first.title, 'Updated title');
      await service.setPostSaved('p22', saved: false);
      await _flush();
      expect(db.docs.containsKey('users/alice/savedPosts/p22'), isFalse);
      await subscription.cancel();
      expect(db.activeListeners, 0);
    },
  );

  testWidgets('save, view in Saved, open and unsave work together', (
    tester,
  ) async {
    db.docs['posts/own'] = _post('alice', 'My lesson');
    db.docs['posts/other'] = _post('bob', 'A useful community post');
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                StreamBuilder<bool>(
                  stream: service.watchPostSaved('other'),
                  builder: (context, snapshot) => PostSaveButton(
                    isSaved: snapshot.data ?? false,
                    onSave: (saved) =>
                        service.setPostSaved('other', saved: saved),
                  ),
                ),
                ProfilePostLibrary(
                  postService: service,
                  onOpenPost: (post) => opened = post.id,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My lesson'), findsOneWidget);
    expect(find.text('A useful community post'), findsNothing);
    await tester.tap(find.byTooltip('Save post'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('My lesson'), findsNothing);
    await tester.tap(find.text('A useful community post'));
    expect(opened, 'other');
    await tester.tap(find.byTooltip('Remove from saved posts').last);
    await tester.pumpAndSettle();
    expect(find.text('Keep something for later'), findsOneWidget);
    await tester.tap(find.text('Posts'));
    await tester.pumpAndSettle();
    expect(find.text('My lesson'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('library retries errors and offers a first-post action', (
    tester,
  ) async {
    final library = _LibraryService()..fail = true;
    var created = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfilePostLibrary(
              postService: library,
              onCreatePost: () => created = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Could not load your posts'), findsOneWidget);
    library.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(library.attempts, 2);
    await tester.tap(find.text('Create a post'));
    expect(created, isTrue);
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Keep something for later'), findsOneWidget);
  });

  testWidgets(
    'grid shows more posts and accommodates large text on small screens',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final library = _LibraryService()
        ..posts = [
          for (var i = 0; i < 13; i++)
            PublishedPost.fromDocument(
              _Snapshot(
                'p$i',
                _post(
                  'alice',
                  'Educational lesson number $i with a descriptive title',
                ),
              ),
            ),
        ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: ProfilePostLibrary(postService: library),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-post-p12')), findsNothing);
      await tester.ensureVisible(find.text('Show more posts'));
      await tester.tap(find.text('Show more posts'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('profile-post-p12')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

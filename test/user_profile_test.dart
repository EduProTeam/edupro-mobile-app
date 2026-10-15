// Connected profile/post services are exercised without Firebase credentials.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/posts/presentation/screens/post_detail_screen.dart';
import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_actions_menu.dart';
import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_card.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:edupro_mobile_app/features/profile/presentation/screens/user_profile_screen.dart';
import 'package:edupro_mobile_app/features/profile/presentation/widgets/profile_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Profiles implements FirebaseFirestore {
  Map<String, dynamic>? profile = {
    'fullName': 'Public Author',
    'professionalTitle': 'Educator',
    'organization': 'Learning Club',
    'bio': 'Sharing useful lessons.',
    'skills': ['Flutter'],
    'learningInterests': ['Design'],
    'email': 'private-author@example.com',
    'phone': '+94123456789',
  };
  bool fail = false;
  final requestedUserIds = <String>[];

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, 'users');
    return _ProfilesCollection(this);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfilesCollection implements CollectionReference<Map<String, dynamic>> {
  _ProfilesCollection(this.profiles);
  final _Profiles profiles;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? id]) =>
      _ProfileReference(profiles, id!);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileReference implements DocumentReference<Map<String, dynamic>> {
  _ProfileReference(this.profiles, this.id);
  final _Profiles profiles;
  @override
  final String id;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    profiles.requestedUserIds.add(id);
    return profiles.fail
        ? Stream.error(StateError('Offline'))
        : Stream.value(_ProfileSnapshot(id, profiles.profile));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProfileSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _ProfileSnapshot(this.id, this.value);
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

class _Posts implements PostService {
  List<PublishedPost> posts = [];
  final requestedAuthors = <(String, bool)>[];
  final requestedDetails = <String>[];

  @override
  Stream<List<PublishedPost>> watchPostsByUser(
    String userId, {
    bool publicOnly = false,
  }) {
    requestedAuthors.add((userId, publicOnly));
    return Stream.value(posts);
  }

  @override
  Stream<PublishedPost?> watchPublishedPost(String postId) {
    requestedDetails.add(postId);
    return Stream.value(posts.firstWhere((post) => post.id == postId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PublishedPost _post(String id) => PublishedPost(
  id: id,
  userName: 'Public Author',
  title: 'Lesson $id',
  category: 'Flutter',
  content: 'Full lesson content for $id.',
  tags: const [],
  attachmentType: 'none',
  attachmentUrl: null,
  attachmentName: null,
  linkUrl: null,
  likeCount: 0,
  commentCount: 0,
  createdAt: null,
);

Future<void> _open(
  WidgetTester tester,
  _Profiles profiles,
  _Posts posts, {
  String userId = 'other-author',
}) async {
  tester.view.physicalSize = const Size(600, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: UserProfileScreen(
        userId: userId,
        fallbackName: 'Fallback author',
        firestore: profiles,
        postService: posts,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void _expectReadOnly() {
  for (final label in [
    'Edit Profile',
    'Share Profile',
    'Add Skill',
    'Add Interest',
    'Saved',
    'Create a post',
  ]) {
    expect(find.text(label), findsNothing);
  }
  expect(find.byTooltip('Settings'), findsNothing);
  expect(find.byTooltip('Change profile photo'), findsNothing);
}

void main() {
  testWidgets(
    'visitor profile shows public details and the selected author posts',
    (tester) async {
      final profiles = _Profiles();
      final posts = _Posts()..posts = [_post('one'), _post('two')];
      await _open(tester, profiles, posts);

      for (final text in [
        'Public Author',
        'Educator',
        'Learning Club',
        'Sharing useful lessons.',
        'Flutter',
        'Design',
        'Lesson one',
        'Lesson two',
      ]) {
        expect(find.text(text), findsWidgets);
      }
      expect(find.text('private-author@example.com'), findsNothing);
      expect(find.text('+94123456789'), findsNothing);
      expect(profiles.requestedUserIds, ['other-author']);
      expect(posts.requestedAuthors, isNotEmpty);
      expect(
        posts.requestedAuthors.every(
          (request) => request == ('other-author', true),
        ),
        isTrue,
      );
      final dashboard = tester.widget<ProfileDashboard>(
        find.byType(ProfileDashboard),
      );
      expect(dashboard.readOnly, isTrue);
      expect(dashboard.postCount, 2);
      _expectReadOnly();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'empty visitor posts never offer profile or post creation controls',
    (tester) async {
      await _open(tester, _Profiles(), _Posts(), userId: 'selected-author');
      final dashboard = tester.widget<ProfileDashboard>(
        find.byType(ProfileDashboard),
      );
      expect(dashboard.postCount, 0);
      expect(dashboard.readOnly, isTrue);
      _expectReadOnly();
      expect(find.text('No public posts yet'), findsOneWidget);
      expect(find.text('Share your first post'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing author does not show fallback personal details', (
    tester,
  ) async {
    await _open(tester, _Profiles()..profile = null, _Posts());
    expect(find.byType(ProfileDashboard), findsNothing);
    expect(find.text('Fallback author'), findsNothing);
    expect(find.text('This profile is no longer available.'), findsOneWidget);
    _expectReadOnly();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'profile loading failure can be retried without editing controls',
    (tester) async {
      final profiles = _Profiles()..fail = true;
      await _open(tester, profiles, _Posts());
      expect(find.byType(ProfileDashboard), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
      _expectReadOnly();

      profiles.fail = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(profiles.requestedUserIds, ['other-author', 'other-author']);
      expect(find.text('Public Author'), findsOneWidget);
      _expectReadOnly();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('visitor post opens a read-only detail without owner actions', (
    tester,
  ) async {
    final posts = _Posts()..posts = [_post('one')];
    await _open(tester, _Profiles(), posts);
    await tester.ensureVisible(find.text('Lesson one'));
    await tester.tap(find.text('Lesson one'));
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailScreen), findsOneWidget);
    expect(
      tester.widget<PostDetailScreen>(find.byType(PostDetailScreen)).readOnly,
      isTrue,
    );
    expect(tester.widget<PostCard>(find.byType(PostCard)).readOnly, isTrue);
    expect(find.text('Full lesson content for one.'), findsOneWidget);
    expect(posts.requestedDetails, ['one']);
    expect(find.byType(PostActionsMenu), findsNothing);
    expect(find.byTooltip('Save post'), findsNothing);
    expect(find.byTooltip('Like post'), findsNothing);
    expect(find.byTooltip('View comments'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

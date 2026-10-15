import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edupro_mobile_app/features/home/models/home_feed_filter.dart';
import 'package:edupro_mobile_app/features/posts/services/post_service.dart';
import 'package:flutter_test/flutter_test.dart';

PublishedPost post(
  String id, {
  String? owner,
  String author = 'A learner',
  String category = 'Flutter',
  List<String> tags = const [],
  int likes = 0,
  int comments = 0,
  int time = 0,
}) => PublishedPost(
  id: id,
  userId: owner,
  userName: author,
  title: 'Lesson $id',
  category: category,
  content: 'Learning together',
  tags: tags,
  attachmentType: 'none',
  attachmentUrl: null,
  attachmentName: null,
  linkUrl: null,
  likeCount: likes,
  commentCount: comments,
  createdAt: Timestamp.fromMillisecondsSinceEpoch(time),
);

void main() {
  test(
    'search combines topics, tags, authors and existing category selection',
    () {
      final posts = [
        post('1', author: 'Nethmi Fernando'),
        post('2', tags: ['StateManagement']),
        post('3', category: 'Database'),
      ];
      expect(filterHomePosts(posts, query: ' nEtHmI ').map((p) => p.id), ['1']);
      expect(filterHomePosts(posts, query: 'state').map((p) => p.id), ['2']);
      expect(filterHomePosts(posts, query: 'database').map((p) => p.id), ['3']);
      expect(
        filterHomePosts(posts, query: 'database', category: 'Flutter'),
        isEmpty,
      );
    },
  );

  test(
    'My Posts shows only the current account and is empty when signed out',
    () {
      final posts = [
        post('1', owner: 'me'),
        post('2', owner: 'other'),
        post('3'),
      ];
      expect(
        filterHomePosts(
          posts,
          view: HomeFeedView.mine,
          currentUserId: 'me',
        ).map((p) => p.id),
        ['1'],
      );
      expect(filterHomePosts(posts, view: HomeFeedView.mine), isEmpty);
    },
  );

  test(
    'Popular ranks real engagement, breaks ties by date, and preserves input',
    () {
      final posts = [
        post('1', likes: 2),
        post('2', likes: 8),
        post('3', likes: 5, comments: 3, time: 2),
      ];
      expect(
        filterHomePosts(posts, view: HomeFeedView.popular).map((p) => p.id),
        ['3', '2', '1'],
      );
      expect(posts.map((p) => p.id), ['1', '2', '3']);
      expect(filterHomePosts(posts).map((p) => p.id), ['1', '2', '3']);
    },
  );
}

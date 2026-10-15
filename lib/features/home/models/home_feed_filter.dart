import '../../posts/models/post_categories.dart';
import '../../posts/services/post_service.dart';

enum HomeFeedView { all, popular, mine }

List<PublishedPost> filterHomePosts(
  List<PublishedPost> posts, {
  String query = '',
  String category = allPostsCategory,
  HomeFeedView view = HomeFeedView.all,
  String? currentUserId,
}) {
  final keyword = query.trim().toLowerCase();
  final filtered = posts.where((post) {
    if (view == HomeFeedView.mine &&
        (currentUserId == null || post.userId != currentUserId)) {
      return false;
    }
    if (category != allPostsCategory && post.category != category) return false;
    return keyword.isEmpty ||
        [
          post.title,
          post.content,
          post.userName,
          post.category,
          ...post.tags,
        ].any((value) => value.toLowerCase().contains(keyword));
  }).toList();
  if (view == HomeFeedView.popular) {
    filtered.sort((a, b) {
      final score = (b.likeCount + b.commentCount).compareTo(
        a.likeCount + a.commentCount,
      );
      if (score != 0) return score;
      final time = (b.createdAt?.millisecondsSinceEpoch ?? 0).compareTo(
        a.createdAt?.millisecondsSinceEpoch ?? 0,
      );
      return time == 0 ? a.id.compareTo(b.id) : time;
    });
  }
  return filtered;
}

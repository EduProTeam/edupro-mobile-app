import '../../../core/sharing/link_share_service.dart';
import '../models/post_link.dart';

class PostShareService {
  PostShareService({
    Future<bool> Function(Uri)? openUrl,
    Future<void> Function(String)? copyText,
  }) : _sharing = LinkShareService(
         linkLabel: 'post link',
         openUrl: openUrl,
         copyText: copyText,
       );

  final LinkShareService _sharing;

  Future<void> message(String postId, String postTitle) =>
      _share(() => _sharing.message(_shareText(postId, postTitle)));

  Future<void> whatsapp(String postId, String postTitle) =>
      _share(() => _sharing.whatsapp(_shareText(postId, postTitle)));

  Future<void> copyLink(String postId) =>
      _share(() => _sharing.copyLink(_link(postId)));

  Future<void> _share(Future<void> Function() action) async {
    try {
      await action();
    } on LinkShareFailure catch (error) {
      throw PostShareFailure(error.message);
    }
  }

  String _shareText(String postId, String postTitle) {
    final title = postTitle.trim().isEmpty ? 'this post' : postTitle.trim();
    return 'View $title on EduPro:\n${_link(postId)}';
  }

  Uri _link(String postId) {
    try {
      return PostLink.forPost(postId);
    } catch (_) {
      throw const PostShareFailure(
        'Unable to create this post link. Please try again.',
      );
    }
  }
}

class PostShareFailure extends LinkShareFailure {
  const PostShareFailure(super.message);
}

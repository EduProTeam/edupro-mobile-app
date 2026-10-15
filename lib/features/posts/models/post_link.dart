/// Creates and validates links to a single EduPro post.
abstract final class PostLink {
  static final _appPrefix = RegExp(r'^edupro://app/', caseSensitive: false);
  static final _postPath = RegExp(r'^/post/([^/?#]+)$');
  static final _controlCharacters = RegExp(r'[\p{Cc}\p{Cf}]', unicode: true);
  static final _rawWhitespace = RegExp(r'\s', unicode: true);

  /// Returns an app link with the post ID encoded as one path segment.
  ///
  /// Throws [ArgumentError] when the ID cannot safely name a post document.
  static Uri forPost(String postId) {
    if (!_isSafePostId(postId)) {
      throw ArgumentError.value(postId, 'postId', 'Invalid post ID.');
    }
    return Uri(scheme: 'edupro', host: 'app', pathSegments: ['post', postId]);
  }

  /// Accepts an EduPro app link, `/post/id`, or `/#/post/id`.
  ///
  /// Validate the raw path before decoding so URI normalization cannot hide
  /// traversal components or extra segments. IDs are decoded only once.
  static String? postIdFromRoute(String? route) {
    if (route == null ||
        route.isEmpty ||
        _controlCharacters.hasMatch(route) ||
        _rawWhitespace.hasMatch(route)) {
      return null;
    }

    var path = route;
    if (route.startsWith('/#/')) {
      path = route.substring(2);
    } else if (!route.startsWith('/')) {
      final prefix = _appPrefix.firstMatch(route);
      if (prefix == null) return null;
      path = route.substring(prefix.end - 1);
    }
    final match = _postPath.firstMatch(path);
    if (match == null) return null;

    try {
      final postId = Uri.decodeComponent(match.group(1)!);
      return _isSafePostId(postId) ? postId : null;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static bool _isSafePostId(String postId) =>
      postId.trim().isNotEmpty &&
      postId != '.' &&
      postId != '..' &&
      !postId.contains('/') &&
      !postId.contains(r'\') &&
      !_controlCharacters.hasMatch(postId);
}

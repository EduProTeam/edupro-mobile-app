/// Creates and validates links to a single EduPro profile.
abstract final class ProfileLink {
  static final _appPrefix = RegExp(r'^edupro://app/', caseSensitive: false);
  static final _profilePath = RegExp(r'^/profile/([^/?#]+)$');
  static final _controlCharacters = RegExp(r'[\p{Cc}\p{Cf}]', unicode: true);
  static final _rawWhitespace = RegExp(r'\s', unicode: true);

  /// Returns an app link with the user ID encoded as one path segment.
  ///
  /// Throws [ArgumentError] when the ID cannot safely name a profile document.
  static Uri forUser(String userId) {
    if (!_isSafeUserId(userId)) {
      throw ArgumentError.value(userId, 'userId', 'Invalid profile user ID.');
    }
    return Uri(
      scheme: 'edupro',
      host: 'app',
      pathSegments: ['profile', userId],
    );
  }

  /// Accepts an EduPro app link, `/profile/id`, or `/#/profile/id`.
  ///
  /// Invalid links return null. The raw path is checked before decoding so URI
  /// normalization cannot hide additional segments or traversal components.
  static String? userIdFromRoute(String? route) {
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
    final match = _profilePath.firstMatch(path);
    if (match == null) return null;

    try {
      final userId = Uri.decodeComponent(match.group(1)!);
      return _isSafeUserId(userId) ? userId : null;
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static bool _isSafeUserId(String userId) =>
      userId.trim().isNotEmpty &&
      userId != '.' &&
      userId != '..' &&
      !userId.contains('/') &&
      !userId.contains(r'\') &&
      !_controlCharacters.hasMatch(userId);
}

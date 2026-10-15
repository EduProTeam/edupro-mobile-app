/// A configurable literal-word filter shared by the app and Firestore rules.
///
/// Entries can contain Unicode letters, combining marks, numbers, and spaces.
/// The generated expression uses only features supported by Dart and RE2.
/// Pass an empty list to explicitly disable filtering.
class BlockedWordFilter {
  BlockedWordFilter(Iterable<String> blockedWords)
    : pattern = _buildPattern(blockedWords) {
    _expression = RegExp(pattern, unicode: true);
  }

  factory BlockedWordFilter.fromJson(Map<String, dynamic> configuration) {
    final words = configuration['blockedWords'];
    if (words is! List || words.any((word) => word is! String)) {
      throw const FormatException('blockedWords must be a list of strings.');
    }
    return BlockedWordFilter(words.cast<String>());
  }

  /// Apply this expression to lowercased text with Unicode mode enabled.
  final String pattern;

  bool get enabled => pattern != 'a^';

  late final RegExp _expression;

  /// Firestore's matches() checks the entire string instead of a substring.
  String get firestorePattern => '(?s).*$pattern.*';

  bool containsBlockedWord(String text) =>
      _expression.hasMatch(text.toLowerCase());

  static const _wordCharacter = r'\p{L}\p{M}\p{N}';
  static const _separator = '[^$_wordCharacter]';

  static final _validEntry = RegExp(
    '^[$_wordCharacter]+(?: +[$_wordCharacter]+)*\$',
    unicode: true,
  );

  static const _leetLetters = <String, String>{
    'a': '[a@4]',
    'e': '[e3]',
    'i': '[i1!]',
    'o': '[o0]',
    's': r'[s$5]',
    't': '[t7]',
  };

  static String _buildPattern(Iterable<String> blockedWords) {
    final entries = <String>{};
    for (final value in blockedWords) {
      final entry = value.trim().toLowerCase();
      if (!_validEntry.hasMatch(entry)) {
        throw const FormatException(
          'Blocked words must contain letters, marks, numbers, and spaces only.',
        );
      }
      entries.add(entry.replaceAll(RegExp(' +'), ' '));
    }
    // This cannot match: an "a" cannot precede the start of a string.
    // Unlike a negative lookahead, it is also supported by Firestore's RE2.
    if (entries.isEmpty) return 'a^';

    final alternatives = entries.map((entry) {
      return entry
          .split(' ')
          .map((word) {
            return word.runes
                .map(String.fromCharCode)
                .map((letter) => _leetLetters[letter] ?? letter)
                .join('$_separator*');
          })
          .join('$_separator+');
    });
    return '(^|$_separator)(?:${alternatives.join('|')})(\$|$_separator)';
  }
}

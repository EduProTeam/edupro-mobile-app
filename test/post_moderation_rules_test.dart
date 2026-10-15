import 'dart:convert';
import 'dart:io';

import 'package:edupro_mobile_app/features/posts/models/blocked_word_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/sync_post_moderation.dart';

BlockedWordFilter _configuredFilter() {
  final configuration =
      jsonDecode(
            File('assets/moderation/blocked_words.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  return BlockedWordFilter.fromJson(configuration);
}

String _patternFromGeneratedBody(BlockedWordFilter filter) {
  final body = generatePostModerationRulesBody(filter);
  final literal = RegExp(
    r'let blockedPattern = ("(?:[^"\\]|\\.)*");',
  ).firstMatch(body)!.group(1)!;
  return jsonDecode(literal) as String;
}

// Dart expresses RE2's (?s) flag through dotAll. Keep the full-match check,
// because Firestore String.matches checks the whole input string.
bool _matchesGeneratedPattern(String pattern, String text) {
  expect(pattern.startsWith('(?s)'), isTrue);
  final expression = RegExp(pattern.substring(4), unicode: true, dotAll: true);
  final normalized = text.toLowerCase();
  final match = expression.matchAsPrefix(normalized);
  return match != null && match.end == normalized.length;
}

void main() {
  test(
    'checked-in Firestore rules are synchronized with the configured list',
    () {
      final rules = File('firestore.rules').readAsStringSync();
      expect(synchronizePostModerationRules(rules, _configuredFilter()), rules);
    },
  );

  test(
    'generated full-string regex preserves app matching across multiline text',
    () {
      final filter = BlockedWordFilter.fromJson({
        'blockedWords': ['badword', 'bad phrase', 'නරක', 'கெட்ட'],
      });
      final pattern = _patternFromGeneratedBody(filter);
      final cases = <String, bool>{
        'a helpful lesson': false,
        'BADWORD': true,
        'first line\nbadword\nlast line': true,
        'b.a.d.w.o.r.d': true,
        'b@dw0rd': true,
        'bad\nphrase': true,
        'prefixbadwordsuffix': false,
        'notbad phrasebook': false,
        'නරක': true,
        'prefixනරකsuffix': false,
        'ஒரு கெட்ட சொல்': true,
        'நல்லகெட்டசொல்': false,
      };
      for (final entry in cases.entries) {
        expect(
          filter.containsBlockedWord(entry.key),
          entry.value,
          reason: entry.key,
        );
        expect(
          _matchesGeneratedPattern(pattern, entry.key),
          entry.value,
          reason: 'Generated rules pattern: ${entry.key}',
        );
      }
    },
  );

  test('every configured word is present in the generated rules pattern', () {
    final configuration =
        jsonDecode(
              File('assets/moderation/blocked_words.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final filter = BlockedWordFilter.fromJson(configuration);
    if (!filter.enabled) {
      expect(generatePostModerationRulesBody(filter), contains('is disabled'));
      return;
    }
    final pattern = _patternFromGeneratedBody(filter);
    for (final word in (configuration['blockedWords'] as List).cast<String>()) {
      expect(_matchesGeneratedPattern(pattern, 'Before $word after'), isTrue);
    }
  });

  test(
    'synchronization preserves unrelated rules and the original line endings',
    () {
      final filter = BlockedWordFilter.fromJson({
        'blockedWords': ['badword'],
      });
      for (final newline in ['\n', '\r\n']) {
        final prefix = 'unrelated prefix$newline$postModerationStartMarker';
        const suffix = '$postModerationEndMarker\nunrelated suffix';
        final existing = '$prefix${newline}old body$newline$suffix';
        final synchronized = synchronizePostModerationRules(existing, filter);
        expect(synchronized.startsWith('$prefix$newline'), isTrue);
        expect(synchronized.endsWith(suffix), isTrue);
        expect(synchronized, isNot(contains('old body')));
        expect(
          synchronizePostModerationRules(synchronized, filter),
          synchronized,
        );
      }
    },
  );

  test('empty configuration disables only word matching', () {
    final filter = BlockedWordFilter.fromJson({'blockedWords': <String>[]});
    final body = generatePostModerationRulesBody(filter);
    expect(body, contains('text filtering is disabled'));
    expect(body, contains('data.title is string'));
    expect(body, contains('data.content is string'));
    expect(body, contains('data.tags is list'));
    expect(body, isNot(contains('.matches(')));
  });

  test('missing or duplicate generation markers are rejected', () {
    final filter = BlockedWordFilter.fromJson({
      'blockedWords': ['badword'],
    });
    final valid = '$postModerationStartMarker\nbody\n$postModerationEndMarker';
    for (final rules in [
      'no markers',
      '$postModerationEndMarker\n$postModerationStartMarker',
      '$valid\n$postModerationStartMarker',
      '$valid\n$postModerationEndMarker',
    ]) {
      expect(
        () => synchronizePostModerationRules(rules, filter),
        throwsFormatException,
      );
    }
  });
}

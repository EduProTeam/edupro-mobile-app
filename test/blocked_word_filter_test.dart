import 'dart:convert';
import 'dart:io';

import 'package:edupro_mobile_app/features/posts/models/blocked_word_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late BlockedWordFilter filter;

  setUp(() {
    final configuration =
        jsonDecode(
              File('assets/moderation/blocked_words.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    filter = BlockedWordFilter.fromJson(configuration);
  });

  test('blocks configured words at the beginning, middle, and end', () {
    for (final text in [
      'fuck',
      'FUCK!',
      'shit happens',
      'This is bullshit.',
      'a fucking example',
      'you fucker',
      'motherfucker',
      'shitty',
      'bitch',
      'bastard',
      'asshole',
      'cunt',
      'first line\nshit\nlast line',
    ]) {
      expect(filter.containsBlockedWord(text), isTrue, reason: text);
    }
  });

  test('recognizes leet spelling and inserted separators', () {
    for (final text in [
      'sh1t',
      'sh!t',
      r'$h!7',
      'b1tch',
      'b@st@rd',
      '@ssh0l3',
      '4ssh0l3',
      'f.u.c.k',
      'F U C K',
      'f-u_c*k',
      'f\u200Bu\u200Cc\u200Dk',
      's\nh\ni\nt',
    ]) {
      expect(filter.containsBlockedWord(text), isTrue, reason: text);
    }
  });

  test('allows ordinary words and rejects substring matches', () {
    for (final text in [
      '',
      'A useful class assignment.',
      'passage',
      'ass',
      'classic',
      'The assistant helped with the assessment.',
      'Scunthorpe',
      'shitake',
      'fuckery',
      '1fuck2',
      'caféfuck',
      'fuck\u0301',
      'සිංහලfuck',
      'fuckதமிழ்',
    ]) {
      expect(filter.containsBlockedWord(text), isFalse, reason: text);
    }
  });

  test('supports configured Unicode words and phrases', () {
    // These neutral words only demonstrate configurable script support.
    // The bundled default list contains English words only.
    final configured = BlockedWordFilter([
      'සිංහල',
      'தமிழ்',
      '  Bad   Phrase  ',
    ]);
    for (final text in [
      'සිංහල',
      'මෙය සිංහල වේ',
      'தமிழ்',
      'இது தமிழ் மொழி',
      'a BAD PHRASE here',
      'bad-phrase',
      'b.a.d p.h.r.a.s.e',
    ]) {
      expect(configured.containsBlockedWord(text), isTrue, reason: text);
    }
    for (final text in ['සිංහලය', 'தமிழ்மொழி', 'badphrase', 'bad phrases']) {
      expect(configured.containsBlockedWord(text), isFalse, reason: text);
    }
  });

  test('empty configuration explicitly disables the filter', () {
    final disabled = BlockedWordFilter.fromJson({'blockedWords': <String>[]});
    expect(disabled.containsBlockedWord('fuck\nshit'), isFalse);
    expect(RegExp(disabled.pattern, unicode: true).hasMatch('a'), isFalse);
  });

  test('rejects malformed configuration and regex metacharacter entries', () {
    for (final configuration in <Map<String, dynamic>>[
      {},
      {'blockedWords': null},
      {'blockedWords': 'fuck'},
      {
        'blockedWords': ['fuck', 123],
      },
      {
        'blockedWords': [''],
      },
      {
        'blockedWords': ['   '],
      },
      {
        'blockedWords': ['f.*k'],
      },
      {
        'blockedWords': ['bad|word'],
      },
      {
        'blockedWords': ['bad\nword'],
      },
    ]) {
      expect(
        () => BlockedWordFilter.fromJson(configuration),
        throwsFormatException,
        reason: configuration.toString(),
      );
    }
  });

  test('exports the same lowercase Unicode pattern for app and rules', () {
    expect(filter.firestorePattern, '(?s).*${filter.pattern}.*');
    final expression = RegExp(filter.pattern, unicode: true);
    expect(expression.hasMatch('F.U.C.K'.toLowerCase()), isTrue);
    expect(expression.hasMatch('class assignment'), isFalse);
  });
}

import 'package:edupro_mobile_app/features/profile/models/profile_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('creates a profile app link with one encoded user ID segment', () {
    final link = ProfileLink.forUser('learner id?#%+தமிழ்');

    expect(link.scheme, 'edupro');
    expect(link.host, 'app');
    expect(link.pathSegments, ['profile', 'learner id?#%+தமிழ்']);
    expect(link.hasQuery, isFalse);
    expect(link.hasFragment, isFalse);
    expect(link.toString(), contains('learner%20id%3F%23%25'));
    expect(ProfileLink.userIdFromRoute(link.toString()), 'learner id?#%+தமிழ்');
  });

  test('supports app, relative, and web fragment profile routes', () {
    for (final route in [
      'edupro://app/profile/alice',
      'EDUPRO://APP/profile/alice',
      '/profile/alice',
      '/#/profile/alice',
    ]) {
      expect(ProfileLink.userIdFromRoute(route), 'alice', reason: route);
    }
    expect(ProfileLink.userIdFromRoute('/profile/a%20b'), 'a b');
    expect(ProfileLink.userIdFromRoute('/profile/alice+tag'), 'alice+tag');
  });

  test(
    'decodes an ID exactly once without turning percent text into a path',
    () {
      final link = ProfileLink.forUser('literal%2Fuser');
      expect(link.toString(), 'edupro://app/profile/literal%252Fuser');
      expect(ProfileLink.userIdFromRoute(link.toString()), 'literal%2Fuser');
    },
  );

  test('rejects unrelated schemes, hosts, authorities, and routes', () {
    for (final route in <String?>[
      null,
      '',
      '/',
      '/profile',
      'profile/alice',
      'https://app/profile/alice',
      'http://app/profile/alice',
      'other://app/profile/alice',
      'edupro://other/profile/alice',
      'edupro://app.evil/profile/alice',
      'edupro://user@app/profile/alice',
      'edupro://app:123/profile/alice',
      'edupro:/profile/alice',
      '//app/profile/alice',
      'edupro://app/PROFILE/alice',
      'edupro://app/other/alice',
      '/PROFILE/alice',
      '/other/alice',
      '/prefix/../profile/alice',
      'edupro://app/prefix/../profile/alice',
      '/profile/alice?edit=true',
      'edupro://app/profile/alice?',
      '/profile/alice#other',
      'edupro://app/profile/alice#',
      '/#/profile/alice?edit=true',
      '/#/profile/alice#other',
      ' /profile/alice',
      '/profile/alice ',
    ]) {
      expect(ProfileLink.userIdFromRoute(route), isNull, reason: route);
    }
  });

  test(
    'rejects empty, malformed, nested, traversal, and control-character IDs',
    () {
      for (final suffix in [
        '',
        '%20%20',
        'alice/',
        'alice/bob',
        'alice%2Fbob',
        'alice%2fbob',
        r'alice\bob',
        'alice%5Cbob',
        '.',
        '..',
        '%2E',
        '%2e%2e',
        '%',
        '%ZZ',
        '%E0%A4',
        'alice\n',
        'alice%00',
        'alice%0A',
        'alice%7F',
        'alice%C2%85',
        'alice%E2%80%AE',
      ]) {
        for (final prefix in [
          'edupro://app/profile/',
          '/profile/',
          '/#/profile/',
        ]) {
          final route = '$prefix$suffix';
          expect(ProfileLink.userIdFromRoute(route), isNull, reason: route);
        }
      }
    },
  );

  test('cannot generate an unsafe profile link', () {
    for (final userId in [
      '',
      '   ',
      '.',
      '..',
      'alice/bob',
      r'alice\bob',
      'alice\u0000',
      'alice\n',
      'alice\u007F',
      'alice\u0085',
      'alice\u202E',
    ]) {
      expect(
        () => ProfileLink.forUser(userId),
        throwsArgumentError,
        reason: userId,
      );
    }
  });
}

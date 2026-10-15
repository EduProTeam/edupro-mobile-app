import 'package:edupro_mobile_app/features/posts/models/post_link.dart';
import 'package:edupro_mobile_app/features/profile/models/profile_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('post app links encode a document ID as one path segment', () {
    const id = 'lesson id?#%+தமிழ்';
    final link = PostLink.forPost(id);
    expect(link.scheme, 'edupro');
    expect(link.host, 'app');
    expect(link.pathSegments, ['post', id]);
    expect(link.hasQuery, isFalse);
    expect(link.hasFragment, isFalse);
    expect(PostLink.postIdFromRoute(link.toString()), id);
  });

  test('post parser accepts app, relative, and web fragment links', () {
    for (final route in [
      'edupro://app/post/lesson',
      'EDUPRO://APP/post/lesson',
      '/post/lesson',
      '/#/post/lesson',
    ]) {
      expect(PostLink.postIdFromRoute(route), 'lesson', reason: route);
    }
    expect(PostLink.postIdFromRoute('/post/a%20b'), 'a b');
    expect(PostLink.postIdFromRoute('/post/lesson+tag'), 'lesson+tag');
  });

  test('post IDs are decoded once and profile links stay separate', () {
    final link = PostLink.forPost('literal%2Fpost');
    expect(link.toString(), 'edupro://app/post/literal%252Fpost');
    expect(PostLink.postIdFromRoute(link.toString()), 'literal%2Fpost');
    expect(PostLink.postIdFromRoute('edupro://app/profile/author'), isNull);
    expect(ProfileLink.userIdFromRoute(link.toString()), isNull);
  });

  test('unrelated or modified post routes are rejected', () {
    for (final route in <String?>[
      null,
      '',
      '/',
      '/post',
      'post/lesson',
      'https://app/post/lesson',
      'other://app/post/lesson',
      'edupro://other/post/lesson',
      'edupro://app.evil/post/lesson',
      'edupro://user@app/post/lesson',
      'edupro://app:123/post/lesson',
      'edupro:/post/lesson',
      '//app/post/lesson',
      '/POST/lesson',
      '/prefix/../post/lesson',
      'edupro://app/prefix/../post/lesson',
      '/post/lesson?edit=true',
      'edupro://app/post/lesson?',
      '/post/lesson#other',
      '/post/lesson#',
      '/#/post/lesson?edit=true',
      '/#/post/lesson#other',
      ' /post/lesson',
      '/post/lesson ',
    ]) {
      expect(PostLink.postIdFromRoute(route), isNull, reason: route);
    }
  });

  test('unsafe post document IDs cannot be received or generated', () {
    for (final suffix in [
      '',
      '%20%20',
      'lesson/',
      'lesson/other',
      'lesson%2Fother',
      'lesson%2fother',
      r'lesson\other',
      'lesson%5Cother',
      '.',
      '..',
      '%2E',
      '%2e%2e',
      '%',
      '%ZZ',
      '%E0%A4',
      'lesson\n',
      'lesson%00',
      'lesson%0A',
      'lesson%7F',
      'lesson%C2%85',
      'lesson%E2%80%AE',
    ]) {
      for (final prefix in ['edupro://app/post/', '/post/', '/#/post/']) {
        final route = '$prefix$suffix';
        expect(PostLink.postIdFromRoute(route), isNull, reason: route);
      }
    }
    for (final id in [
      '',
      '   ',
      '.',
      '..',
      'lesson/other',
      r'lesson\other',
      'lesson\u0000',
      'lesson\n',
      'lesson\u007F',
      'lesson\u0085',
      'lesson\u202E',
    ]) {
      expect(() => PostLink.forPost(id), throwsArgumentError, reason: id);
    }
  });
}

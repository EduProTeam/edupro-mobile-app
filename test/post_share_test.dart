import 'package:edupro_mobile_app/features/posts/models/post_link.dart';
import 'package:edupro_mobile_app/features/posts/presentation/widgets/post_share_sheet.dart';
import 'package:edupro_mobile_app/features/posts/services/post_share_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _postId = 'post +&?%#தமிழ்';
const _postTitle = 'Flutter & UI? සිංහල #+';
String get _link => PostLink.forPost(_postId).toString();
String get _message => 'View $_postTitle on EduPro:\n$_link';

Future<void> _openSheet(
  WidgetTester tester,
  PostShareService service, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(320, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPostShareSheet(
              context,
              postId: _postId,
              postTitle: _postTitle,
              service: service,
            ),
            child: const Text('Open share menu'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open share menu'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'post Message includes the selected title and link with safe encoding',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final launched = <Uri>[];
      await PostShareService(
        openUrl: (uri) async {
          launched.add(uri);
          return true;
        },
      ).message(_postId, _postTitle);
      expect(launched, hasLength(1));
      expect(launched.single.scheme, 'sms');
      expect(launched.single.queryParameters, {'body': _message});
      expect(launched.single.toString(), contains('%20'));
      expect(launched.single.toString(), isNot(contains('+')));
    },
  );

  test('post WhatsApp app and fallback share the same selected post', () async {
    final launched = <Uri>[];
    await PostShareService(
      openUrl: (uri) async {
        launched.add(uri);
        return launched.length == 2;
      },
    ).whatsapp(_postId, _postTitle);
    expect(launched.map((uri) => uri.scheme), ['whatsapp', 'https']);
    expect(launched.last.host, 'wa.me');
    for (final uri in launched) {
      expect(uri.queryParameters, {'text': _message});
    }
  });

  test('post Copy Link copies only its URI', () async {
    final copied = <String>[];
    await PostShareService(
      copyText: (text) async => copied.add(text),
    ).copyLink(_postId);
    expect(copied, [_link]);
    expect(copied.single, isNot(contains(_postTitle)));
  });

  test(
    'post launch and clipboard failures remain typed and actionable',
    () async {
      final service = PostShareService(
        openUrl: (_) async => false,
        copyText: (_) async => throw PlatformException(code: 'unavailable'),
      );
      for (final action in [
        () => service.message(_postId, _postTitle),
        () => service.whatsapp(_postId, _postTitle),
        () => service.copyLink(_postId),
      ]) {
        await expectLater(
          action(),
          throwsA(
            isA<PostShareFailure>().having(
              (failure) => failure.message,
              'message',
              contains('post link'),
            ),
          ),
        );
      }
    },
  );

  test('invalid post IDs never open a composer or copy a wrong link', () async {
    var actions = 0;
    final service = PostShareService(
      openUrl: (_) async {
        actions++;
        return true;
      },
      copyText: (_) async {
        actions++;
      },
    );
    await expectLater(
      service.message('', _postTitle),
      throwsA(isA<PostShareFailure>()),
    );
    await expectLater(service.copyLink(''), throwsA(isA<PostShareFailure>()));
    expect(actions, 0);
  });

  for (final option in ['Message', 'WhatsApp', 'Copy Link']) {
    testWidgets('post $option option shares only the selected post', (
      tester,
    ) async {
      final launched = <Uri>[];
      final copied = <String>[];
      await _openSheet(
        tester,
        PostShareService(
          openUrl: (uri) async {
            launched.add(uri);
            return true;
          },
          copyText: (text) async => copied.add(text),
        ),
      );
      expect(find.text('Share Post'), findsOneWidget);
      expect(
        tester
            .widgetList<ListTile>(find.byType(ListTile))
            .map((tile) => (tile.title as Text).data),
        ['Message', 'WhatsApp', 'Copy Link'],
      );
      await tester.tap(find.text(option));
      await tester.pumpAndSettle();
      if (option == 'Copy Link') {
        expect(copied, [_link]);
        expect(launched, isEmpty);
        expect(find.text('Post link copied.'), findsOneWidget);
      } else {
        expect(copied, isEmpty);
        expect(launched, hasLength(1));
        expect(
          launched.single.scheme,
          option == 'Message' ? 'sms' : 'whatsapp',
        );
        expect(launched.single.queryParameters.values.single, _message);
      }
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'failed post share leaves retry and Copy Link usable with large text',
    (tester) async {
      var launches = 0;
      final copied = <String>[];
      await _openSheet(
        tester,
        PostShareService(
          openUrl: (_) async {
            launches++;
            return false;
          },
          copyText: (text) async => copied.add(text),
        ),
        textScale: 2,
      );
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(
        find.text('Unable to open WhatsApp. Try again or copy the post link.'),
        findsWidgets,
      );
      expect(
        tester
            .widgetList<ListTile>(find.byType(ListTile))
            .every((tile) => tile.enabled),
        isTrue,
      );
      await tester.ensureVisible(find.text('WhatsApp'));
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();
      expect(launches, 4);
      await tester.ensureVisible(find.text('Copy Link'));
      await tester.tap(find.text('Copy Link'));
      await tester.pumpAndSettle();
      expect(copied, [_link]);
      expect(find.text('Post link copied.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

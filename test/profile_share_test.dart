import 'dart:async';

import 'package:edupro_mobile_app/features/profile/models/profile_link.dart';
import 'package:edupro_mobile_app/features/profile/presentation/widgets/profile_share_sheet.dart';
import 'package:edupro_mobile_app/features/profile/services/profile_share_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _userId = 'author +&?%#தமிழ்';
const _profileName = 'සිසිර & Ravi? #+';
String get _link => ProfileLink.forUser(_userId).toString();
String get _message => 'View $_profileName on EduPro:\n$_link';

Future<void> _openSheet(
  WidgetTester tester,
  ProfileShareService service,
) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showProfileShareSheet(
              context,
              userId: _userId,
              profileName: _profileName,
              service: service,
            ),
            child: const Text('Open sharing options'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open sharing options'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Message preserves Unicode, delimiters and the encoded profile link',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final launched = <Uri>[];
      final service = ProfileShareService(
        openUrl: (uri) async {
          launched.add(uri);
          return true;
        },
      );
      await service.message(_userId, _profileName);
      expect(launched, hasLength(1));
      expect(launched.single.toString(), startsWith('sms:?body='));
      expect(launched.single.queryParameters, {'body': _message});
      expect(launched.single.toString(), contains('%20'));
      expect(launched.single.toString(), isNot(contains('+')));
    },
  );

  test(
    'iOS Message uses the composer body convention without losing text',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      late Uri launched;
      await ProfileShareService(
        openUrl: (uri) async {
          launched = uri;
          return true;
        },
      ).message(_userId, _profileName);
      const prefix = 'sms:&body=';
      expect(launched.toString(), startsWith(prefix));
      expect(
        Uri.decodeComponent(launched.toString().substring(prefix.length)),
        _message,
      );
    },
  );

  test(
    'WhatsApp tries its app then web composer with the same safe text',
    () async {
      final launched = <Uri>[];
      final service = ProfileShareService(
        openUrl: (uri) async {
          launched.add(uri);
          if (launched.length == 1) {
            throw PlatformException(code: 'unavailable');
          }
          return true;
        },
      );
      await service.whatsapp(_userId, _profileName);
      expect(launched.map((uri) => uri.scheme), ['whatsapp', 'https']);
      expect(launched.first.host, 'send');
      expect(launched.last.host, 'wa.me');
      for (final uri in launched) {
        expect(uri.queryParameters, {'text': _message});
      }
    },
  );

  test(
    'unavailable composers return clear failures instead of sending',
    () async {
      final service = ProfileShareService(openUrl: (_) async => false);
      await expectLater(
        service.message(_userId, _profileName),
        throwsA(
          isA<ProfileShareFailure>().having(
            (error) => error.message,
            'message',
            contains('Messages'),
          ),
        ),
      );
      await expectLater(
        service.whatsapp(_userId, _profileName),
        throwsA(
          isA<ProfileShareFailure>().having(
            (error) => error.message,
            'message',
            contains('WhatsApp'),
          ),
        ),
      );
    },
  );

  test(
    'Copy Link copies only the app link and reports clipboard failures',
    () async {
      final copied = <String>[];
      await ProfileShareService(
        copyText: (text) async => copied.add(text),
      ).copyLink(_userId);
      expect(copied, [_link]);
      await expectLater(
        ProfileShareService(
          copyText: (_) async {
            throw PlatformException(code: 'clipboard-unavailable');
          },
        ).copyLink(_userId),
        throwsA(isA<ProfileShareFailure>()),
      );
    },
  );

  testWidgets('share chooser has three options and Copy Link gives feedback', (
    tester,
  ) async {
    final copied = <String>[];
    await _openSheet(
      tester,
      ProfileShareService(copyText: (text) async => copied.add(text)),
    );
    expect(find.text('Share Profile'), findsOneWidget);
    expect(
      tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((tile) => (tile.title as Text).data),
      ['Message', 'WhatsApp', 'Copy Link'],
    );
    await tester.tap(find.text('Copy Link'));
    await tester.pumpAndSettle();
    expect(copied, [_link]);
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Profile link copied.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final option in ['Message', 'WhatsApp']) {
    testWidgets('$option option opens only its composer', (tester) async {
      final launched = <Uri>[];
      await _openSheet(
        tester,
        ProfileShareService(
          openUrl: (uri) async {
            launched.add(uri);
            return true;
          },
        ),
      );
      await tester.tap(find.text(option));
      await tester.pumpAndSettle();
      expect(launched, hasLength(1));
      expect(launched.single.scheme, option == 'Message' ? 'sms' : 'whatsapp');
      expect(launched.single.queryParameters.values.single, _message);
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('failed launch keeps retry and Copy Link available', (
    tester,
  ) async {
    var launches = 0;
    final copied = <String>[];
    await _openSheet(
      tester,
      ProfileShareService(
        openUrl: (_) async {
          launches++;
          return false;
        },
        copyText: (text) async => copied.add(text),
      ),
    );
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to open Messages. Try again or copy the profile link.'),
      findsWidgets,
    );
    expect(
      tester
          .widgetList<ListTile>(find.byType(ListTile))
          .every((tile) => tile.enabled),
      isTrue,
    );
    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();
    expect(launches, 2);
    await tester.tap(find.text('Copy Link'));
    await tester.pumpAndSettle();
    expect(copied, [_link]);
    expect(find.text('Profile link copied.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pending launch disables other share options and duplicate taps',
    (tester) async {
      final pending = Completer<bool>();
      var launches = 0;
      var copies = 0;
      await _openSheet(
        tester,
        ProfileShareService(
          openUrl: (_) {
            launches++;
            return pending.future;
          },
          copyText: (_) async {
            copies++;
          },
        ),
      );
      await tester.tap(find.text('Message'));
      await tester.pump();
      expect(
        tester
            .widgetList<ListTile>(find.byType(ListTile))
            .every((tile) => !tile.enabled),
        isTrue,
      );
      await tester.tap(find.text('Message'));
      await tester.tap(find.text('Copy Link'));
      expect(launches, 1);
      expect(copies, 0);
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

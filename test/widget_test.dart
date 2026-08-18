import 'package:flutter_test/flutter_test.dart';

import 'package:edupro_mobile_app/main.dart';

void main() {
  testWidgets('Splash screen shows EduPro branding', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Edu'), findsOneWidget);
    expect(find.text('Pro'), findsOneWidget);
  });
}

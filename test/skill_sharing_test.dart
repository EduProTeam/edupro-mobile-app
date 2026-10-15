import 'package:edupro_mobile_app/features/skill_sharing/presentation/screens/offer_acceptance_screen.dart';
import 'package:edupro_mobile_app/features/skill_sharing/presentation/screens/schedule_session_screen.dart';
import 'package:edupro_mobile_app/features/skill_sharing/presentation/screens/skill_requests_screen.dart';
import 'package:edupro_mobile_app/features/skill_sharing/services/skill_sharing_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('skill requests can be searched and saved', (tester) async {
    final store = SkillSharingStore();
    await tester.pumpWidget(
      MaterialApp(home: SkillRequestsScreen(store: store)),
    );

    expect(find.text('Spoken English Practice'), findsOneWidget);
    expect(find.text('UI/UX Basics'), findsOneWidget);

    await tester.tap(find.byTooltip('Search requests'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Excel');
    await tester.pump();

    expect(find.text('Excel for Beginners'), findsOneWidget);
    expect(find.text('Spoken English Practice'), findsNothing);

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(store.isSaved('excel'), isTrue);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('accepting an offer opens session scheduling', (tester) async {
    final store = SkillSharingStore();
    await tester.pumpWidget(
      MaterialApp(home: OfferAcceptanceScreen(store: store)),
    );

    await tester.tap(find.text('Accept Offer').first);
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleSessionScreen), findsOneWidget);
    expect(find.text('Schedule Session'), findsOneWidget);
    expect(find.text('Confirm Schedule'), findsOneWidget);
  });
}

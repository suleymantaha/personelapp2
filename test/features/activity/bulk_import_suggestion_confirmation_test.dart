import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/compact_error_summary.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';

void main() {
  testWidgets('PersonnelMatchCard shows "Onayla" button when needsReview is true',
      (tester) async {
    var confirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonnelMatchCard(
            item: ParsedPersonnelItem(
              rawIndex: 1,
              rawRank: 'J.Uzm.Çvş.',
              rawName: 'Murat D. HÜNERCİ',
              matchedPersonnelId: 10,
              matchedAdSoyad: 'Murat Dursun HÜNERCİ',
              matchedRutbe: 'J.Uzm.Çvş.',
              matchedTimId: 1,
              matchConfidence: 0.65,
              reviewConfirmed: false,
            ),
            teamName: '6-B Timi',
            onSelect: () {},
            onDelete: () {},
            onConfirmSuggestion: () {
              confirmed = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final confirmButton =
        find.byKey(const Key('bulk-person-confirm-suggestion'));
    expect(confirmButton, findsOneWidget);

    await tester.tap(confirmButton);
    expect(confirmed, isTrue);
  });

  testWidgets('CompactErrorSummary shows "Tümünü Onayla" button when callback provided',
      (tester) async {
    var allConfirmed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompactErrorSummary(
            problemCount: 0,
            warningCount: 2,
            parseIssues: const [],
            isExpanded: true,
            onToggle: () {},
            totalIssues: 2,
            currentIndex: 0,
            onConfirmAllSuggestions: () {
              allConfirmed = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final confirmAllButton =
        find.byKey(const Key('bulk-confirm-all-suggestions'));
    expect(confirmAllButton, findsOneWidget);

    await tester.tap(confirmAllButton);
    expect(allConfirmed, isTrue);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';

void main() {
  for (final focused in [false, true]) {
    testWidgets(
      'manual toggle works while wizard focuses ${focused ? 'this' : 'another'} card',
      (tester) async {
        final block = ParsedActivityBlock(
          rawTitle: 'Heybet',
          parsedTimName: '6/B',
          parsedActivityType: 'Heybet',
          parsedDate: '2026-07-25',
          personnelList: [
            ParsedPersonnelItem(
              rawIndex: 1,
              rawRank: 'J.Uzm.Çvş.',
              rawName: 'Mehmet KAYIP',
            ),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityBlockCard(
                block: block,
                blockIdx: 0,
                duplicates: const {},
                allSquads: const [],
                focusedIssue: BulkIssueFocus.person(
                  blockIndex: focused ? 0 : 1,
                  personIndex: 0,
                  isCritical: true,
                ),
                onEditBlock: (_) {},
                onRemoveBlock: (_) {},
                onSelectPersonnel: (_, _) {},
                onRemovePerson: (_, _) {},
              ),
            ),
          ),
        );
        expect(
          find.byType(PersonnelMatchCard),
          focused ? findsOneWidget : findsNothing,
        );
        await tester.tap(find.byKey(const Key('bulk-card-header-0')));
        await tester.pumpAndSettle();
        expect(
          find.byType(PersonnelMatchCard),
          focused ? findsNothing : findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('bulk-card-header-0')));
        await tester.pumpAndSettle();
        expect(
          find.byType(PersonnelMatchCard),
          focused ? findsOneWidget : findsNothing,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/personnel_match_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart';

void main() {
  group('safe bulk import panel', () {
    testWidgets(
      'labels a matched cross-team person as duty context instead of a broken match',
      (tester) async {
        final item = ParsedPersonnelItem(
          rawIndex: 1,
          rawRank: 'J.Asb.Cvs.',
          rawName: 'Ahmet TINAS',
          matchedPersonnelId: 10,
          matchedAdSoyad: 'Ahmet TINAS',
          matchedRutbe: 'J.Asb.Cvs.',
          matchedTimId: 6,
          matchConfidence: 1,
          teamMismatch: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PersonnelMatchCard(
                item: item,
                teamName: '9/B',
                onSelect: () {},
                onDelete: () {},
                onConfirmSuggestion: () {},
              ),
            ),
          ),
        );

        expect(find.text('Tim disi gorev'), findsWidgets);
        expect(find.textContaining('Tim uyusmazligi'), findsNothing);
        expect(find.textContaining('arizali'), findsNothing);
      },
    );

    testWidgets(
      'shows list team separately from the matched personnel registered team',
      (tester) async {
        final item = ParsedPersonnelItem(
          rawIndex: 1,
          rawRank: 'J.Asb.Cvs.',
          rawName: 'Ahmet TINAS',
          matchedPersonnelId: 10,
          matchedAdSoyad: 'Ahmet TINAS',
          matchedRutbe: 'J.Asb.Cvs.',
          matchedTimId: 6,
          matchConfidence: 1,
          teamMismatch: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PersonnelMatchCard(
                item: item,
                teamName: '9/B',
                registeredTeamName: '6/B',
                onSelect: () {},
                onDelete: () {},
                onConfirmSuggestion: () {},
              ),
            ),
          ),
        );

        expect(find.textContaining('Kayitli tim: 6/B'), findsOneWidget);
        expect(find.textContaining('Liste timi: 9/B'), findsOneWidget);
      },
    );

    testWidgets(
      'keeps save enabled when only review warnings remain',
      (tester) async {
        final blocks = [
          ParsedActivityBlock(
            rawTitle: '9/B Gorev Listesi',
            parsedTimName: '9/B',
            parsedActivityType: 'GOREV',
            parsedDate: '2026-07-30',
            personnelList: [
              ParsedPersonnelItem(
                rawIndex: 1,
                rawRank: 'J.Asb.Cvs.',
                rawName: 'Ahmet TINAS',
                matchedPersonnelId: 10,
                matchedAdSoyad: 'Ahmet TINAS',
                matchedRutbe: 'J.Asb.Cvs.',
                matchedTimId: 6,
                matchConfidence: 1,
                teamMismatch: true,
              ),
            ],
          ),
        ];
        var saved = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartSaveBar(
                problemCount: 0,
                problemLocs: const [
                  ProblemLocation(
                    blockIndex: 0,
                    personIndex: 0,
                    description: 'Ahmet TINAS - Tim disi gorev.',
                    isCritical: false,
                  ),
                ],
                activeIssueFocusIndex: -1,
                onGotoProblem: () {},
                onGotoPrevious: () {},
                onSave: () => saved = true,
                isSaving: false,
                blocks: blocks,
                issues: const <BulkParseIssue>[],
                hasUnresolvedProblems: false,
              ),
            ),
          ),
        );

        final button = tester.widget<FilledButton>(
          find.byKey(const Key('bulk-import-save-button')),
        );
        expect(button.onPressed, isNotNull);

        await tester.tap(find.byKey(const Key('bulk-import-save-button')));
        expect(saved, isTrue);
      },
    );

    testWidgets(
      'shows a saving state instead of a blocked state while save is in progress',
      (tester) async {
        final blocks = [
          ParsedActivityBlock(
            rawTitle: '9/B Gorev Listesi',
            parsedTimName: '9/B',
            parsedActivityType: 'GOREV',
            parsedDate: '2026-07-30',
            personnelList: [
              ParsedPersonnelItem(
                rawIndex: 1,
                rawRank: 'J.Asb.Cvs.',
                rawName: 'Ahmet TINAS',
                matchedPersonnelId: 10,
                matchedAdSoyad: 'Ahmet TINAS',
                matchedRutbe: 'J.Asb.Cvs.',
                matchedTimId: 6,
                matchConfidence: 1,
              ),
            ],
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SmartSaveBar(
                problemCount: 0,
                problemLocs: const [],
                activeIssueFocusIndex: -1,
                onGotoProblem: () {},
                onGotoPrevious: () {},
                onSave: () {},
                isSaving: true,
                blocks: blocks,
                issues: const <BulkParseIssue>[],
                hasUnresolvedProblems: false,
              ),
            ),
          ),
        );

        expect(find.text('Kaydediliyor...'), findsOneWidget);
        expect(find.textContaining('Kaydedilemiyor'), findsNothing);
        expect(find.textContaining('(1/0)'), findsNothing);
      },
    );
  });
}

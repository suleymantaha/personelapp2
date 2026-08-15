import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/activity_block_card.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/compact_error_summary.dart';

void main() {
  group('Bulk Import Warning Hierarchy Tests', () {
    test('ProblemLocation differentiates critical vs review warnings', () {
      final List<ParsedActivityBlock> blocks = [
        ParsedActivityBlock(
          rawTitle: 'GÖREVLİ',
          parsedActivityType: 'GÖREVLİ',
          parsedDate: '2026-08-01',
          parsedTimName: '1/B',
          personnelList: [],
        ),
        ParsedActivityBlock(
          rawTitle: 'NÖBET',
          parsedActivityType: 'NÖBET',
          parsedDate: '2026-08-01',
          parsedTimName: '5-B Timi',
          personnelList: [
            ParsedPersonnelItem(
              rawIndex: 1,
              rawRank: 'J.Ütğm.',
              rawName: 'Okan TOPUZ',
              matchedPersonnelId: 10,
              matchedAdSoyad: 'Okan TOPUZ',
              matchedRutbe: 'J.Ütğm.',
              matchedTimId: 2,
              teamMismatch: true,
            ),
          ],
        ),
      ];

      final locs = BulkImportProblemWizard.getProblemLocations(
        blocks: blocks,
        duplicates: {},
      );

      expect(locs.length, 2);
      expect(locs[0].isCritical, isTrue);
      expect(locs[0].description,
          contains('GÖREVLİ kartında personel bulunamadı'));

      expect(locs[1].isCritical, isFalse);
      expect(locs[1].description, contains('Okan TOPUZ'));
    });

    testWidgets(
        'CompactErrorSummary shows Amber color when only review warnings remain',
        (tester) async {
      final locs = [
        const ProblemLocation(
          blockIndex: 0,
          personIndex: 0,
          description:
              'Satır 202: J.Ütğm. Okan TOPUZ - Tim kontrolü gerektiriyor.',
          isCritical: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactErrorSummary(
              problemCount: 0,
              warningCount: 1,
              parseIssues: const <BulkParseIssue>[],
              problemLocations: locs,
              isExpanded: true,
              onToggle: () {},
              totalIssues: 1,
              currentIndex: 0,
            ),
          ),
        ),
      );

      expect(find.text('İnceleme Bekleyen Ögeler Var'), findsOneWidget);
      expect(find.textContaining('Okan TOPUZ'), findsOneWidget);
      expect(find.text('Tüm kontroller tamam'), findsNothing);
    });

    testWidgets(
        'ActivityBlockCard auto-expands and shows focus badge when focused',
        (tester) async {
      final block = ParsedActivityBlock(
        rawTitle: 'DEVRİYE',
        parsedActivityType: 'DEVRİYE',
        parsedDate: '2026-08-01',
        parsedTimName: '3-A Timi',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'J.Astsb.Çvş.',
            rawName: 'Ahmet YILMAZ',
            matchedPersonnelId: 5,
            matchedAdSoyad: 'Ahmet YILMAZ',
            matchedRutbe: 'J.Astsb.Çvş.',
            matchedTimId: 1,
            teamMismatch: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ActivityBlockCard(
                block: block,
                blockIdx: 0,
                duplicates: const {},
                allSquads: const [],
                focusedIssue: const BulkIssueFocus.person(
                  blockIndex: 0,
                  personIndex: 0,
                  isCritical: false,
                ),
                isExpanded:
                    false, // Explicitly passed false, should be overridden by focus
                onEditBlock: (_) {},
                onRemoveBlock: (_) {},
                onSelectPersonnel: (_, __) {},
                onRemovePerson: (_, __) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('İNCELENEN KART'), findsOneWidget);
      expect(find.text('İNCELENEN PERSONEL'), findsOneWidget);
      expect(find.textContaining('Ahmet YILMAZ'), findsWidgets);
    });
  });
}

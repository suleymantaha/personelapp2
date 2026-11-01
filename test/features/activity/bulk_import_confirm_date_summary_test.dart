import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_confirm_section.dart';

void main() {
  ParsedActivityBlock record(String team, String date, int people) {
    return ParsedActivityBlock(
      rawTitle: team,
      parsedTimName: team,
      parsedActivityType: 'Hazır Kıta',
      parsedDate: date,
      personnelList: List.generate(
        people,
        (index) => ParsedPersonnelItem(
          rawIndex: index + 1,
          rawRank: 'J.Uzm.Çvş.',
          rawName: 'Personel ${index + 1}',
          matchedPersonnelId: index + 1,
          matchConfidence: 1,
        ),
      ),
    );
  }

  test('ISO dates are displayed as Turkish day.month.year', () {
    expect(BulkImportConfirmSection.displayDate('2026-10-16'), '16.10.2026');
    expect(BulkImportConfirmSection.displayDate('2026-10-17'), '17.10.2026');
    expect(BulkImportConfirmSection.displayDate(''), 'Tarih belirtilmedi');
  });

  testWidgets('every source card shows its own team, count and date',
      (tester) async {
    tester.view.physicalSize = const Size(390, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var didSave = false;
    final blocks = [
      record('1-B', '2026-10-16', 10),
      record('2-A', '2026-10-16', 8),
      record('KH-4', '2026-10-17', 6),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BulkImportConfirmSection(
            blocks: blocks,
            issues: const [],
            unresolvedPersonnelCount: 0,
            isSaving: false,
            isMobile: true,
            onSave: () => didSave = true,
            onReturnToPreview: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('bulk-import-confirm-record-list')),
        findsOneWidget);
    expect(find.text('1-B'), findsOneWidget);
    expect(find.text('2-A'), findsOneWidget);
    expect(find.text('KH-4'), findsOneWidget);
    expect(find.text('10 personel • Hazır Kıta'), findsOneWidget);
    expect(find.text('8 personel • Hazır Kıta'), findsOneWidget);
    expect(find.text('6 personel • Hazır Kıta'), findsOneWidget);
    expect(find.text('16.10.2026'), findsNWidgets(2));
    expect(find.text('17.10.2026'), findsOneWidget);
    expect(didSave, isFalse);
    await tester.tap(find.byKey(const Key('bulk-import-save-button')));
    expect(didSave, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blocking parse issue prevents committing source cards',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BulkImportConfirmSection(
            blocks: [record('1-B', '2026-10-16', 1)],
            issues: const [
              BulkParseIssue(
                lineNumber: 1,
                rawLine: 'Geçersiz veri',
                code: 'invalid_time',
                message: 'Geçersiz veri',
                severity: BulkParseIssueSeverity.error,
              ),
            ],
            unresolvedPersonnelCount: 0,
            isSaving: false,
            isMobile: true,
            onSave: () => fail('Blocking records must never be saved'),
            onReturnToPreview: () {},
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<FilledButton>(
              find.byKey(const Key('bulk-import-save-button')))
          .onPressed,
      isNull,
    );
    expect(find.text('Kaydedilemiyor'), findsOneWidget);
  });

  testWidgets(
    'confirmation cards scroll under the top while actions stay fixed',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BulkImportConfirmSection(
              blocks: [
                for (var i = 0; i < 16; i++) record('Tim $i', '2026-10-16', 3),
              ],
              issues: const [],
              unresolvedPersonnelCount: 0,
              isSaving: false,
              isMobile: true,
              onSave: () {},
              onReturnToPreview: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollable =
          find.byKey(const Key('bulk-import-confirm-record-list'));
      final back = find.byKey(const Key('bulk-import-confirm-back-button'));
      final save = find.byKey(const Key('bulk-import-save-button'));
      final heading = find.text('Kayda Hazır');
      expect(scrollable, findsOneWidget);
      expect(back, findsOneWidget);
      expect(save, findsOneWidget);

      expect(heading, findsOneWidget);
      final backTopBefore = tester.getTopLeft(back).dy;
      await tester.drag(scrollable, const Offset(0, -360));
      await tester.pumpAndSettle();

      // The header scrolls completely out of the sliver viewport; it is
      // intentionally no longer mounted while the rows occupy that space.
      expect(heading, findsNothing);
      expect(tester.getTopLeft(back).dy, closeTo(backTopBefore, 1));
      expect(tester.getSize(back).height, 52);
      expect(tester.getSize(save).height, 52);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('320dp mobile width and large text never grow action buttons',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: BulkImportConfirmSection(
            blocks: [
              record('Çok Uzun Takım Adı / 10-B', '2026-10-16', 10),
              record('7/B', '2026-10-17', 11),
            ],
            issues: const [],
            unresolvedPersonnelCount: 0,
            isSaving: false,
            isMobile: true,
            onSave: () {},
            onReturnToPreview: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final back = find.byKey(const Key('bulk-import-confirm-back-button'));
    final save = find.byKey(const Key('bulk-import-save-button'));
    expect(tester.getSize(back).height, 52);
    expect(tester.getSize(save).height, 52);
    expect(find.text('Önizlemeye Dön'), findsOneWidget);
    expect(find.text('TÜMÜNÜ KAYDET'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

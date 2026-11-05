import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_result_sheet.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('result $width scale $scale scrolls without hiding done',
          (tester) async {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var closed = false;
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.darkMilitaryTheme,
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: Scaffold(
                body: Builder(
                    builder: (context) => TextButton(
                        onPressed: () async {
                          await showBulkImportResult(
                              context: context,
                              addedCount: 3,
                              skippedCount: 8,
                              fallbackContext: 'METİ',
                              outcomes: [
                                for (var i = 0; i < 11; i++)
                                  ActivityImportOutcome(
                                      personnelId: i,
                                      name: 'Deneme $i',
                                      rank: 'J.Uzm.Çvş.',
                                      activityName: 'METİ',
                                      date: '2026-11-06',
                                      duty: 'GÖREVLİ',
                                      status: i < 8
                                          ? ActivityImportStatus.conflict
                                          : ActivityImportStatus.added,
                                      existingDescription:
                                          i < 8 ? 'Nöbet · NÖBETÇİ' : null)
                              ]);
                          closed = true;
                        },
                        child: const Text('Aç'))))));
        await tester.tap(find.text('Aç'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final done = find.byKey(const Key('bulk-import-result-done'));
        final initialDone = tester.getRect(done);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(closed, isFalse);
        if (scale > 1.5) {
          await tester.scrollUntilVisible(find.text('Atlananlar (8)'), 150,
              scrollable: find
                  .descendant(
                      of: find.byType(NestedScrollView),
                      matching: find.byType(Scrollable))
                  .first);
          await tester.pumpAndSettle();
        }
        expect(find.text('Atlananlar (8)'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('J.Uzm.Çvş. Deneme 7'), 200,
            scrollable: find.descendant(
                of: find.byKey(const Key('bulk-import-outcome-list')).first,
                matching: find.byType(Scrollable)));
        await tester.pumpAndSettle();
        expect(find.text('J.Uzm.Çvş. Deneme 7'), findsOneWidget);
        expect(tester.getRect(done), initialDone);
        expect(tester.takeException(), isNull);
        await tester.tap(done);
        await tester.pumpAndSettle();
        expect(closed, isTrue);
        expect(find.text('Aç'), findsOneWidget);
      });
    }
  }
}

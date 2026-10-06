import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/previous_day_excel_picker.dart';

GunlukFaaliyetTableData card(int id, String name, String date) =>
    GunlukFaaliyetTableData(
      id: id,
      faaliyetAdi: name,
      tarih: date,
      olusturanKullanici: 'admin',
      olusturmaTarihi: date,
    );

void main() {
  testWidgets('same-day and previous-day choices return independent card IDs', (
    tester,
  ) async {
    Set<int>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<Set<int>>(
                  context: context,
                  builder: (_) => PreviousDayExcelPicker(
                    activities: [card(3, 'Önceki Hazır Kıta', '2026-10-05')],
                    currentActivities: [
                      card(2, 'Bugünkü Devriye', '2026-10-06'),
                    ],
                  ),
                );
              },
              child: const Text('Aç'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Aç'));
    await tester.pumpAndSettle();
    expect(find.text('Aynı Günün Kartları'), findsOneWidget);
    expect(find.text('Önceki Günün Kartları'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('current-activity-2')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('previous-activity-3')));
    await tester.pump();
    await tester.tap(find.text('Önizleme (2)'));
    await tester.pumpAndSettle();
    expect(result, {2, 3});
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'anchor-only export remains available when both lists are empty',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PreviousDayExcelPicker(activities: [])),
        ),
      );
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Önizleme (0)'),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('card picker fits a narrow phone and can be cancelled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PreviousDayExcelPicker(
            activities: List.generate(
              10,
              (i) => card(i + 1, 'Uzun Faaliyet Adı $i', '2026-10-05'),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Vazgeç'), findsOneWidget);
  });
}

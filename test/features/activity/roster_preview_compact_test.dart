import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/theme/app_theme.dart';
import 'package:personelapp2/features/activity/presentation/roster_output_preview_screen.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:shared_preferences/shared_preferences.dart';

MilitaryRosterRow person(int id, String name) => MilitaryRosterRow(
      sNu: id,
      personelId: id,
      birligi: 'Test',
      rutbe: 'J.Er',
      adSoyad: name,
      diger: '',
    );

GunlukFaaliyetTableData card(int id, String name) => GunlukFaaliyetTableData(
      id: id,
      faaliyetAdi: name,
      tarih: '2026-10-28',
      olusturanKullanici: 'test',
      olusturmaTarihi: '2026-10-28',
    );

Map<int, MatrixDayCell> xDays(int count) => {
      for (var day = 1; day <= count; day++)
        day: const MatrixDayCell(
          displayCode: 'X',
          entries: [],
          hasConflict: false,
        ),
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('compact cards start closed and reveal their original details',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rows = [person(1, 'TEST KİŞİ')];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkMilitaryTheme,
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: [card(1, 'HEYBET'), card(2, 'Nöbet')],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Seçilen kartlar · 2'), findsOneWidget);
    expect(find.text('HEYBET'), findsNothing);
    expect(find.text('İmzalar'), findsOneWidget);
    expect(find.byKey(const Key('edit-roster-signer-0')), findsNothing);
    expect(find.text('TEST KİŞİ'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('roster-preview-summary'))).height,
      lessThan(90),
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('roster-preview-cards-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('HEYBET'), findsOneWidget);
    expect(find.text('Nöbet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('roster-preview-cards-toggle')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('roster-preview-signers-toggle')),
      120,
    );
    await tester.tap(find.byKey(const Key('roster-preview-signers-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-roster-signer-0')), findsOneWidget);
    expect(find.byKey(const Key('edit-roster-signer-1')), findsOneWidget);
  });

  testWidgets('rule counts open separate included and excluded people lists',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rows = [
      person(1, 'KALAN BİR'),
      person(2, 'HARİÇ KİŞİ'),
      person(3, 'KALAN İKİ'),
    ];
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkMilitaryTheme,
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: [card(1, 'HEYBET')],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async => {2: xDays(21)},
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
    await tester.pumpAndSettle();
    expect(find.text('2 kişi çıktıda'), findsOneWidget);
    expect(find.text('1 kişi hariç'), findsOneWidget);

    await tester.tap(find.byKey(const Key('roster-rule-included-count')));
    await tester.pumpAndSettle();
    expect(find.text('Çıktıdaki personel (2)'), findsOneWidget);
    expect(find.text('KALAN BİR'), findsOneWidget);
    expect(find.text('KALAN İKİ'), findsOneWidget);
    expect(find.text('HARİÇ KİŞİ'), findsNothing);
    await tester.tap(find.byKey(const Key('roster-rule-sheet-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('roster-rule-excluded-count')));
    await tester.pumpAndSettle();
    expect(find.text('Çıktıya alınmayanlar (1)'), findsOneWidget);
    expect(find.text('HARİÇ KİŞİ'), findsOneWidget);
    expect(find.text('21 gün X'), findsOneWidget);
    expect(find.text('KALAN BİR'), findsNothing);
    expect(find.text('KALAN İKİ'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed rule refresh clears stale counts and export action',
      (tester) async {
    final rows = [person(1, 'TEST KİŞİ')];
    var matrixLoads = 0;
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: RosterOutputPreviewScreen(
          date: '2026-10-28',
          sources: [card(1, 'HEYBET')],
          rows: rows,
          loadRows: () async => rows,
          loadMatrix: () async {
            if (++matrixLoads == 1) return {};
            throw StateError('matrix unavailable');
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('roster-matrix-rule-preview')));
    await tester.pumpAndSettle();
    expect(find.text('1 kişi çıktıda'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('roster-matrix-rule-refresh')),
      120,
    );
    await tester.tap(find.byKey(const Key('roster-matrix-rule-refresh')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('roster-rule-included-count')), findsNothing);
    expect(find.byKey(const Key('roster-rule-export')), findsNothing);
    expect(find.byKey(const Key('roster-matrix-rule-preview')), findsOneWidget);
    expect(find.textContaining('matrix unavailable'), findsOneWidget);
  });
}

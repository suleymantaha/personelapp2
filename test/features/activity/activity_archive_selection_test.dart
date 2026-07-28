import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/activity_archive_screen.dart';

void main() {
  testWidgets('long press enables multi-select and opens export options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    const activities = [
      GunlukFaaliyetTableData(
        id: 1,
        faaliyetAdi: 'Birinci Faaliyet',
        tarih: '2026-07-28',
        olusturanKullanici: 'admin',
        olusturmaTarihi: '',
      ),
      GunlukFaaliyetTableData(
        id: 2,
        faaliyetAdi: 'İkinci Faaliyet',
        tarih: '2026-07-28',
        olusturanKullanici: 'admin',
        olusturmaTarihi: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          filteredActivitiesProvider.overrideWith(
            (ref) => Stream.value(activities),
          ),
          allPersonnelProvider.overrideWith((ref) => Stream.value(const [])),
          allSquadsProvider.overrideWith((ref) => Stream.value(const [])),
          pendingAssignmentsProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
        child: const MaterialApp(home: ActivityArchiveScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('activity-card-1')));
    await tester.pump();
    expect(find.text('1 faaliyet seçildi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('activity-card-2')));
    await tester.pump();
    expect(find.text('2 faaliyet seçildi'), findsOneWidget);

    await tester.tap(find.byKey(const Key('activity-selection-export')));
    await tester.pumpAndSettle();
    expect(find.text('PDF Paylaş'), findsOneWidget);
    expect(find.text('Doğrudan Yazdır'), findsOneWidget);
    expect(find.text('Excel Olarak Aktar'), findsOneWidget);
    expect(find.text('Metin Listesi Paylaş'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

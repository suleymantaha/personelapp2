import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

void main() {
  late AppDatabase database;

  Future<void> pickDefaultDate(WidgetTester tester) async {
    await tester.tap(find.text('Tarih seç'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final teamId = await database.into(database.timTable).insert(
      TimTableCompanion.insert(
        timAdi: '6-B Timi',
        olusturmaTarihi: '2026-01-01',
      ),
    );
    await database.batch((batch) {
      batch.insertAll(database.personelTable, [
        PersonelTableCompanion.insert(
          adSoyad: 'Ali DENEME',
          rutbe: 'J.Uzm.Çvş.',
          birlik: '6/B',
          timId: Value(teamId),
          kayitTarihi: '2026-01-01',
        ),
        PersonelTableCompanion.insert(
          adSoyad: 'Veli SAĞLAM',
          rutbe: 'J.Uzm.Çvş.',
          birlik: '6/B',
          timId: Value(teamId),
          kayitTarihi: '2026-01-01',
        ),
      ]);
    });
  });

  tearDown(() => database.close());

  testWidgets(
      'editing a card reduces the issue count incrementally card-by-card',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: BulkImportDialog(
              database: database,
              activityRepository: ActivityRepository(database),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Paste two blocks without dates
    await tester.enterText(
      find.byType(TextField).first,
      '''
6/B Heybet Listesi
Ali DENEME

6/B Hazır Kıta Listesi
Veli SAĞLAM
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Initial state: 2 cards with missing dates => "2 kritik hata"
    expect(find.textContaining('2 kritik hata'), findsOneWidget);

    // Open card menu for Card 0 and click "Kartı düzenle"
    final cardMenu0 = find.byKey(const Key('bulk-card-menu-0'));
    expect(cardMenu0, findsOneWidget);
    await tester.tap(cardMenu0);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kartı düzenle'));
    await tester.pumpAndSettle();

    // In EditDialog, select a date before saving.
    await pickDefaultDate(tester);
    await tester.tap(find.byKey(const Key('bulk-edit-save')));
    await tester.pumpAndSettle();

    // Issue count should decrease from 2 to 1 => "1 kritik hata"
    expect(find.textContaining('1 kritik hata'), findsOneWidget);

    // Open card menu for Card 1 and click "Kartı düzenle"
    final cardMenu1 = find.byKey(const Key('bulk-card-menu-1'));
    expect(cardMenu1, findsOneWidget);
    await tester.tap(cardMenu1);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Kartı düzenle'));
    await tester.pumpAndSettle();

    await pickDefaultDate(tester);
    await tester.tap(find.byKey(const Key('bulk-edit-save')));
    await tester.pumpAndSettle();

    // All issues resolved => "Tüm kontroller tamam"
    expect(find.text('Tüm kontroller tamam'), findsOneWidget);
  });
}

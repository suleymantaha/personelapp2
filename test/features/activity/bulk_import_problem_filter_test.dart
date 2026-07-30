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

  testWidgets('problem chip filters cards and personnel using original indexes',
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

    await tester.enterText(
      find.byType(TextField).first,
      '''
6/B Heybet Listesi
25.07.2026
1- J.Uzm.Çvş. Ali DENEME
2- J.Uzm.Çvş. Veli SAĞLAM
6/B Devriye Listesi
25.07.2026
1- J.Uzm.Çvş. Mehmet BİLİNMEYEN
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bulk-person-0-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bulk-filter-problems')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bulk-person-0-1')), findsNothing);
    expect(find.byKey(const Key('bulk-person-1-0')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bulk-filter-all')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('bulk-person-0-1')), findsOneWidget);
  });

  testWidgets(
      'team mismatch on matched personnel displays warning tag but does not block saving',
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

    await tester.enterText(
      find.byType(TextField).first,
      '''
2. TİM KARAKEÇİ Listesi
25.07.2026
1- J.Uzm.Çvş. Ali DENEME
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Ali DENEME is matched (100% confidence), but KARAKEÇİ team differs from 6-B Timi in DB
    expect(find.textContaining('Ali DENEME'), findsWidgets);
    expect(find.byKey(const Key('bulk-team-mismatch-warning'), skipOffstage: false), findsWidgets);

    // Problem count chip should say "Hazır" (0 problems blocking save)
    expect(find.text('Hazır'), findsWidgets);

    // Save button should be enabled
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('bulk-import-save-button')),
    );
    expect(button.onPressed != null, isTrue);
  });
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
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

  testWidgets(
      'missing team header does not block save when personnel are matched',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userSessionProvider.overrideWith(
            (ref) => const UserSessionState(
              username: 'admin',
              role: UserRole.admin,
            ),
          ),
        ],
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

    // Paste text with date and personnel, but NO team header
    await tester.enterText(
      find.byType(TextField).first,
      '''
25.07.2026 Heybet
1. J.Uzm.Çvş. Ali DENEME
2. J.Uzm.Çvş. Veli SAĞLAM
''',
    );
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();

    // Verify it is not blocking (no critical error banner)
    expect(find.text('Kaydedilemiyor'), findsNothing);

    // Verify Stepper Step 3 (Kaydet) or SmartSaveBar allows proceeding
    final step3 = find.text('Kaydet');
    expect(step3, findsOneWidget);
    await tester.tap(step3);
    await tester.pumpAndSettle();

    // Tap confirm save
    final confirmSaveBtn = find.byKey(const Key('bulk-import-save-button'));
    expect(confirmSaveBtn, findsOneWidget);
    await tester.tap(confirmSaveBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Check database has created assignments
    final list = await database.select(database.gunlukFaaliyetTable).get();
    expect(list, isNotEmpty);
  });
}

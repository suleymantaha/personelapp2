import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
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
          rutbe: 'J.Uzm.Cvs.',
          birlik: '6/B',
          timId: Value(teamId),
          kayitTarihi: '2026-01-01',
        ),
        PersonelTableCompanion.insert(
          adSoyad: 'Mehmet TEST',
          rutbe: 'J.Uzm.Cvs.',
          birlik: '6/B',
          timId: Value(teamId),
          kayitTarihi: '2026-01-01',
        ),
      ]);
    });
  });

  tearDown(() => database.close());

  Future<void> pumpBulkImportDialog(WidgetTester tester) {
    return tester.pumpWidget(
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
  }

  testWidgets(
    'missing team header does not block save when personnel are matched',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpBulkImportDialog(tester);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        '''
25.07.2026 Heybet
1. Ali DENEME
2. Mehmet TEST
''',
      );
      await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
      await tester.pumpAndSettle();

      expect(find.text('Kaydedilemiyor'), findsNothing);

      final step3 = find.text('Kaydet');
      expect(step3, findsOneWidget);
      await tester.tap(step3);
      await tester.pumpAndSettle();

      final confirmSaveBtn = find.byKey(const Key('bulk-import-save-button'));
      expect(confirmSaveBtn, findsOneWidget);
      await tester.tap(confirmSaveBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final list = await database.select(database.gunlukFaaliyetTable).get();
      expect(list, isNotEmpty);
    },
  );

  testWidgets(
    'duplicate import confirmation waits for user choice before showing saving state',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const pastedText = '''
25.07.2026 Heybet
1. Ali DENEME
2. Mehmet TEST
''';

      final personnel = await database.select(database.personelTable).get();
      final parsed = BulkTextParser.parse(pastedText);
      final importedBlocks =
          await PersonnelFuzzyMatcher(database).matchBlocks(parsed.blocks);
      await ActivityRepository(database).createActivitiesWithAssignments(
        [
          ActivityCreateRequest(
            faaliyetAdi: 'Günlük Tüm Faaliyetler',
            tarih: '2026-07-25',
            olusturanKullanici: 'admin',
            personnelAssignments: [
              for (final person in personnel)
                PersonnelAssignmentInput(
                  personnelId: person.id,
                  duty: importedBlocks.single.parsedActivityType,
                ),
            ],
          ),
        ],
        actor: const UserSessionState(
          username: 'admin',
          role: UserRole.admin,
        ),
      );
      await BulkImportLearningService(database).recordImport(
        fingerprint: BulkImportLearningService.fingerprint(importedBlocks),
        blocks: importedBlocks,
        actor: 'admin',
        rawText: pastedText,
      );

      await pumpBulkImportDialog(tester);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, pastedText);
      await tester.tap(
        find.widgetWithText(
          ElevatedButton,
          'Metni Ayrıştır ve Kartları Oluştur',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('bulk-import-save-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Bu Liste'), findsOneWidget);
      expect(find.text('Kaydediliyor...'), findsNothing);
    },
  );
}

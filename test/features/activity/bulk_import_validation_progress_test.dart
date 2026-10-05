import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/bulk_import_problem_wizard.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import/smart_save_bar.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

void main() {
  final block = ParsedActivityBlock(
    rawTitle: 'HEYBET',
    parsedTimName: '6/B',
    parsedActivityType: 'HEYBET',
    parsedDate: '2026-07-25',
    personnelList: [
      ParsedPersonnelItem(
        rawIndex: 1,
        rawRank: '',
        rawName: 'Ali DENEME',
        matchedPersonnelId: 1,
        matchedAdSoyad: 'Ali DENEME',
        matchConfidence: 1,
      ),
    ],
  );
  Future<void> pumpBar(
    WidgetTester tester,
    List<BulkParseIssue> issues, {
    List<ProblemLocation> locations = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmartSaveBar(
            problemCount: locations.isEmpty ? issues.length : locations.length,
            problemLocs: locations,
            activeIssueFocusIndex: -1,
            onGotoProblem: () {},
            onGotoPrevious: () {},
            onSave: () {},
            isSaving: false,
            blocks: [block],
            issues: issues,
            hasUnresolvedProblems: false,
          ),
        ),
      ),
    );
  }

  const warning = BulkParseIssue(
    lineNumber: 3,
    rawLine: 'Ali DENEME',
    code: 'unknown_rank',
    message: 'Rütbe tanınamadı.',
    severity: BulkParseIssueSeverity.warning,
  );
  const sourceError = BulkParseIssue(
    lineNumber: 2,
    rawLine: '25:00-08:00',
    code: 'invalid_time',
    message: 'Saat aralığı geçerli değil.',
    severity: BulkParseIssueSeverity.error,
  );
  testWidgets(
    'source review warning does not lock continuation after personnel errors are resolved',
    (tester) async {
      await pumpBar(tester, const [warning]);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('bulk-import-save-button')),
            )
            .onPressed,
        isNotNull,
      );
      expect(find.textContaining('Kaydetmek için'), findsNothing);
    },
  );
  testWidgets('a source blocking error is counted once', (tester) async {
    await pumpBar(tester, const [sourceError]);
    expect(find.text('Kaydetmek için 1 işlem kaldı'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('bulk-import-save-button')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'source and card errors are both counted while duplicate parser diagnostics are not',
    (tester) async {
      await pumpBar(
        tester,
        const [
          sourceError,
          BulkParseIssue(
            lineNumber: 3,
            rawLine: 'Ali DENEME',
            code: 'unmatched_personnel',
            message: 'Personel seçilmedi.',
            severity: BulkParseIssueSeverity.error,
          ),
        ],
        locations: const [
          ProblemLocation(
            blockIndex: 0,
            personIndex: 0,
            description: 'Personel seçilmedi.',
          ),
        ],
      );
      expect(find.text('Kaydetmek için 2 işlem kaldı'), findsOneWidget);
    },
  );

  late AppDatabase database;
  Future<void> pumpImport(WidgetTester tester, String text) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final team = await database
        .into(database.timTable)
        .insert(
          TimTableCompanion.insert(
            timAdi: '6-B Timi',
            olusturmaTarihi: '2026-01-01',
          ),
        );
    await database
        .into(database.personelTable)
        .insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ali DENEME',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            timId: Value(team),
            kayitTarihi: '2026-01-01',
          ),
        );
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
    await tester.enterText(find.byType(TextField).first, text);
    await tester.tap(find.text('Metni Ayrıştır ve Kartları Oluştur'));
    await tester.pumpAndSettle();
  }

  Future<void> clean(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets(
    'individual suggestion confirmation exits issue focus and restores all cards',
    (tester) async {
      await pumpImport(
        tester,
        '2. TİM KARAKEÇİ Listesi\n25.07.2026\n1- J.Uzm.Çvş. Ali DENEME\n6/B Devriye Listesi\n26.07.2026\n1- J.Uzm.Çvş. Ali DENEME',
      );
      try {
        await tester.ensureVisible(find.byKey(const Key('bulk-wizard-next')));
        await tester.tap(find.byKey(const Key('bulk-wizard-next')));
        await tester.pumpAndSettle();
        final confirm = find.byKey(const Key('bulk-person-confirm-suggestion'));
        expect(confirm, findsOneWidget);
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('bulk-card-header-1')), findsOneWidget);
        expect(
          find.byKey(const Key('bulk-focused-person-badge')),
          findsNothing,
        );
      } finally {
        await clean(tester);
      }
    },
  );
  testWidgets(
    'source error fix opens original input instead of a dead wizard',
    (tester) async {
      await pumpImport(
        tester,
        '6/B Heybet Listesi\n25.07.2026\n25:00-08:00\n1- J.Uzm.Çvş. Ali DENEME',
      );
      try {
        final fix = find.widgetWithText(OutlinedButton, 'Düzelt');
        await tester.ensureVisible(fix);
        await tester.tap(fix);
        await tester.pumpAndSettle();
        expect(find.text('Metni Ayrıştır ve Kartları Oluştur'), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byType(TextField).first)
              .controller!
              .text,
          contains('25:00-08:00'),
        );
      } finally {
        await clean(tester);
      }
    },
  );
  testWidgets(
    'preview continuation opens confirmation without writing assignments',
    (tester) async {
      await pumpImport(
        tester,
        '6/B Heybet Listesi\n25.07.2026\n1- J.Uzm.Çvş. Ali DENEME',
      );
      try {
        await tester.tap(find.byKey(const Key('bulk-import-save-button')));
        await tester.pumpAndSettle();
        expect(find.text('Kayda Hazır'), findsOneWidget);
        expect(
          await database.select(database.faaliyetPersonelAtamaTable).get(),
          isEmpty,
        );
      } finally {
        await clean(tester);
      }
    },
  );
}

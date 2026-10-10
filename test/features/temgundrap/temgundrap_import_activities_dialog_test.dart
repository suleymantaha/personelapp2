import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/domain/services/temgundrap_activity_converter.dart';
import 'package:personelapp2/features/temgundrap/presentation/widgets/temgundrap_import_activities_dialog.dart';
import 'package:personelapp2/l10n/generated/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('select all skips imported source but keeps same-name activity',
      (tester) async {
    final ids = <int>[];
    for (var i = 0; i < 2; i++) {
      ids.add(await db.into(db.gunlukFaaliyetTable).insert(
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'AYNI İSİMLİ DEVRİYE',
              tarih: '2026-10-10',
              olusturanKullanici: 'test',
              olusturmaTarihi: '2026-10-10',
            ),
          ));
    }
    final source = await (db.select(db.gunlukFaaliyetTable)
          ..where((tbl) => tbl.id.equals(ids.first)))
        .getSingle();
    final existing = TemgundrapActivityConverter.convert(
      activity: source,
      assignments: [],
      personnelMap: {},
    );
    // Legacy imports remain identifiable after their description is edited.
    final legacy = TemgundrapOperation.fromJson({
      ...existing.toJson(),
      'id': '${ids.first}_123456789',
      'description': 'DÜZENLENMİŞ AÇIKLAMA',
    });
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
            body: TemgundrapImportActivitiesDialog(
          initialDate: DateTime(2026, 10, 10),
          existingOperations: [legacy],
        )),
      ),
    ));
    await tester.pumpAndSettle();
    final imported = find.byKey(Key('activity-import-${ids.first}'));
    final available = find.byKey(Key('activity-import-${ids.last}'));
    expect(tester.widget<CheckboxListTile>(imported).onChanged, isNull);
    expect(tester.widget<CheckboxListTile>(imported).value, isFalse);
    await tester.scrollUntilVisible(available, 80);
    expect(tester.widget<CheckboxListTile>(available).value, isTrue);
    await tester.tap(find.text('Seçimi Kaldır'));
    await tester.pump();
    await tester.tap(find.text('Tümünü Seç'));
    await tester.pump();
    expect(tester.widget<CheckboxListTile>(available).value, isTrue);
    expect(find.text('FORMA AKTAR (1)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'TemgundrapImportActivitiesDialog renders correctly and lists activities',
      (tester) async {
    // Insert test activity
    await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'KOVANCILAR İLÇE J.K.LIĞI DEVRİYE',
            tarih: '2026-10-10',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-10-10 08:00:00',
          ),
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: TemgundrapImportActivitiesDialog(
              initialDate: DateTime(2026, 10, 10),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Faaliyetlerden İçe Aktar'), findsOneWidget);
    expect(find.text('10.10.2026'), findsOneWidget);
    expect(find.text('KOVANCILAR İLÇE J.K.LIĞI DEVRİYE'), findsOneWidget);
    expect(find.byKey(const Key('submit-import-activities')), findsOneWidget);
  });

  testWidgets(
      'TemgundrapImportActivitiesDialog converts and submits selected activities',
      (tester) async {
    await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'PALU İLÇE J.K.LIĞI YOL EMNİYETİ',
            tarih: '2026-10-10',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-10-10 08:00:00',
          ),
        );

    List<TemgundrapOperation>? result;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showDialog<List<TemgundrapOperation>>(
                    context: context,
                    builder: (_) => TemgundrapImportActivitiesDialog(
                      initialDate: DateTime(2026, 10, 10),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('PALU İLÇE J.K.LIĞI YOL EMNİYETİ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('submit-import-activities')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.length, equals(1));
    expect(result!.first.operationArea, equals('PALU İLÇE J.K.LIĞI'));
    expect(result!.first.purpose, equals('YOL EMNİYETİ'));
  });
}

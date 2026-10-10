import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
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

  testWidgets('TemgundrapImportActivitiesDialog renders correctly and lists activities', (tester) async {
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

  testWidgets('TemgundrapImportActivitiesDialog converts and submits selected activities', (tester) async {
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

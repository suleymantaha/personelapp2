import 'package:drift/drift.dart' hide isNull, isNotNull;
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
  for (final scenario in [
    'fresh',
    'renamed',
    'revoked',
    'assignment-changed',
    'scope-only'
  ]) {
    testWidgets('TEM import refreshes selected scope on submit: $scenario',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final team = await db.into(db.timTable).insert(
          TimTableCompanion.insert(timAdi: 'A', olusturmaTarihi: '2020-01-01'));
      final user = await db.into(db.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
              kullaniciAdi: 'chief', rol: 'tim_komutani', timId: Value(team)));
      await (db.update(db.timTable)..where((t) => t.id.equals(team)))
          .write(TimTableCompanion(timKomutaniId: Value(user)));
      final act = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Selected task',
              tarih: '2020-02-01',
              olusturanKullanici: 'chief',
              olusturmaTarihi: '2020-02-01'));
      final p = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: 'Original Person',
              rutbe: 'J.Er',
              birlik: '1/B',
              kayitTarihi: '2020-01-01'));
      final assignment = await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: act,
              personelId: p,
              gorevVeyaIzin: 'HEYBET',
              durum: 'onaylandi',
              gorevTimId: Value(team),
              gorevTimAdi: const Value('Historical A')));
      if (scenario == 'scope-only') {
        final other = await db.into(db.timTable).insert(
            TimTableCompanion.insert(
                timAdi: 'Foreign', olusturmaTarihi: '2020-01-01'));
        for (final row in [
          ('Foreign-only task', other, 'onaylandi'),
          ('Pending-only task', team, 'beklemede')
        ]) {
          final id = await db.into(db.gunlukFaaliyetTable).insert(
              GunlukFaaliyetTableCompanion.insert(
                  faaliyetAdi: row.$1,
                  tarih: '2020-02-01',
                  olusturanKullanici: 'chief',
                  olusturmaTarihi: '2020-02-01'));
          await db.into(db.faaliyetPersonelAtamaTable).insert(
              FaaliyetPersonelAtamaTableCompanion.insert(
                  faaliyetId: id,
                  personelId: p,
                  gorevVeyaIzin: 'HEYBET',
                  durum: row.$3,
                  gorevTimId: Value(row.$2),
                  gorevTimAdi: Value(row.$1)));
        }
      }
      List<TemgundrapOperation>? result;
      await tester.pumpWidget(ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userSessionProvider.overrideWith((ref) => UserSessionState(
                username: 'chief', role: UserRole.teamCommander, timId: team)),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () async {
                          result = await showDialog<List<TemgundrapOperation>>(
                              context: context,
                              builder: (_) => TemgundrapImportActivitiesDialog(
                                  initialDate: DateTime(2020, 2, 1)));
                        },
                        child: const Text('Open')))),
          )));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('1 Personel Görevli'), findsOneWidget);
      if (scenario == 'scope-only') {
        expect(find.text('Foreign-only task'), findsNothing);
        expect(find.text('Pending-only task'), findsNothing);
        expect(find.text('FORMA AKTAR (1)'), findsOneWidget);
      }
      if (scenario == 'renamed') {
        await (db.update(db.gunlukFaaliyetTable)
              ..where((t) => t.id.equals(act)))
            .write(const GunlukFaaliyetTableCompanion(
                faaliyetAdi: Value('Changed source')));
      } else if (scenario == 'revoked') {
        await (db.update(db.timTable)..where((t) => t.id.equals(team)))
            .write(const TimTableCompanion(timKomutaniId: Value(null)));
      } else if (scenario == 'assignment-changed') {
        await (db.update(db.faaliyetPersonelAtamaTable)
              ..where((t) => t.id.equals(assignment)))
            .write(const FaaliyetPersonelAtamaTableCompanion(
                durum: Value('reddedildi')));
      } else {
        await (db.update(db.personelTable)..where((t) => t.id.equals(p))).write(
            const PersonelTableCompanion(adSoyad: Value('Fresh Person')));
      }
      await tester.tap(find.byKey(const Key('submit-import-activities')));
      await tester.pumpAndSettle();
      if (scenario == 'renamed' || scenario == 'revoked') {
        expect(result, isNull);
        expect(find.byType(TemgundrapImportActivitiesDialog), findsOneWidget);
      } else if (scenario == 'assignment-changed') {
        expect(result, isEmpty);
      } else {
        expect(result, hasLength(1));
        expect(result!.single.id, 'activity-2020-02-01-$act');
        final encoded = result!.single.toJson().toString();
        expect(encoded.contains('Original Person'), isFalse);
        if (scenario == 'fresh') {
          expect(encoded.contains('Fresh Person'), isTrue);
        }
      }
      expect(tester.takeException(), isNull);
    });
  }
}

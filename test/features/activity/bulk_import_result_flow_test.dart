import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

import '../../support/task_team_history_fixture.dart';

void main() {
  for (final targetMode in [false, true]) {
    for (final mode in ['partial', 'zero', 'success']) {
      testWidgets('$mode result target=$targetMode reports committed personnel',
          (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        const actor = UserSessionState(username: 'admin', role: UserRole.admin);
        await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
            kullaniciAdi: 'admin', rol: 'yönetici'));
        final team = await db.into(db.timTable).insert(TimTableCompanion.insert(
            timAdi: '1-B', olusturmaTarihi: '2000-01-01'));
        final ids = <int>[];
        for (final name in ['Örnek DENEME', 'İkinci DENEME', 'Üçüncü DENEME']) {
          ids.add(await db.into(db.personelTable).insert(
              PersonelTableCompanion.insert(
                  adSoyad: name,
                  rutbe: 'J.Uzm.Çvş.',
                  birlik: 'Test',
                  timId: Value(team),
                  kayitTarihi: '2000-01-01')));
        }
        await seedTaskTeamHistory(db);
        final date = DateTime.now().toIso8601String().split('T').first;
        final parts = date.split('-');
        final repo = ActivityRepository(db);
        final targetId = await repo.createActivityWithAssignments(
            faaliyetAdi: 'METİ',
            tarih: date,
            olusturanKullanici: 'admin',
            personnelAssignments: mode == 'success'
                ? []
                : [
                    PersonnelAssignmentInput(
                        personnelId: ids[0],
                        duty: 'METİ',
                        note: targetMode ? null : 'Görev Türü: METİ')
                  ],
            actor: actor);
        if (mode != 'success') {
          await repo.createActivityWithAssignments(
              faaliyetAdi: 'Nöbet',
              tarih: date,
              olusturanKullanici: 'admin',
              personnelAssignments: [
                PersonnelAssignmentInput(personnelId: ids[1], duty: 'NÖBETÇİ')
              ],
              actor: actor);
        }
        final target = await (db.select(db.gunlukFaaliyetTable)
              ..where((t) => t.id.equals(targetId)))
            .getSingle();
        final before = await db.select(db.faaliyetPersonelAtamaTable).get();
        bool? returned;
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final names = mode == 'zero'
            ? ['Örnek DENEME', 'İkinci DENEME']
            : ['Örnek DENEME', 'İkinci DENEME', 'Üçüncü DENEME'];
        await tester.pumpWidget(ProviderScope(
            overrides: [userSessionProvider.overrideWith((ref) => actor)],
            child: MaterialApp(
                home: Scaffold(
                    body: Builder(
                        builder: (context) => TextButton(
                            onPressed: () async {
                              returned = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => BulkImportDialog(
                                      database: db,
                                      activityRepository: repo,
                                      targetActivity:
                                          targetMode ? target : null,
                                      initialText:
                                          '${parts[2]}.${parts[1]}.${parts[0]} 1/B METİ Listesi\n'
                                          '${names.indexed.map((e) => '${e.$1 + 1}. J.Uzm.Çvş. ${e.$2}').join('\n')}'));
                            },
                            child: const Text('Aktar')))))));
        await tester.tap(find.text('Aktar'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Kaydet'));
        await tester.pumpAndSettle();
        if (targetMode && mode == 'partial') {
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(BulkImportDialog), findsOneWidget);
          expect(find.text('Kaydet'), findsOneWidget);
          expect(await db.select(db.faaliyetPersonelAtamaTable).get(), before);
          await tester.tap(find.text('Kaydet'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Onayla ve Kaydet'), findsOneWidget);
        await tester.tap(find.byKey(const Key('bulk-import-save-button')));
        await tester.pumpAndSettle();
        expect(find.text('Aktarım sonucu'), findsOneWidget);
        expect(
            find.text(mode == 'zero'
                ? 'Yeni personel eklenmedi'
                : mode == 'partial'
                    ? 'Kısmen tamamlandı'
                    : 'Tamamlandı'),
            findsOneWidget);
        expect(find.text('Mevcut kayıtlar korunuyor.'), findsOneWidget);
        expect(find.text('Atlananlar (${mode == 'success' ? 0 : 2})'),
            findsOneWidget);
        expect(
            find.text(
                'Eklenenler (${mode == 'zero' ? 0 : mode == 'partial' ? 1 : 3})'),
            findsOneWidget);
        if (mode != 'success') {
          expect(find.text('J.Uzm.Çvş. Örnek DENEME'), findsOneWidget);
          expect(find.text('Bu kartta zaten kayıtlı'), findsOneWidget);
          expect(find.text('Aynı gün görev kaydı var'), findsOneWidget);
          expect(find.textContaining('NÖBETÇİ'), findsWidgets);
        }
        if (mode != 'zero') {
          await tester
              .tap(find.text('Eklenenler (${mode == 'partial' ? 1 : 3})'));
          await tester.pumpAndSettle();
          expect(find.text('J.Uzm.Çvş. Üçüncü DENEME'), findsOneWidget);
        }
        final saved = await db.select(db.faaliyetPersonelAtamaTable).get();
        expect(
            saved.length,
            before.length +
                (mode == 'zero'
                    ? 0
                    : mode == 'partial'
                        ? 1
                        : 3));
        for (final row in before) {
          expect(saved, contains(row));
        }
        await tester.tap(find.text('Tamam'));
        await tester.pumpAndSettle();
        expect(find.text('Aktarım sonucu'), findsNothing);
        expect(find.text('Aktar'), findsOneWidget);
        expect(returned, mode != 'zero');
        expect(await db.select(db.faaliyetPersonelAtamaTable).get(), saved);
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      });
    }
  }
}

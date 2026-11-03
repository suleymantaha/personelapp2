import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/dialogs/bulk_import_dialog.dart';

String day(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

void main() {
  for (final offset in [-1, 4]) {
    for (final useTarget in [false, true]) {
      testWidgets(
        'offset $offset target=$useTarget requires consent, cancel writes nothing, retry keeps day',
        (tester) async {
          final db = AppDatabase(NativeDatabase.memory());
          addTearDown(db.close);
          await db.into(db.kullaniciTable).insert(
                KullaniciTableCompanion.insert(
                  kullaniciAdi: 'admin',
                  rol: 'yönetici',
                ),
              );
          final team = await db.into(db.timTable).insert(
                TimTableCompanion.insert(
                  timAdi: '1-B',
                  olusturmaTarihi: '2000-01-01',
                ),
              );
          await db.into(db.personelTable).insert(
                PersonelTableCompanion.insert(
                  adSoyad: 'Örnek DENEME',
                  rutbe: 'J.Uzm.Çvş.',
                  birlik: 'Test',
                  timId: Value(team),
                  kayitTarihi: '2000-01-01',
                ),
              );
          final destinationDay =
              day(DateTime.now().add(Duration(days: offset)));
          final sourceDay = useTarget
              ? day(DateTime.now().add(Duration(days: offset + 1)))
              : destinationDay;
          GunlukFaaliyetTableData? target;
          if (useTarget) {
            final id = await db.into(db.gunlukFaaliyetTable).insert(
                GunlukFaaliyetTableCompanion.insert(
                    faaliyetAdi: 'Hedef Kart',
                    tarih: destinationDay,
                    olusturanKullanici: 'admin',
                    olusturmaTarihi: destinationDay));
            target = await (db.select(db.gunlukFaaliyetTable)
                  ..where((t) => t.id.equals(id)))
                .getSingle();
          }
          final parts = sourceDay.split('-');
          tester.view.physicalSize = const Size(1000, 1000);
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
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => BulkImportDialog(
                          database: db,
                          activityRepository: ActivityRepository(db),
                          targetActivity: target,
                          initialText:
                              '${parts[2]}.${parts[1]}.${parts[0]} 1/B METİ Listesi\n'
                              '1. J.Uzm.Çvş. Örnek DENEME',
                        ),
                      ),
                      child: const Text('Aktar'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Aktar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Kaydet'));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('bulk-import-save-button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          expect(find.byKey(const Key('import-date-approve')), findsOneWidget);
          expect((await db.select(db.gunlukFaaliyetTable).get()).length,
              useTarget ? 1 : 0);
          if (useTarget) {
            expect(
                find.text(
                    'Kaynak tarihleri: ${parts[2]}.${parts[1]}.${parts[0]}'),
                findsOneWidget);
          }
          await tester.tap(find.byKey(const Key('import-date-cancel')));
          await tester.pumpAndSettle();
          expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
          expect(await db.select(db.topluAktarimGecmisiTable).get(), isEmpty);
          await tester.tap(find.byKey(const Key('bulk-import-save-button')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          await tester.tap(find.byKey(const Key('import-date-approve')));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          final rows = await db.select(db.gunlukFaaliyetTable).get();
          expect(rows.single.tarih, destinationDay);
          expect(rows.single.faaliyetAdi, useTarget ? 'Hedef Kart' : 'METİ');
          expect(
            (await db.select(db.faaliyetPersonelAtamaTable).get()).length,
            1,
          );
          await tester.tap(find.text('TAMAM'));
          await tester.pumpAndSettle();
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }
}

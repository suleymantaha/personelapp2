import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_copy_action.dart';

void main() {
  for (final mode in [
    'copy',
    'cancel picker',
    'cancel past team',
    'non-admin'
  ]) {
    testWidgets('copy card action: $mode', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('synthetic-user', 'synthetic-test-hash', 'yönetici')");
      addTearDown(db.close);
      final now = DateTime.now();
      final sourceDate = DateTime(now.year, now.month, now.day + 1);
      final target = DateTime(
        now.year,
        now.month,
        now.day + (mode == 'cancel past team' ? -2 : 2),
      );
      final targetDate = DateFormat('yyyy-MM-dd').format(target);
      final team = await db.into(db.timTable).insert(
            TimTableCompanion.insert(
                timAdi: 'Synthetic Team', olusturmaTarihi: ''),
          );
      final person = await db.into(db.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: 'Synthetic Person',
              rutbe: 'Er',
              birlik: 'Test',
              kayitTarihi: DateFormat('yyyy-MM-dd').format(now),
              timId: Value(team),
            ),
          );
      final activity = GunlukFaaliyetTableData(
        id: 70,
        faaliyetAdi: 'Synthetic Duty',
        tarih: DateFormat('yyyy-MM-dd').format(sourceDate),
        olusturanKullanici: 'synthetic-admin',
        olusturmaTarihi: '',
      );
      await db.into(db.gunlukFaaliyetTable).insert(activity);
      await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: 70,
              personelId: person,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: 'onaylandi',
              aciklama: const Value('Synthetic note'),
              gorevTimId: Value(team),
              gorevTimAdi: const Value('Synthetic Team'),
            ),
          );
      final originalRows = await db.select(db.faaliyetPersonelAtamaTable).get();
      final callbacks = <String>[];
      Future<void> settle() async {
        await tester.pumpAndSettle();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            userSessionProvider.overrideWith((ref) => UserSessionState(
                  username: 'synthetic-user',
                  role: mode == 'non-admin'
                      ? UserRole.teamCommander
                      : UserRole.admin,
                  timId: team,
                )),
          ],
          child: MaterialApp(
              home: Scaffold(
                  body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => copyActivityFromCard(
                context: context,
                ref: ref,
                activity: activity,
                onDateChanged: callbacks.add,
              ),
              child: const Text('Copy card'),
            ),
          ))),
        ));
        await tester.tap(find.text('Copy card'));
        await settle();
        if (mode == 'non-admin') {
          expect(find.byType(DatePickerDialog), findsNothing);
        } else {
          expect(find.byType(DatePickerDialog), findsOneWidget);
          if (mode == 'cancel picker') {
            await tester.tap(find.text('Cancel'));
          } else {
            await tester.tap(find.byTooltip('Switch to input'));
            await tester.pumpAndSettle();
            await tester.enterText(
              find.byType(TextField),
              DateFormat('MM/dd/yyyy').format(target),
            );
            await tester.tap(find.text('OK'));
          }
          await settle();
          if (mode == 'cancel past team') {
            expect(find.text('Görev tarihindeki timi doğrula'), findsOneWidget);
            expect(
                tester
                    .widget<FilledButton>(
                      find.byKey(const ValueKey('task-team-confirm')),
                    )
                    .onPressed,
                isNull);
            await tester.tap(find.text('İptal'));
            await settle();
          }
        }

        final activities = await db.select(db.gunlukFaaliyetTable).get();
        final rows = await db.select(db.faaliyetPersonelAtamaTable).get();
        expect(activities.singleWhere((row) => row.id == 70), activity);
        expect(rows.singleWhere((row) => row.faaliyetId == 70),
            originalRows.single);
        if (mode == 'copy') {
          expect(activities, hasLength(2));
          final destination = activities.singleWhere((row) => row.id != 70);
          expect(destination.tarih, targetDate);
          expect(destination.faaliyetAdi, 'Synthetic Duty');
          expect(rows, hasLength(2));
          final copied =
              rows.singleWhere((row) => row.faaliyetId == destination.id);
          expect(copied.personelId, person);
          expect(copied.gorevVeyaIzin, 'GÖREVLİ');
          expect(copied.aciklama, 'Synthetic note');
          expect(copied.gorevTimId, team);
          expect(callbacks, [targetDate]);
        } else {
          expect(activities, [activity]);
          expect(rows, originalRows);
          expect(callbacks, isEmpty);
        }
        expect((await db.select(db.personelTable).getSingle()).timId, team);
        expect(await db.select(db.timUyelikGecmisiTable).get(), isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
      }
    });
  }
}

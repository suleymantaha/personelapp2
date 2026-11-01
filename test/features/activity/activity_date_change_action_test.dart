import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_date_change_action.dart';

void main() {
  for (final mode in [
    'same team',
    'cancel changed team',
    'confirm changed team'
  ]) {
    testWidgets('date change: $mode', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('synthetic-admin', 'synthetic-test-hash', 'yönetici')");
      addTearDown(db.close);
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final nextDay = DateTime(now.year, now.month, now.day + 2);
      final originalDate = DateFormat('yyyy-MM-dd').format(tomorrow);
      final targetDate = DateFormat('yyyy-MM-dd').format(nextDay);
      final changedTeam = mode != 'same team';
      final oldTeam = await db.into(db.timTable).insert(
          TimTableCompanion.insert(
              timAdi: 'Saved team', olusturmaTarihi: '2000-01-01'));
      final newTeam = await db.into(db.timTable).insert(
          TimTableCompanion.insert(
              timAdi: 'New team', olusturmaTarihi: '2000-01-01'));
      final person = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
              adSoyad: 'Synthetic',
              rutbe: 'Er',
              birlik: 'Test',
              kayitTarihi: '2000-01-01',
              timId: Value(changedTeam ? newTeam : oldTeam)));
      final activity = GunlukFaaliyetTableData(
          id: 1,
          faaliyetAdi: 'Synthetic planned duty',
          tarih: originalDate,
          olusturanKullanici: 'synthetic-admin',
          olusturmaTarihi: '2000-01-01');
      final otherActivity = activity.copyWith(
          id: 2,
          faaliyetAdi: 'Other synthetic duty',
          tarih: DateFormat('yyyy-MM-dd')
              .format(DateTime(now.year, now.month, now.day + 4)));
      for (final record in [activity, otherActivity]) {
        await db.into(db.gunlukFaaliyetTable).insert(record);
        await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
                faaliyetId: record.id,
                personelId: person,
                gorevVeyaIzin: 'GÖREVLİ',
                durum: 'onaylandi',
                gorevTimId: Value(oldTeam),
                gorevTimAdi: const Value('Saved team')));
      }
      final before = await db.select(db.faaliyetPersonelAtamaTable).get();
      final callbacks = <String>[];
      Future<void> settle() async {
        await tester.pumpAndSettle();
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pumpAndSettle();
      }

      try {
        await tester.pumpWidget(ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              userSessionProvider.overrideWith((ref) => const UserSessionState(
                  username: 'synthetic-admin', role: UserRole.admin)),
            ],
            child: MaterialApp(
                home: Scaffold(
                    body: Consumer(
                        builder: (context, ref, _) => TextButton(
                            onPressed: () => changeActivityDateFromCard(
                                context: context,
                                ref: ref,
                                activity: activity,
                                onDateChanged: callbacks.add),
                            child: const Text('Change date')))))));
        await tester.tap(find.text('Change date'));
        await settle();
        await tester.tap(find.byTooltip('Switch to input'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byType(TextField), DateFormat('MM/dd/yyyy').format(nextDay));
        await tester.tap(find.text('OK'));
        await settle();
        expect(find.text('TARİHİ DEĞİŞTİR'), findsOneWidget);
        await tester.tap(find.text('TARİHİ DEĞİŞTİR'));
        await settle();

        if (changedTeam) {
          expect(find.text('Görev tarihindeki timi doğrula'), findsOneWidget);
          expect(
              tester
                  .widget<FilledButton>(
                      find.byKey(const ValueKey('task-team-confirm')))
                  .onPressed,
              isNull);
          if (mode == 'cancel changed team') {
            await tester.tap(find.text('İptal'));
          } else {
            await tester.tap(find.byKey(ValueKey('task-team-choice-$person')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('New team').last);
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('task-team-confirm')));
          }
          await settle();
        } else {
          expect(find.text('Görev tarihindeki timi doğrula'), findsNothing);
        }
        final cancelled = mode == 'cancel changed team';
        final savedActivity = await (db.select(db.gunlukFaaliyetTable)
              ..where((a) => a.id.equals(activity.id)))
            .getSingle();
        final assignments =
            await db.select(db.faaliyetPersonelAtamaTable).get();
        final savedAssignment =
            assignments.singleWhere((a) => a.faaliyetId == activity.id);
        expect(savedActivity.tarih, cancelled ? originalDate : targetDate);
        expect(callbacks, cancelled ? isEmpty : [targetDate]);
        expect(savedAssignment.gorevTimId,
            changedTeam && !cancelled ? newTeam : oldTeam);
        expect(savedAssignment.gorevTimAdi,
            changedTeam && !cancelled ? 'New team' : 'Saved team');
        if (cancelled) expect(assignments, before);
        expect(assignments.singleWhere((a) => a.faaliyetId == otherActivity.id),
            before.singleWhere((a) => a.faaliyetId == otherActivity.id));
        expect(
            await (db.select(db.gunlukFaaliyetTable)
                  ..where((a) => a.id.equals(otherActivity.id)))
                .getSingle(),
            otherActivity);
        expect((await db.select(db.personelTable).getSingle()).timId,
            changedTeam ? newTeam : oldTeam);
        expect(await db.select(db.timUyelikGecmisiTable).get(), isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
      }
    });
  }
}

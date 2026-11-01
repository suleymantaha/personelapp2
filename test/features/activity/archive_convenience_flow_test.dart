import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_summary_card.dart';

void main() {
  testWidgets(
      'admin card menu and selected team shortcut save only chosen rows',
      (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('admin', 'synthetic-test-hash', 'yönetici')");
    addTearDown(db.close);
    const admin = UserSessionState(username: 'admin', role: UserRole.admin);
    final repo = ActivityRepository(db);
    final teams = [
      for (var i = 0; i < 2; i++)
        await db.into(db.timTable).insert(TimTableCompanion.insert(
            timAdi: 'Test Tim $i', olusturmaTarihi: '2026-01-01'))
    ];
    final people = [
      for (var i = 0; i < 2; i++)
        await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: 'Test Personel $i',
            rutbe: 'Er',
            birlik: 'Test',
            timId: Value(teams[i]),
            kayitTarihi: '2026-01-01'))
    ];
    final id = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Test Kart',
        tarih: '2026-10-15',
        olusturanKullanici: 'admin',
        actor: admin,
        personnelAssignments: [
          for (var i = 0; i < 2; i++)
            PersonnelAssignmentInput(
                personnelId: people[i],
                duty: 'METİ',
                teamId: teams[i],
                note: 'Not $i')
        ]);
    final activity = await (db.select(db.gunlukFaaliyetTable)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final before = await db.select(db.faaliyetPersonelAtamaTable).get();
    final personnel = await db.select(db.personelTable).get();
    final squads = await db.select(db.timTable).get();
    Future<void> settle() async {
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((ref) => admin),
          historicalPersonnelProvider
              .overrideWith((ref) => Stream.value(personnel)),
          allSquadsProvider.overrideWith((ref) => Stream.value(squads)),
        ],
        child: MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(
                    child: ActivityCard(
                        activity: activity, onDateChanged: (_) {}))))));
    await settle();
    await tester.tap(find.byKey(Key('activity-actions-$id')));
    await tester.pumpAndSettle();
    expect(find.text('Başka Güne Kopyala'), findsOneWidget);
    Navigator.of(tester.element(find.text('Başka Güne Kopyala'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Kart'));
    await settle();
    expect(find.byKey(const Key('activity-detail-screen')), findsOneWidget);
    await tester
        .longPress(find.byKey(Key('activity-team-header-${teams.first}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reassign-selected-teams')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1 personel seçildi'), findsOneWidget);
    await tester.tap(find.byKey(const Key('archive-existing-save')));
    await settle();
    expect(find.byKey(const Key('archive-existing-save')), findsNothing);
    final after = await db.select(db.faaliyetPersonelAtamaTable).get();
    expect(after, hasLength(2));
    final changed = after.singleWhere((a) => a.personelId == people.first);
    final old = before.singleWhere((a) => a.personelId == people.first);
    expect(changed.id, old.id);
    expect(changed.gorevVeyaIzin, 'GÖREVLİ');
    expect(changed.gorevTimId, old.gorevTimId);
    expect(changed.aciklama, old.aciklama);
    expect(after.singleWhere((a) => a.personelId == people.last),
        before.singleWhere((a) => a.personelId == people.last));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}

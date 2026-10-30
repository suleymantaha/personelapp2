import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/presentation/widgets/activity_summary_card.dart';

void main() {
  const scenarios = [
    (
      name: 'historical duty remains visible under its snapshot team',
      hasSnapshot: true,
      activePerson: true,
      filter: 'old',
      visible: true,
    ),
    (
      name: 'historical duty is hidden under the current personnel team',
      hasSnapshot: true,
      activePerson: true,
      filter: 'new',
      visible: false,
    ),
    (
      name: 'snapshot team remains visible without active personnel',
      hasSnapshot: true,
      activePerson: false,
      filter: 'old',
      visible: true,
    ),
    (
      name: 'unknown snapshot does not inherit current personnel team',
      hasSnapshot: false,
      activePerson: true,
      filter: 'new',
      visible: false,
    ),
    (
      name: 'all teams includes duties with an unknown snapshot',
      hasSnapshot: false,
      activePerson: true,
      filter: 'all',
      visible: true,
    ),
  ];

  for (final scenario in scenarios) {
    testWidgets(scenario.name, (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final oldTeam = await db.into(db.timTable).insert(
            TimTableCompanion.insert(
              timAdi: 'Old team',
              olusturmaTarihi: '2000-01-01',
            ),
          );
      final newTeam = await db.into(db.timTable).insert(
            TimTableCompanion.insert(
              timAdi: 'New team',
              olusturmaTarihi: '2000-01-01',
            ),
          );
      final personId = await db.into(db.personelTable).insert(
            PersonelTableCompanion.insert(
              adSoyad: 'Synthetic',
              rutbe: 'Er',
              birlik: 'Test',
              kayitTarihi: '2000-01-01',
              timId: Value(newTeam),
            ),
          );
      const activity = GunlukFaaliyetTableData(
        id: 1,
        faaliyetAdi: 'Historical duty',
        tarih: '2001-01-02',
        olusturanKullanici: 'admin',
        olusturmaTarihi: '2001-01-02',
      );
      await db.into(db.gunlukFaaliyetTable).insert(activity);
      await db.into(db.faaliyetPersonelAtamaTable).insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: activity.id,
              personelId: personId,
              gorevVeyaIzin: 'GÖREVLİ',
              durum: 'onaylandi',
              gorevTimId: Value(scenario.hasSnapshot ? oldTeam : null),
              gorevTimAdi: Value(scenario.hasSnapshot ? 'Old team' : null),
            ),
          );
      final people = await db.select(db.personelTable).get();
      final teams = await db.select(db.timTable).get();
      final selectedSquadId = switch (scenario.filter) {
        'old' => oldTeam,
        'new' => newTeam,
        _ => null,
      };

      await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          allPersonnelProvider.overrideWith(
            (ref) => Stream.value(scenario.activePerson ? people : []),
          ),
          allSquadsProvider.overrideWith((ref) => Stream.value(teams)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivityCard(
              activity: activity,
              selectedSquadId: selectedSquadId,
              onDateChanged: (_) {},
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      try {
        expect(
          find.byKey(const Key('activity-card-1')),
          scenario.visible ? findsOneWidget : findsNothing,
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
      }
    });
  }
}

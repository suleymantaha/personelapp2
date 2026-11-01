import 'package:drift/drift.dart' hide Column, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/providers/providers.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/activity/presentation/activity_detail_screen.dart';

const _admin = UserSessionState(username: 'admin', role: UserRole.admin);

Future<AppDatabase> _fixture() async {
  final db = AppDatabase(NativeDatabase.memory());
  await db.into(db.kullaniciTable).insert(KullaniciTableCompanion.insert(
      kullaniciAdi: 'admin', rol: UserRole.admin.storageValue));
  await db
      .into(db.timTable)
      .insert(TimTableCompanion.insert(timAdi: 'K.H', olusturmaTarihi: ''));
  await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
      adSoyad: 'Sentetik Test',
      rutbe: 'J.Uzm.Çvş.',
      birlik: 'Test',
      timId: const Value(1),
      kayitTarihi: '2026-11-01'));
  await db.into(db.gunlukFaaliyetTable).insert(
      GunlukFaaliyetTableCompanion.insert(
          faaliyetAdi: 'Test',
          tarih: '2026-11-01',
          olusturanKullanici: 'admin',
          olusturmaTarihi: ''));
  await db.into(db.faaliyetPersonelAtamaTable).insert(
      FaaliyetPersonelAtamaTableCompanion.insert(
          faaliyetId: 1,
          personelId: 1,
          gorevVeyaIzin: 'GÖREVLİ',
          durum: 'onaylandi',
          gorevTimId: const Value(1),
          gorevTimAdi: const Value('K.H')));
  return db;
}

void main() {
  for (final bulk in [false, true]) {
    test('assignment removal checks current admin role: bulk=$bulk', () async {
      final db = await _fixture();
      addTearDown(db.close);
      await db
          .update(db.kullaniciTable)
          .write(const KullaniciTableCompanion(rol: Value('tim_komutani')));
      final repo = ActivityRepository(db);
      await expectLater(
          bulk
              ? repo.deleteAssignments([1], actor: _admin)
              : repo.deleteAssignment(1, actor: _admin),
          throwsA(isA<Exception>()));
      expect(
          await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
    });
    test('authorized admin can remove assignment: bulk=$bulk', () async {
      final db = await _fixture();
      addTearDown(db.close);
      final repo = ActivityRepository(db);
      expect(
          await (bulk
              ? repo.deleteAssignments([1], actor: _admin)
              : repo.deleteAssignment(1, actor: _admin)),
          1);
      expect(await db.select(db.personelTable).get(), hasLength(1));
    });
  }
  testWidgets(
      'last assignment removed clears sticky toolbar on real detail route',
      (tester) async {
    final db = await _fixture();
    await tester.pumpWidget(ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          userSessionProvider.overrideWith((_) => _admin),
        ],
        child: MaterialApp(
            home: ActivityDetailScreen(
                activityId: 1,
                actionsBuilder: (context, ref, activity, rows) =>
                    const SizedBox.shrink()))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('team-selection-start')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('activity-team-header-1')));
    await tester.pumpAndSettle();
    expect(find.text('1 tim seçildi'), findsOneWidget);
    expect(find.byKey(const Key('activity-detail-export')), findsNothing);
    expect(find.text('+ Personel Ekle'), findsNothing);
    await db.delete(db.faaliyetPersonelAtamaTable).go();
    await tester.pumpAndSettle();
    expect(find.text('1 tim seçildi'), findsNothing);
    expect(find.byKey(const Key('export-selected-teams')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await db.close();
    await tester.pump(const Duration(milliseconds: 50));
  });
}

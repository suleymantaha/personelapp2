import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/services/combined_heybet_excel_service.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

void main() {
  late AppDatabase db;
  late CombinedHeybetExcelService service;
  late GunlukFaaliyetTableData anchor;
  late Map<int, PersonelTableData> people;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = CombinedHeybetExcelService(db);
    for (var i = 1; i <= 5; i++) {
      await db
          .into(db.personelTable)
          .insert(
            PersonelTableCompanion.insert(
              adSoyad: i <= 2 ? 'Aynı İsim' : 'Personel $i',
              rutbe: 'J.Uzm.Çvş.',
              birlik: 'KH',
              kayitTarihi: '',
            ),
          );
    }
    for (final item in [
      ('Heybet', '2027-01-01'),
      ('Devriye', '2027-01-01'),
      ('Hazır Kıta', '2026-12-31'),
      ('Eski', '2026-12-30'),
    ]) {
      await db
          .into(db.gunlukFaaliyetTable)
          .insert(
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: item.$1,
              tarih: item.$2,
              olusturanKullanici: 'admin',
              olusturmaTarihi: item.$2,
            ),
          );
    }
    anchor = (await db.select(db.gunlukFaaliyetTable).get()).first;
    people = {for (final p in await db.select(db.personelTable).get()) p.id: p};
    for (final item in [
      (2, 1, 'HAZIR KITA', 'onaylandi', 1),
      (2, 2, 'HAZIR KITA', 'onaylandi', 1),
      (3, 1, 'NÖB. SB.', 'onaylandi', 1),
      (3, 3, 'HAZIR KITA', 'onaylandi', 1),
      (3, 3, 'HAZIR KITA', 'onaylandi', 1),
      (2, 4, 'HAZIR KITA', 'beklemede', 1),
      (2, 5, 'HAZIR KITA', 'onaylandi', 2),
    ]) {
      await db
          .into(db.faaliyetPersonelAtamaTable)
          .insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: item.$1,
              personelId: item.$2,
              gorevVeyaIzin: item.$3,
              durum: item.$4,
              gorevTimId: Value(item.$5),
            ),
          );
    }
  });
  tearDown(() => db.close());

  MilitaryRosterRow mainRow() => MilitaryRosterRow(
    sNu: 7,
    personelId: 1,
    birligi: 'Normal birlik',
    rutbe: 'J.Uzm.Çvş.',
    adSoyad: 'Aynı İsim',
    diger: 'Ana kart',
    groupCode: 'DIGER',
  );

  test('same-day picker excludes anchor and handles year boundary', () async {
    expect((await service.listCurrentActivities(anchor)).map((a) => a.id), [2]);
    expect((await service.listPreviousActivities(anchor)).map((a) => a.id), [
      3,
    ]);
  });

  test(
    'deduplicates by person ID with main then current then previous priority',
    () async {
      final before = await db.select(db.faaliyetPersonelAtamaTable).get();
      final main = mainRow();
      final rows = await service.build(
        activity: anchor,
        selectedCurrentActivityIds: {2},
        selectedPreviousActivityIds: {3},
        currentRows: [main],
        personnelById: people,
        squadNames: {},
        authorizedTeamId: 1,
      );
      expect(rows.map((r) => r.personelId), [1, 2, 3]);
      expect(rows.map((r) => r.sNu), [1, 2, 3]);
      expect(rows.where((r) => r.adSoyad == 'Aynı İsim'), hasLength(2));
      expect(rows.first.groupCode, 'DIGER');
      expect(rows.map((r) => r.diger), everyElement(''));
      expect(
        rows.map((r) => r.birligi),
        everyElement('J.Komd.Öz.Hrk.Tb.Klığı'),
      );
      expect(main.sNu, 7);
      expect(main.diger, 'Ana kart');
      expect(await db.select(db.faaliyetPersonelAtamaTable).get(), before);
    },
  );

  test('same-day only works without any previous-day selection', () async {
    final rows = await service.build(
      activity: anchor,
      selectedCurrentActivityIds: {2},
      selectedPreviousActivityIds: {},
      currentRows: [mainRow()],
      personnelById: people,
      squadNames: {},
      selectedSquadId: 1,
    );
    expect(rows.map((r) => r.personelId), [1, 2]);
  });

  test(
    'rejects IDs from wrong dates and excludes pending or foreign-team rows',
    () async {
      final rows = await service.build(
        activity: anchor,
        selectedCurrentActivityIds: {1, 3, 4, 999},
        selectedPreviousActivityIds: {1, 2, 4},
        currentRows: [mainRow()],
        personnelById: people,
        squadNames: {},
        authorizedTeamId: 1,
      );
      expect(rows.map((r) => r.personelId), [1]);
    },
  );

  test(
    'deduplicates previous-day source even when main roster is empty',
    () async {
      final rows = await service.build(
        activity: anchor,
        selectedPreviousActivityIds: {3},
        currentRows: [],
        personnelById: people,
        squadNames: {},
      );
      expect(rows.map((r) => r.personelId).toSet(), {1, 3});
      expect(rows, hasLength(2));
    },
  );
}

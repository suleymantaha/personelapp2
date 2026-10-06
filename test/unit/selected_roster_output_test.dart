import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/services/combined_heybet_excel_service.dart';

void main() {
  late AppDatabase db;
  late CombinedHeybetExcelService service;
  late List<GunlukFaaliyetTableData> cards;
  late Map<int, PersonelTableData> people;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    service = CombinedHeybetExcelService(db);
    await db
        .into(db.timTable)
        .insert(TimTableCompanion.insert(timAdi: '1-B', olusturmaTarihi: ''));
    await db
        .into(db.timTable)
        .insert(TimTableCompanion.insert(timAdi: '2-B', olusturmaTarihi: ''));
    for (final name in [
      'Heybet personeli',
      'Z Personel',
      'A Personel',
      'Aynı İsim',
      'Aynı İsim',
    ]) {
      await db
          .into(db.personelTable)
          .insert(
            PersonelTableCompanion.insert(
              adSoyad: name,
              rutbe: 'J.Uzm.Çvş.',
              birlik: '',
              kayitTarihi: '',
            ),
          );
    }
    for (final item in [
      ('Heybet', '2027-01-01'),
      ('Bugün A', '2027-01-01'),
      ('Bugün B', '2027-01-01'),
      ('Dün A', '2026-12-31'),
      ('Dün B', '2026-12-31'),
    ]) {
      await db
          .into(db.gunlukFaaliyetTable)
          .insert(
            GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: item.$1,
              tarih: item.$2,
              olusturanKullanici: 'admin',
              olusturmaTarihi: '',
            ),
          );
    }
    for (final item in [
      (1, 1, 1, 'onaylandi'),
      (2, 2, 1, 'onaylandi'),
      (3, 3, 1, 'onaylandi'),
      (4, 2, 1, 'onaylandi'),
      (4, 4, 1, 'onaylandi'),
      (5, 5, 1, 'onaylandi'),
      (5, 1, 2, 'onaylandi'),
      (5, 3, 1, 'beklemede'),
    ]) {
      await db
          .into(db.faaliyetPersonelAtamaTable)
          .insert(
            FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: item.$1,
              personelId: item.$2,
              gorevVeyaIzin: 'HAZIR KITA',
              gorevTimId: Value(item.$3),
              durum: item.$4,
            ),
          );
    }
    cards = await db.select(db.gunlukFaaliyetTable).get();
    people = {for (final p in await db.select(db.personelTable).get()) p.id: p};
  });
  tearDown(() => db.close());

  Future<List<int?>> output(List<int> ids, {int? team = 1}) async =>
      (await service.buildSelected(
        date: '2027-01-01',
        sources: ids.map((id) => cards.singleWhere((c) => c.id == id)).toList(),
        personnelById: people,
        squadNames: {},
        authorizedTeamId: team,
      )).map((r) => r.personelId).toList();

  test('date candidates include Heybet but exporting other cards does not include it', () async {
    expect(
      (await service.listActivitiesForDate('2027-01-01')).map((c) => c.id),
      [1, 2, 3],
    );
    expect(await output([2]), [2]);
    expect(await output([]), isEmpty);
    expect(await output([1]), [1]);
  });
  test('card order wins over global name sorting and previous day always follows current day', () async {
    expect(await output([5, 2, 4, 3]), [2, 3, 5, 4]);
    expect(await output([3, 2, 4, 5]), [3, 2, 4, 5]);
  });
  test('same name different IDs survive and data is read-only with continuous numbering', () async {
    final before = await db.select(db.faaliyetPersonelAtamaTable).get();
    final rows = await service.buildSelected(
      date: '2027-01-01',
      sources: [cards[1], cards[3], cards[4]],
      personnelById: people,
      squadNames: {},
      authorizedTeamId: 1,
    );
    expect(rows.map((r) => r.personelId), [2, 4, 5]);
    expect(rows.map((r) => r.sNu), [1, 2, 3]);
    expect(rows.where((r) => r.adSoyad == 'Aynı İsim'), hasLength(2));
    expect(rows.map((r) => r.diger), everyElement(''));
    expect(rows.map((r) => r.birligi), everyElement('J.Komd.Öz.Hrk.Tb.Klığı'));
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), before);
  });
  test('pending personnel and foreign teams are excluded', () async {
    expect(await output([5]), [5]);
    expect(await output([5], team: null), [5, 1]);
  });
  test('deleted duplicate-only source is rejected even if personnel would be unchanged', () async {
    await (db.delete(
      db.gunlukFaaliyetTable,
    )..where((c) => c.id.equals(4))).go();
    expect(output([2, 4]), throwsStateError);
  });
  test('renamed source is rejected before export', () async {
    await (db.update(
      db.gunlukFaaliyetTable,
    )..where((c) => c.id.equals(2))).write(
      const GunlukFaaliyetTableCompanion(faaliyetAdi: Value('Değişti')),
    );
    expect(output([2]), throwsStateError);
  });
  test(
    'wrong date fails instead of silently ignoring the selected card',
    () async {
      expect(
        service.buildSelected(
          date: '2027-01-03',
          sources: [cards[1]],
          personnelById: people,
          squadNames: {},
        ),
        throwsArgumentError,
      );
    },
  );
}

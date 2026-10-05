import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/services/combined_heybet_excel_service.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test(
      'separate Excel derives yesterday rows without altering normal rows or X history',
      () async {
    for (var i = 1; i <= 5; i++) {
      await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
          adSoyad: 'Personel $i',
          rutbe: 'J.Uzm.Çvş.',
          birlik: 'Eski birlik',
          kayitTarihi: ''));
    }
    for (final date in ['2026-12-30', '2026-12-31', '2027-01-01']) {
      await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
              faaliyetAdi: 'Heybet',
              tarih: date,
              olusturanKullanici: 'admin',
              olusturmaTarihi: date));
    }
    final activity = (await db.select(db.gunlukFaaliyetTable).get()).last;
    for (final item in [
      (1, 1, 'HAZIR KITA', 'onaylandi'),
      (2, 2, 'HAZIR KITA', 'onaylandi'),
      (2, 3, 'NÖB. SB.', 'onaylandi'),
      (2, 4, 'MEBS NÖB.', 'beklemede'),
      (2, 5, 'GÜLÜŞKÜR', 'onaylandi')
    ]) {
      await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: item.$1,
              personelId: item.$2,
              gorevVeyaIzin: item.$3,
              durum: item.$4,
              aciklama: const Value('Ek açıklama')));
    }
    final before = await db.select(db.faaliyetPersonelAtamaTable).get();
    final activitiesBefore = await db.select(db.gunlukFaaliyetTable).get();
    final people = {
      for (final p in await db.select(db.personelTable).get()) p.id: p
    };
    final normalRows = [
      MilitaryRosterRow(
          sNu: 1,
          birligi: '6-B Timi',
          rutbe: '',
          adSoyad: 'Bugünün Heybeti',
          diger: 'Normal açıklama'),
      MilitaryRosterRow(
          sNu: 2,
          birligi: 'Normal birlik',
          rutbe: '',
          adSoyad: 'Bugünün Hazır Kıtası',
          diger: 'HAZIR KITA',
          groupCode: 'HAZIR_KITA')
    ];
    final service = CombinedHeybetExcelService(db);
    for (var repeat = 0; repeat < 2; repeat++) {
      final rows = await service.build(
          activity: activity,
          currentRows: normalRows,
          personnelById: people,
          squadNames: {});
      expect(rows.map((r) => r.adSoyad), [
        'Bugünün Heybeti',
        'Bugünün Hazır Kıtası',
        'Personel 3',
        'Personel 2'
      ]);
      expect(rows.map((r) => r.sNu), [1, 2, 3, 4]);
      expect(rows.map((r) => r.diger), everyElement(''));
      expect(rows.first.birligi, 'J.Komd.Öz.Hrk.Tb.Klığı');
      expect(rows[1].birligi, '');
      expect(rows.skip(2).map((r) => r.birligi),
          everyElement('J.Komd.Öz.Hrk.Tb.Klığı'));
    }
    expect(normalRows.first.birligi, '6-B Timi');
    expect(normalRows.first.diger, 'Normal açıklama');
    expect(normalRows[1].birligi, 'Normal birlik');
    expect(normalRows[1].diger, 'HAZIR KITA');
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), before);
    expect(await db.select(db.gunlukFaaliyetTable).get(), activitiesBefore);
    final matrix =
        await MatrixRepository(db).watchMonthlyMatrix('2027-01').first;
    expect(matrix[2]?[1]?.displayCode, 'X');
    expect(matrix[2]?[1]?.entries, hasLength(1));
    expect(matrix[2]?[1]?.entries.single.isContinuationDay, isTrue);
    expect(matrix[2]?[2], isNull);
    final filtered = await service.build(
        activity: activity,
        currentRows: [],
        personnelById: {3: people[3]!},
        squadNames: {});
    expect(filtered.map((r) => r.adSoyad), ['Personel 3']);
  });

  test('option only accepts Heybet activities', () {
    expect(CombinedHeybetExcelService.isHeybet('Heybet Tepe'), isTrue);
    expect(CombinedHeybetExcelService.isHeybet('Devriye'), isFalse);
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:personelapp2/core/database/database.dart';

/// Synthetic records only; the caller supplies an in-memory database.
Future<int> seedDailyAnalytics(AppDatabase db) async {
  final team = await db.into(db.timTable).insert(TimTableCompanion.insert(
      timAdi: '2-B Timi', olusturmaTarihi: '2026-01-01'));
  final other = await db.into(db.timTable).insert(TimTableCompanion.insert(
      timAdi: '1-B Timi', olusturmaTarihi: '2026-01-01'));
  final people = <int>[];
  for (final name in ['ÖRNEK PERSONEL A', 'ÖRNEK PERSONEL B']) {
    people.add(await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: 'Er',
            birlik: '',
            timId: Value(team),
            kayitTarihi: '2026-01-01')));
  }
  Future<void> activity(String duty, int? teamId, List<int> ids) async {
    final id = await db.into(db.gunlukFaaliyetTable).insert(
        GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: duty,
            tarih: '2026-10-23',
            olusturanKullanici: 'test',
            olusturmaTarihi: '2026-10-23'));
    for (final person in ids) {
      await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
              faaliyetId: id,
              personelId: person,
              gorevVeyaIzin: duty,
              durum: 'onaylandi',
              gorevTimId: Value(teamId)));
    }
  }

  await activity('HAZIR KITA', team, people);
  await activity('DDE', team, [people.first]);
  await activity('HEYBET', other, [people.last]);
  await activity('METİ', null, [people.first]);
  return team;
}

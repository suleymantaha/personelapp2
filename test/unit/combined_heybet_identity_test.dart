import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/services/combined_heybet_excel_service.dart';

void main() {
  test(
    'repeated person across selected previous cards is exported only once',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      for (var i = 0; i < 2; i++) {
        await db
            .into(db.personelTable)
            .insert(
              PersonelTableCompanion.insert(
                adSoyad: 'Aynı İsim',
                rutbe: 'J.Uzm.Çvş.',
                birlik: '',
                kayitTarihi: '',
              ),
            );
      }
      for (final date in ['2026-10-05', '2026-10-05', '2026-10-06']) {
        await db
            .into(db.gunlukFaaliyetTable)
            .insert(
              GunlukFaaliyetTableCompanion.insert(
                faaliyetAdi: 'Heybet',
                tarih: date,
                olusturanKullanici: 'admin',
                olusturmaTarihi: date,
              ),
            );
      }
      for (final source in [(1, 1), (2, 1), (2, 2)]) {
        await db
            .into(db.faaliyetPersonelAtamaTable)
            .insert(
              FaaliyetPersonelAtamaTableCompanion.insert(
                faaliyetId: source.$1,
                personelId: source.$2,
                gorevVeyaIzin: 'HAZIR KITA',
                durum: 'onaylandi',
              ),
            );
      }
      final people = {
        for (final p in await db.select(db.personelTable).get()) p.id: p,
      };
      final anchor = (await db.select(db.gunlukFaaliyetTable).get()).last;
      final before = await db.select(db.faaliyetPersonelAtamaTable).get();
      final rows = await CombinedHeybetExcelService(db).build(
        activity: anchor,
        selectedPreviousActivityIds: {1, 2},
        currentRows: [],
        personnelById: people,
        squadNames: {},
      );
      expect(rows, hasLength(2));
      expect(rows.map((r) => r.sNu), [1, 2]);
      expect(await db.select(db.faaliyetPersonelAtamaTable).get(), before);
    },
  );
}

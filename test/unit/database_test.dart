import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Database tables insert and query test', () async {
    // 1. Insert Tim
    final timId = await db.into(db.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '1. Asayiş Timi',
            olusturmaTarihi: '2026-07-21',
          ),
        );

    // 2. Insert User
    final userId = await db.into(db.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: 'admin_test',
            sifre: const Value('123456'),
            rol: 'yönetici',
          ),
        );

    expect(timId, greaterThan(0));
    expect(userId, greaterThan(0));

    // 3. Insert Personnel
    final pId = await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ahmet Yılmaz',
            rutbe: 'ASB.KD.BÇVŞ',
            birlik: 'Asayiş Timi',
            kayitTarihi: '2026-07-21',
          ),
        );
    expect(pId, greaterThan(0));

    // 4. Insert Activity
    final actId = await db.into(db.gunlukFaaliyetTable).insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: 'Önleyici Kolluk Devriyesi',
            tarih: '2026-07-21',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-07-21',
          ),
        );

    // 5. Insert Assignment
    final atamaId = await db.into(db.faaliyetPersonelAtamaTable).insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: actId,
            personelId: pId,
            gorevVeyaIzin: 'GÖREVLİ',
            durum: 'onaylandi',
          ),
        );
    expect(atamaId, greaterThan(0));

    // Query Personnel List
    final personnelList = await db.select(db.personelTable).get();
    expect(personnelList.length, equals(1));
    expect(personnelList.first.adSoyad, equals('Ahmet Yılmaz'));
  });
}

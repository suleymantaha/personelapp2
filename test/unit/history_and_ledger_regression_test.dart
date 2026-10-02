import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

void main() {
  late AppDatabase db;
  late PersonnelRepository people;
  late int squad;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    people = PersonnelRepository(db);
    squad = await people.addSquad(timAdi: '1-B', olusturmaTarihi: '2026-01-01');
  });
  tearDown(() => db.close());
  Future<int> person(String name) => people.addPersonnel(
    adSoyad: name,
    rutbe: 'J.Er',
    birlik: 'Asayiş',
    timId: squad,
    kayitTarihi: '2026-01-01',
  );
  Future<void> assignment(
    int id,
    String duty, {
    String status = 'onaylandi',
  }) async {
    final activity = await db
        .into(db.gunlukFaaliyetTable)
        .insert(
          GunlukFaaliyetTableCompanion.insert(
            faaliyetAdi: duty,
            tarih: '2026-10-02',
            olusturanKullanici: 'admin',
            olusturmaTarihi: '2026-10-02',
          ),
        );
    await db
        .into(db.faaliyetPersonelAtamaTable)
        .insert(
          FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: activity,
            personelId: id,
            gorevVeyaIzin: duty,
            durum: status,
            gorevTimId: Value(squad),
            gorevTimAdi: const Value('1-B'),
          ),
        );
  }

  Future<dynamic> calendar() => MatrixRepository(
    db,
  ).getTeamMonthlyCalendar(timId: squad, timAdi: '1-B', year: 2026, month: 10);

  test('all duty types on the same day remain visible', () async {
    for (var i = 0; i < 5; i++) {
      await assignment(await person('Gülüşkür $i'), 'GÜLÜŞKÜR');
    }
    for (var i = 0; i < 3; i++) {
      await assignment(await person('Heybet $i'), 'HEYBET');
    }
    final result = await calendar();
    expect(
      result.ozet.gorevTuruDagilimi.keys,
      containsAll(['GÜLÜŞKÜR', 'HEYBET']),
    );
    expect(result.gunler[1].gorevliPersonelAdlari, hasLength(8));
  });

  test(
    'deactivated and demo personnel are excluded from normal selectors',
    () async {
      final real = await person('Gerçek KİŞİ');
      expect(await people.seedTestPersonnelPerSquad(countPerSquad: 1), 1);
      expect(await people.seedTestPersonnelPerSquad(countPerSquad: 1), 0);
      expect(await people.watchAllPersonnelSorted().first, hasLength(1));
      expect(await people.deleteAllPersonnel(), 1);
      expect((await db.select(db.personelTable).get()).single.id, real);
      await people.deletePersonnel(real);
      expect(await people.watchAllPersonnelSorted().first, isEmpty);
      expect(
        await people.watchAllPersonnelSorted(includeInactive: true).first,
        hasLength(1),
      );
    },
  );

  test('departure preserves assignment and medical-report history', () async {
    final id = await person('Ali KAYA');
    await assignment(id, 'HEYBET');
    await db
        .into(db.raporKayitTable)
        .insert(
          RaporKayitTableCompanion.insert(
            personelId: id,
            raporBaslangic: '2026-09-01',
            raporBitis: '2026-09-02',
          ),
        );
    await people.deletePersonnel(id);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), hasLength(1));
    expect(await db.select(db.raporKayitTable).get(), hasLength(1));
    expect(await db.select(db.personelTable).get(), hasLength(1));
  });
  test('failed membership history rolls the personnel transfer back', () async {
    final id = await person('Ali KAYA');
    final other = await people.addSquad(
      timAdi: '2-B',
      olusturmaTarihi: '2026-01-01',
    );
    final record = (await db.select(db.personelTable).get()).single;
    await db.customStatement(
      "CREATE TRIGGER reject_history BEFORE INSERT ON tim_uyelik_gecmisi_table BEGIN SELECT RAISE(ABORT, 'history unavailable'); END",
    );
    await expectLater(
      people.updatePersonnel(record.copyWith(timId: Value(other))),
      throwsA(anything),
    );
    expect(
      (await db.select(db.personelTable).get())
          .singleWhere((p) => p.id == id)
          .timId,
      squad,
    );
  });
  test('renaming a default squad does not recreate its old name', () async {
    await db.delete(db.timTable).go();
    await db.ensureSeeded();
    final seeded = (await db.select(db.timTable).get()).firstWhere(
      (t) => t.timAdi == '1-B Timi',
    );
    await (db.update(db.timTable)..where(
      (t) => t.id.equals(seeded.id),
    )).write(const TimTableCompanion(timAdi: Value('Özel Tim')));
    await people.ensureDefaultSquads();
    expect(
      (await db.select(db.timTable).get()).any((t) => t.timAdi == '1-B Timi'),
      isFalse,
    );
  });
  test('same-name participants count as separate people', () async {
    await assignment(await person('Ali KAYA'), 'HEYBET');
    await assignment(await person('Ali KAYA'), 'HEYBET');
    final result = await calendar();
    expect(result.gunler[1].gorevliPersonelAdlari, hasLength(2));
  });
  test('pending and leave do not inflate approved operational load', () async {
    await assignment(await person('Ali KAYA'), 'HEYBET', status: 'beklemede');
    await assignment(await person('Veli KAYA'), 'İZİNLİ');
    final result = await calendar();
    expect(result.ozet.toplamGorevGunSayisi, 0);
    expect(result.ozet.gorevTuruDagilimi, isEmpty);
  });
  test('daily coverage does not invent a 24 hour duration', () async {
    await assignment(await person('Ali KAYA'), 'HEYBET');
    expect((await calendar()).ozet.toplamGorevSaati, 0);
  });
  test('new short passwords are rejected at the repository boundary', () async {
    await db
        .into(db.kullaniciTable)
        .insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: 'admin',
            rol: 'yönetici',
          ),
        );
    await expectLater(
      people.updateUserPassword(kullaniciAdi: 'admin', newPassword: '1234'),
      throwsArgumentError,
    );
    expect((await db.select(db.kullaniciTable).get()).single.sifre, isEmpty);
  });
}

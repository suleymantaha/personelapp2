import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';

void main() {
  late AppDatabase db;
  late PersonnelRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = PersonnelRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('Adding personnel with squad should log history', () async {
    final timId = await repo.addSquad(
      timAdi: '1. Asayiş Timi',
      olusturmaTarihi: '2026-07-21',
    );

    final pId = await repo.addPersonnel(
      adSoyad: 'Mehmet Demir',
      rutbe: 'UZM.ÇVŞ',
      birlik: 'Asayiş Timi',
      kayitTarihi: '2026-07-21',
      timId: timId,
    );

    final historyList = await repo.watchAllHistory().first;
    expect(historyList.length, equals(1));
    expect(historyList.first.personelId, equals(pId));
    expect(historyList.first.timId, equals(timId));
    expect(historyList.first.islem, equals('eklendi'));
  });

  test(
    'Deleting personnel assigned to squad should log removal history',
    () async {
      final timId = await repo.addSquad(
        timAdi: '2. Asayiş Timi',
        olusturmaTarihi: '2026-07-21',
      );

      final pId = await repo.addPersonnel(
        adSoyad: 'Ali Kaya',
        rutbe: 'ASB.ÇVŞ',
        birlik: 'Asayiş Timi',
        kayitTarihi: '2026-07-21',
        timId: timId,
      );

      await repo.deletePersonnel(pId, tarih: '2026-07-22');

      final historyList = await repo.watchAllHistory().first;
      expect(historyList.length, equals(2));
      expect(historyList.first.islem, equals('çıkarıldı'));
    },
  );

  test('batch import adds unique personnel and skips duplicates', () async {
    final timId = await repo.addSquad(
      timAdi: '3. Asayiş Timi',
      olusturmaTarihi: '2026-08-05',
    );
    await repo.addPersonnel(
      adSoyad: 'Ahmet YILMAZ',
      rutbe: 'J.Asb.Çvş.',
      birlik: 'Asayiş Timi',
      kayitTarihi: '2026-08-05',
      timId: timId,
    );

    final result = await repo.importPersonnelBatch(
      [
        PersonnelImportEntry(
          adSoyad: 'ahmet yilmaz',
          rutbe: 'J.Asb.Çvş.',
          birlik: 'Asayiş Timi',
          timId: timId,
        ),
        PersonnelImportEntry(
          adSoyad: 'Mehmet DEMİR',
          rutbe: 'J.Uzm.Çvş.',
          birlik: 'Asayiş Timi',
          timId: timId,
        ),
        PersonnelImportEntry(
          adSoyad: 'Mehmet DEMİR',
          rutbe: 'J.Uzm.Çvş.',
          birlik: 'Asayiş Timi',
          timId: timId,
        ),
      ],
      kayitTarihi: '2026-08-05',
    );

    expect(result.addedCount, 1);
    expect(result.skippedCount, 2);
    final personnel = await db.select(db.personelTable).get();
    expect(personnel, hasLength(2));
    final history = await db.select(db.timUyelikGecmisiTable).get();
    expect(history, hasLength(2));
  });
}

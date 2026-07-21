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

  test('Deleting personnel assigned to squad should log removal history', () async {
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
  });
}

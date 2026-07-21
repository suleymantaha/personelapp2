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

  test('Reassigning commander to squad should update user and squad table', () async {
    final timId = await repo.addSquad(
      timAdi: '1. Asayiş Timi',
      olusturmaTarihi: '2026-07-21',
    );

    // Create commander user account
    final userId = await db.into(db.kullaniciTable).insert(
          KullaniciTableCompanion.insert(
            kullaniciAdi: 'komutan1',
            sifre: '123456',
            rol: 'tim_komutani',
          ),
        );

    // Reassign commander to timId
    await repo.assignCommanderToSquad(userId: userId, timId: timId);

    final commanders = await repo.watchAllCommanders().first;
    expect(commanders.first.timId, equals(timId));

    // Revoke authority (assign to null)
    await repo.assignCommanderToSquad(userId: userId, timId: null);

    final updatedCommanders = await repo.watchAllCommanders().first;
    expect(updatedCommanders.first.timId, isNull);
  });
}

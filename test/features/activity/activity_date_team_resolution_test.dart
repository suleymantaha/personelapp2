import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repo;
  late int team, person;
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  String day(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset)
        .toIso8601String()
        .split('T')
        .first;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('admin', 'synthetic-test-hash', 'yönetici')");
    repo = ActivityRepository(db);
    team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Saved team', olusturmaTarihi: '2000-01-01'));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(team)));
  });
  tearDown(() => db.close());

  test('moving a planned duty needs no history when its team is unchanged',
      () async {
    final id = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Planned',
        tarih: day(1),
        olusturanKullanici: 'admin',
        actor: admin,
        personnelAssignments: [
          PersonnelAssignmentInput(personnelId: person, duty: 'GÖREVLİ')
        ]);
    final result = await repo.changeActivityDate(
        actor: admin, activityId: id, newDate: day(2));
    expect(result.status, ActivityDateChangeStatus.success);
    expect((await db.select(db.gunlukFaaliyetTable).getSingle()).tarih, day(2));
    final assignment =
        await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(assignment.gorevTimId, team);
    expect(assignment.gorevTimAdi, 'Saved team');
    expect(await db.select(db.timUyelikGecmisiTable).get(), isEmpty);
  });
}

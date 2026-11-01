import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';

const dateChangeAdmin =
    UserSessionState(username: 'admin', role: UserRole.admin);

class DateTeamFixture {
  final db = AppDatabase(NativeDatabase.memory());
  late final repo = ActivityRepository(db);
  late int team, otherTeam, person;

  String day(int offset) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + offset)
        .toIso8601String()
        .split('T')
        .first;
  }

  Future<void> initialize() async {
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('admin', 'synthetic-test-hash', 'yönetici')");
    team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Saved team', olusturmaTarihi: '2000-01-01'));
    otherTeam = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: 'Other team', olusturmaTarihi: '2000-01-01'));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(team)));
  }

  Future<int> create(String date, {int? explicitTeam}) =>
      repo.createActivityWithAssignments(
          faaliyetAdi: 'Planned',
          tarih: date,
          olusturanKullanici: 'admin',
          actor: dateChangeAdmin,
          personnelAssignments: [
            PersonnelAssignmentInput(
                personnelId: person, duty: 'GÖREVLİ', teamId: explicitTeam)
          ]);

  Future<void> history(int teamId, String date) => db
      .into(db.timUyelikGecmisiTable)
      .insert(TimUyelikGecmisiTableCompanion.insert(
          personelId: person,
          timId: Value(teamId),
          tarih: date,
          islem: 'eklendi'));
}

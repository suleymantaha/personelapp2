import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';

void main() {
  late AppDatabase db;
  late ActivityRepository repo;
  late int person, oldTeam, newTeam;
  const admin = UserSessionState(username: 'admin', role: UserRole.admin);
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('admin', 'synthetic-test-hash', 'yönetici')");
    repo = ActivityRepository(db);
    oldTeam = await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: 'Old', olusturmaTarihi: '2000-01-01'));
    newTeam = await db.into(db.timTable).insert(
        TimTableCompanion.insert(timAdi: 'New', olusturmaTarihi: '2000-01-01'));
    person = await db.into(db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Synthetic',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(newTeam)));
  });
  tearDown(() => db.close());

  Future<int> create(String date, {int? team, bool outside = false}) =>
      repo.createActivityWithAssignments(
          faaliyetAdi: 'Synthetic',
          tarih: date,
          olusturanKullanici: 'admin',
          personnelAssignments: [
            PersonnelAssignmentInput(
                personnelId: person,
                duty: 'GÖREVLİ',
                teamId: team,
                isOutsideTeam: outside)
          ],
          actor: admin);
  Future<void> history(int? team, String date, String action) => db
      .into(db.timUyelikGecmisiTable)
      .insert(TimUyelikGecmisiTableCompanion.insert(
          personelId: person, timId: Value(team), tarih: date, islem: action));

  test('past assignment without dated evidence rolls back whole activity',
      () async {
    await expectLater(create('2001-01-02'), throwsStateError);
    expect(await db.select(db.gunlukFaaliyetTable).get(), isEmpty);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
  });
  test('past assignment uses dated old team instead of current membership',
      () async {
    await history(oldTeam, '2000-01-01', 'eklendi');
    await history(newTeam, '2002-01-01', 'eklendi');
    await create('2001-01-02');
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, oldTeam);
    expect(row.gorevTimAdi, 'Old');
  });
  test('explicit task team is retained even when different from membership',
      () async {
    await create('2001-01-02', team: oldTeam);
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, oldTeam);
  });
  test('verified historical removal becomes explicit outside team', () async {
    await history(oldTeam, '2000-01-01', 'eklendi');
    await history(oldTeam, '2001-01-01', 'çıkarıldı');
    await create('2001-01-02');
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, isNull);
    expect(row.gorevTimAdi, 'Tim dışı');
  });
  test('same-day conflicting team events are not guessed', () async {
    await history(oldTeam, '2001-01-02', 'eklendi');
    await history(newTeam, '2001-01-02', 'eklendi');
    await expectLater(create('2001-01-02'), throwsStateError);
  });
  test(
      'single assignment cannot use supplied today date to bypass actual past date',
      () async {
    final id = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Empty',
        tarih: '2001-01-02',
        olusturanKullanici: 'admin',
        personnelAssignments: [],
        actor: admin);
    await expectLater(
        repo.addSingleAssignment(
            faaliyetId: id,
            personelId: person,
            gorevVeyaIzin: 'GÖREVLİ',
            tarih: DateTime.now().toIso8601String().split('T').first,
            actor: admin),
        throwsStateError);
    expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
  });
  test('today snapshot stays unchanged after personnel team changes', () async {
    final today = DateTime.now().toIso8601String().split('T').first;
    await create(today);
    await (db.update(db.personelTable)..where((p) => p.id.equals(person)))
        .write(PersonelTableCompanion(timId: Value(oldTeam)));
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle()).gorevTimId,
        newTeam);
  });
  test('explicit outside choice is saved for a past task without history',
      () async {
    await create('2001-01-02', outside: true);
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, isNull);
    expect(row.gorevTimAdi, 'Tim dışı');
  });
  test('moving legacy unknown to another date rolls back without guessing',
      () async {
    final source = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Source',
        tarih: '2001-01-02',
        olusturanKullanici: 'admin',
        personnelAssignments: [],
        actor: admin);
    final target = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Target',
        tarih: '2001-01-03',
        olusturanKullanici: 'admin',
        personnelAssignments: [],
        actor: admin);
    final id = await db.into(db.faaliyetPersonelAtamaTable).insert(
        FaaliyetPersonelAtamaTableCompanion.insert(
            faaliyetId: source,
            personelId: person,
            gorevVeyaIzin: 'GÖREVLİ',
            durum: 'onaylandi'));
    await expectLater(
        repo.transferPersonnelBetweenActivities(
            assignmentId: id, targetActivityId: target, actor: admin),
        throwsStateError);
    final row = await db.select(db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.id, id);
    expect(row.faaliyetId, source);
    expect(row.gorevTimId, isNull);
    expect(row.gorevTimAdi, isNull);
  });
  test(
      'date edit refuses to silently move a snapshot to a different team period',
      () async {
    await history(oldTeam, '2000-01-01', 'eklendi');
    await history(newTeam, '2002-01-01', 'eklendi');
    final id = await create('2001-01-02');
    await expectLater(
        repo.changeActivityDate(
            actor: admin, activityId: id, newDate: '2002-01-02'),
        throwsStateError);
    expect((await db.select(db.gunlukFaaliyetTable).getSingle()).tarih,
        '2001-01-02');
    expect(
        (await db.select(db.faaliyetPersonelAtamaTable).getSingle()).gorevTimId,
        oldTeam);
  });
  test(
      'new outside personnel has a dated outside event for future past entries',
      () async {
    final id = await PersonnelRepository(db).addPersonnel(
        adSoyad: 'Outside',
        rutbe: 'Er',
        birlik: 'Test',
        kayitTarihi: '2001-01-01');
    final rows = await (db.select(db.timUyelikGecmisiTable)
          ..where((h) => h.personelId.equals(id)))
        .get();
    expect(rows, hasLength(1));
    expect(rows.single.islem, 'çıkarıldı');
    expect(rows.single.timId, isNull);
    expect(rows.single.tarih, '2001-01-01');
  });
  for (final merge in [false, true]) {
    test(
        'stale explicit team confirmation rejects changed target date merge=$merge',
        () async {
      final id = await repo.createActivityWithAssignments(
          faaliyetAdi: 'Changed',
          tarih: '2001-01-03',
          olusturanKullanici: 'admin',
          personnelAssignments: [],
          actor: admin);
      final choices = [
        PersonnelAssignmentInput(
            personnelId: person, duty: 'GÖREVLİ', teamId: oldTeam)
      ];
      await expectLater(
          merge
              ? repo.mergeAssignmentsIntoActivity(
                  activityId: id,
                  updateDifferentAssignments: false,
                  expectedDate: '2001-01-02',
                  personnelAssignments: choices,
                  actor: admin)
              : repo.addAssignmentsToActivity(
                  activityId: id,
                  expectedDate: '2001-01-02',
                  assignments: choices,
                  actor: admin),
          throwsStateError);
      expect(await db.select(db.faaliyetPersonelAtamaTable).get(), isEmpty);
    });
  }
}

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'activity_date_team_test_support.dart';

void main() {
  late DateTeamFixture f;
  setUp(() async {
    f = DateTeamFixture();
    await f.initialize();
  });
  tearDown(() => f.db.close());
  PersonnelAssignmentInput choice({int? teamId, bool outside = false}) =>
      PersonnelAssignmentInput(
          personnelId: f.person,
          duty: 'GÖREVLİ',
          teamId: teamId,
          isOutsideTeam: outside);

  test(
      'confirmed date move updates only its snapshot, not membership or archive',
      () async {
    final archived = await f.create('2001-01-02', explicitTeam: f.team);
    final id = await f.create(f.day(1));
    await f.repo.changeActivityDate(
        activityId: id,
        newDate: '2002-01-02',
        actor: dateChangeAdmin,
        teamConfirmations: [choice(teamId: f.otherTeam)]);
    final rows = await f.db.select(f.db.faaliyetPersonelAtamaTable).get();
    expect(
        rows.singleWhere((a) => a.faaliyetId == archived).gorevTimId, f.team);
    final moved = rows.singleWhere((a) => a.faaliyetId == id);
    expect(moved.gorevTimId, f.otherTeam);
    expect(moved.gorevTimAdi, 'Other team');
    expect((await f.db.select(f.db.personelTable).getSingle()).timId, f.team);
    expect(await f.db.select(f.db.timUyelikGecmisiTable).get(), isEmpty);
  });

  test('explicit outside confirmation changes only moved task', () async {
    final id = await f.create(f.day(1));
    await f.repo.changeActivityDate(
        activityId: id,
        newDate: '2001-01-02',
        actor: dateChangeAdmin,
        teamConfirmations: [choice(outside: true)]);
    final row = await f.db.select(f.db.faaliyetPersonelAtamaTable).getSingle();
    expect(row.gorevTimId, isNull);
    expect(row.gorevTimAdi, 'Tim dışı');
    expect((await f.db.select(f.db.personelTable).getSingle()).timId, f.team);
  });

  for (final invalid in ['unknown-team', 'no-choice', 'duplicate', 'both']) {
    test('invalid confirmation $invalid rolls back date and snapshot',
        () async {
      final id = await f.create(f.day(1));
      final choices = switch (invalid) {
        'unknown-team' => [choice(teamId: 999999)],
        'no-choice' => [choice()],
        'duplicate' => [choice(teamId: f.team), choice(teamId: f.otherTeam)],
        _ => [choice(teamId: f.team, outside: true)],
      };
      await expectLater(
          f.repo.changeActivityDate(
              activityId: id,
              newDate: '2001-01-02',
              actor: dateChangeAdmin,
              teamConfirmations: choices),
          invalid == 'duplicate' ? throwsStateError : throwsArgumentError);
      expect((await f.db.select(f.db.gunlukFaaliyetTable).getSingle()).tarih,
          f.day(1));
      expect(
          (await f.db.select(f.db.faaliyetPersonelAtamaTable).getSingle())
              .gorevTimId,
          f.team);
    });
  }

  test('stale date rejects previously selected team', () async {
    final id = await f.create(f.day(1));
    await f.repo.changeActivityDate(
        activityId: id, newDate: f.day(2), actor: dateChangeAdmin);
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id,
            newDate: '2001-01-02',
            actor: dateChangeAdmin,
            expectedDate: f.day(1),
            teamConfirmations: [choice(teamId: f.otherTeam)]),
        throwsStateError);
    expect((await f.db.select(f.db.gunlukFaaliyetTable).getSingle()).tarih,
        f.day(2));
  });

  test('one invalid team cannot partially update a multi-person date move',
      () async {
    final id = await f.create(f.day(1));
    final second = await f.db.into(f.db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Second',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(f.team)));
    await f.repo.addSingleAssignment(
        faaliyetId: id,
        personelId: second,
        gorevVeyaIzin: 'GÖREVLİ',
        tarih: f.day(1),
        actor: dateChangeAdmin);
    final before = await f.db.select(f.db.faaliyetPersonelAtamaTable).get();
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id,
            newDate: '2001-01-02',
            actor: dateChangeAdmin,
            teamConfirmations: [
              choice(teamId: f.otherTeam),
              PersonnelAssignmentInput(
                  personnelId: second, duty: 'GÖREVLİ', teamId: 999999)
            ]),
        throwsArgumentError);
    expect(await f.db.select(f.db.faaliyetPersonelAtamaTable).get(), before);
    expect((await f.db.select(f.db.gunlukFaaliyetTable).getSingle()).tarih,
        f.day(1));
  });

  test('changed assignment list rejects confirmation atomically', () async {
    final id = await f.create(f.day(1));
    final preview = await f.repo.previewActivityDateChange(
        activityId: id, newDate: f.day(2), actor: dateChangeAdmin);
    final secondPerson = await f.db.into(f.db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Second',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(f.team)));
    await f.repo.addSingleAssignment(
        faaliyetId: id,
        personelId: secondPerson,
        gorevVeyaIzin: 'GÖREVLİ',
        tarih: f.day(1),
        actor: dateChangeAdmin);
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id,
            newDate: f.day(2),
            actor: dateChangeAdmin,
            expectedDate: f.day(1),
            expectedAssignments: preview.assignmentSnapshot),
        throwsStateError);
    expect((await f.db.select(f.db.gunlukFaaliyetTable).getSingle()).tarih,
        f.day(1));
  });

  test('admin role is required even with explicit team confirmation', () async {
    final id = await f.create(f.day(1));
    final leader = UserSessionState(
        username: 'leader', role: UserRole.teamCommander, timId: f.team);
    await expectLater(
        f.repo.previewActivityDateChange(
            activityId: id, newDate: f.day(2), actor: leader),
        throwsA(isA<AuthorizationException>()));
    expect(
        () => f.repo.changeActivityDate(
            activityId: id,
            newDate: '2001-01-02',
            actor: leader,
            teamConfirmations: [choice(teamId: f.team)]),
        throwsA(isA<AuthorizationException>()));
  });
}

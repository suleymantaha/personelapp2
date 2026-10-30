import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
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

  test('team change before planned date move requires explicit choice',
      () async {
    final id = await f.create(f.day(1));
    await (f.db.update(f.db.personelTable)..where((p) => p.id.equals(f.person)))
        .write(PersonelTableCompanion(timId: Value(f.otherTeam)));
    final preview = await f.repo.previewActivityDateChange(
        activityId: id, newDate: f.day(2), actor: dateChangeAdmin);
    expect(preview.teamConfirmationPersonnelIds, {f.person});
    expect(preview.assignmentSnapshot.single.personelId, f.person);
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id, newDate: f.day(2), actor: dateChangeAdmin),
        throwsA(isA<TaskTeamRequiredException>()));
    expect((await f.db.select(f.db.gunlukFaaliyetTable).getSingle()).tarih,
        f.day(1));
    expect(
        (await f.db.select(f.db.faaliyetPersonelAtamaTable).getSingle())
            .gorevTimId,
        f.team);
  });

  test('same historical team moves while preserving original saved name',
      () async {
    await f.history(f.team, '2000-01-01');
    final id = await f.create('2001-01-02');
    await (f.db.update(f.db.timTable)..where((t) => t.id.equals(f.team)))
        .write(const TimTableCompanion(timAdi: Value('Renamed')));
    final preview = await f.repo.previewActivityDateChange(
        activityId: id, newDate: '2001-02-02', actor: dateChangeAdmin);
    expect(preview.teamConfirmationPersonnelIds, isEmpty);
    await f.repo.changeActivityDate(
        activityId: id, newDate: '2001-02-02', actor: dateChangeAdmin);
    expect(
        (await f.db.select(f.db.faaliyetPersonelAtamaTable).getSingle())
            .gorevTimAdi,
        'Saved team');
  });

  test('different dated historical team requires confirmation', () async {
    await f.history(f.team, '2000-01-01');
    await f.history(f.otherTeam, '2002-01-01');
    final id = await f.create('2001-01-02');
    final preview = await f.repo.previewActivityDateChange(
        activityId: id, newDate: '2003-01-02', actor: dateChangeAdmin);
    expect(preview.teamConfirmationPersonnelIds, {f.person});
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id, newDate: '2003-01-02', actor: dateChangeAdmin),
        throwsA(isA<TaskTeamRequiredException>()));
  });

  test('unknown past date requires choice without a current team fallback',
      () async {
    final id = await f.create(f.day(1));
    final preview = await f.repo.previewActivityDateChange(
        activityId: id, newDate: '2001-01-02', actor: dateChangeAdmin);
    expect(preview.teamConfirmationPersonnelIds, {f.person});
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id, newDate: '2001-01-02', actor: dateChangeAdmin),
        throwsA(isA<TaskTeamRequiredException>()));
  });

  test('legacy unknown snapshot requires choice even for future date',
      () async {
    final id = await f.create(f.day(1));
    await f.db.update(f.db.faaliyetPersonelAtamaTable).write(
        const FaaliyetPersonelAtamaTableCompanion(
            gorevTimId: Value(null), gorevTimAdi: Value(null)));
    final preview = await f.repo.previewActivityDateChange(
        activityId: id, newDate: f.day(2), actor: dateChangeAdmin);
    expect(preview.teamConfirmationPersonnelIds, {f.person});
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id, newDate: f.day(2), actor: dateChangeAdmin),
        throwsA(isA<TaskTeamRequiredException>()));
  });
}

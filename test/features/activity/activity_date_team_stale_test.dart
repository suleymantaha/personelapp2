import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'activity_date_team_test_support.dart';

void main() {
  test(
      'deleting and readding the same person invalidates old team confirmation',
      () async {
    final f = DateTeamFixture();
    addTearDown(f.db.close);
    await f.initialize();
    final id = await f.create(f.day(1));
    final preview = await f.repo.previewActivityDateChange(
        activityId: id, newDate: '2001-01-02', actor: dateChangeAdmin);
    final oldAssignment =
        await f.db.select(f.db.faaliyetPersonelAtamaTable).getSingle();
    await f.db.delete(f.db.faaliyetPersonelAtamaTable).go();
    await f.repo.addSingleAssignment(
        faaliyetId: id,
        personelId: f.person,
        gorevVeyaIzin: 'GÖREVLİ',
        tarih: f.day(1),
        taskTeamId: f.otherTeam,
        actor: dateChangeAdmin);
    final replacement =
        await f.db.select(f.db.faaliyetPersonelAtamaTable).getSingle();
    expect(replacement, isNot(oldAssignment));
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id,
            newDate: '2001-01-02',
            actor: dateChangeAdmin,
            expectedDate: preview.oldDate,
            expectedAssignments: preview.assignmentSnapshot,
            teamConfirmations: [
              PersonnelAssignmentInput(
                  personnelId: f.person, duty: 'GÖREVLİ', teamId: f.team)
            ]),
        throwsStateError);
    expect(await f.db.select(f.db.faaliyetPersonelAtamaTable).getSingle(),
        replacement);
    expect((await f.db.select(f.db.gunlukFaaliyetTable).getSingle()).tarih,
        f.day(1));
  });

  test('same assignment ID with changed note invalidates old confirmation',
      () async {
    final f = DateTeamFixture();
    addTearDown(f.db.close);
    await f.initialize();
    final id = await f.create(f.day(1));
    final preview = await f.repo.previewActivityDateChange(
        activityId: id, newDate: f.day(2), actor: dateChangeAdmin);
    await f.db.update(f.db.faaliyetPersonelAtamaTable).write(
        const FaaliyetPersonelAtamaTableCompanion(aciklama: Value('Changed')));
    await expectLater(
        f.repo.changeActivityDate(
            activityId: id,
            newDate: f.day(2),
            actor: dateChangeAdmin,
            expectedDate: preview.oldDate,
            expectedAssignments: preview.assignmentSnapshot),
        throwsStateError);
    expect((await f.db.select(f.db.gunlukFaaliyetTable).getSingle()).tarih,
        f.day(1));
    expect(
        (await f.db.select(f.db.faaliyetPersonelAtamaTable).getSingle())
            .aciklama,
        'Changed');
  });
}

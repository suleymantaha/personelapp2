import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

import 'activity_date_team_test_support.dart';

void main() {
  late DateTeamFixture f;
  late int source;
  late String sourceDate, targetDate;
  setUp(() async {
    f = DateTeamFixture();
    await f.initialize();
    final now = DateTime.now();
    sourceDate =
        DateTime(now.year, now.month + 2, 0).toIso8601String().split('T').first;
    targetDate =
        DateTime(now.year, now.month + 2, 1).toIso8601String().split('T').first;
    source = await f.repo.createActivityWithAssignments(
        faaliyetAdi: 'Copy source',
        tarih: sourceDate,
        olusturanKullanici: 'original',
        actor: dateChangeAdmin,
        personnelAssignments: [
          PersonnelAssignmentInput(
            personnelId: f.person,
            duty: 'METİ',
            note: 'Source note',
            teamId: f.otherTeam,
          )
        ]);
  });
  tearDown(() => f.db.close());

  Future<ActivityAssignmentBatchResult> copy() => f.repo.copyActivityToDate(
      activityId: source, newDate: targetDate, actor: dateChangeAdmin);

  test('copies exact personnel duty and note across month using target team',
      () async {
    final before = await f.db.select(f.db.faaliyetPersonelAtamaTable).get();
    final result = await copy();
    expect(result.addedCount, 1);
    final rows = await f.db.select(f.db.faaliyetPersonelAtamaTable).get();
    expect(rows.where((r) => r.faaliyetId == source).toList(), before);
    final target = rows.singleWhere((r) => r.faaliyetId != source);
    expect(target.personelId, f.person);
    expect(target.gorevVeyaIzin, 'METİ');
    expect(target.aciklama, 'Source note');
    expect(target.gorevTimId, f.team);
    expect(target.durum, 'onaylandi');
    final matrix = await MatrixRepository(f.db)
        .watchMonthlyMatrix(targetDate.substring(0, 7))
        .first;
    expect(matrix[f.person]?[1]?.displayCode, 'X');
    final original = await (f.db.select(f.db.gunlukFaaliyetTable)
          ..where((t) => t.id.equals(source)))
        .getSingle();
    expect(original.tarih, sourceDate);
    expect(original.olusturanKullanici, 'original');
  });

  test('repeated copy reuses target card without duplicates', () async {
    await copy();
    final result = await copy();
    expect(result.addedCount, 0);
    expect(result.alreadyAssignedCount, 1);
    expect(await f.db.select(f.db.gunlukFaaliyetTable).get(), hasLength(2));
    expect(
        await f.db.select(f.db.faaliyetPersonelAtamaTable).get(), hasLength(2));
  });

  test('conflict skips personnel and leaves no empty destination', () async {
    await f.repo.createActivityWithAssignments(
        faaliyetAdi: 'Other duty',
        tarih: targetDate,
        olusturanKullanici: 'admin',
        actor: dateChangeAdmin,
        personnelAssignments: [
          PersonnelAssignmentInput(personnelId: f.person, duty: 'GÖREVLİ')
        ]);
    final result = await copy();
    expect(result.addedCount, 0);
    expect(result.conflictSkippedCount, 1);
    expect(result.conflictDescriptions, hasLength(1));
    expect(await f.db.select(f.db.gunlukFaaliyetTable).get(), hasLength(2));
  });

  test('unknown past team rolls back destination then accepts confirmation',
      () async {
    const past = '2000-01-01';
    await expectLater(
        f.repo.copyActivityToDate(
            activityId: source, newDate: past, actor: dateChangeAdmin),
        throwsA(isA<TaskTeamRequiredException>()));
    expect(await f.db.select(f.db.gunlukFaaliyetTable).get(), hasLength(1));
    final result = await f.repo.copyActivityToDate(
        activityId: source,
        newDate: past,
        actor: dateChangeAdmin,
        teamConfirmations: [
          PersonnelAssignmentInput(
              personnelId: f.person,
              duty: 'IGNORED',
              note: 'IGNORED',
              isOutsideTeam: true)
        ]);
    expect(result.addedCount, 1);
    final target = (await f.db.select(f.db.faaliyetPersonelAtamaTable).get())
        .singleWhere((r) => r.faaliyetId != source);
    expect(target.gorevTimAdi, 'Tim dışı');
    expect(target.gorevVeyaIzin, 'METİ');
    expect(target.aciklama, 'Source note');
  });

  test('stale source snapshot aborts without adding destination', () async {
    final snapshot = await f.db.select(f.db.faaliyetPersonelAtamaTable).get();
    await (f.db.update(f.db.faaliyetPersonelAtamaTable)
          ..where((r) => r.faaliyetId.equals(source)))
        .write(const FaaliyetPersonelAtamaTableCompanion(
            aciklama: Value('edited')));
    await expectLater(
        f.repo.copyActivityToDate(
            activityId: source,
            newDate: targetDate,
            actor: dateChangeAdmin,
            expectedDate: sourceDate,
            expectedAssignments: snapshot),
        throwsStateError);
    expect(await f.db.select(f.db.gunlukFaaliyetTable).get(), hasLength(1));
  });

  test('same date invalid date missing source and stale date reject', () async {
    for (final date in [sourceDate, '2026-02-30']) {
      await expectLater(
          f.repo.copyActivityToDate(
              activityId: source, newDate: date, actor: dateChangeAdmin),
          throwsArgumentError);
    }
    await expectLater(
        f.repo.copyActivityToDate(
            activityId: -1, newDate: targetDate, actor: dateChangeAdmin),
        throwsArgumentError);
    await expectLater(
        f.repo.copyActivityToDate(
            activityId: source,
            newDate: targetDate,
            actor: dateChangeAdmin,
            expectedDate: 'stale'),
        throwsStateError);
    expect(await f.db.select(f.db.gunlukFaaliyetTable).get(), hasLength(1));
  });
}

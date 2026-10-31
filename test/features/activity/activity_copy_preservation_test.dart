import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';

import 'activity_date_team_test_support.dart';

void main() {
  late DateTeamFixture f;
  setUp(() async {
    f = DateTeamFixture();
    await f.initialize();
  });
  tearDown(() => f.db.close());

  test(
      'existing target row stays byte-equal while missing source person is added',
      () async {
    final second = await f.db.into(f.db.personelTable).insert(
        PersonelTableCompanion.insert(
            adSoyad: 'Second source person',
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(f.team)));
    final source = await f.repo.createActivityWithAssignments(
        faaliyetAdi: 'Same card',
        tarih: f.day(2),
        olusturanKullanici: 'source owner',
        actor: dateChangeAdmin,
        personnelAssignments: [
          PersonnelAssignmentInput(
              personnelId: f.person,
              duty: 'METİ',
              note: 'Source note',
              teamId: f.team),
          PersonnelAssignmentInput(
              personnelId: second,
              duty: 'GÖREVLİ',
              note: 'Added note',
              teamId: f.team),
        ]);
    final target = await f.repo.createActivityWithAssignments(
        faaliyetAdi: 'Same card',
        tarih: f.day(5),
        olusturanKullanici: 'target owner',
        actor: dateChangeAdmin,
        personnelAssignments: [
          PersonnelAssignmentInput(
              personnelId: f.person,
              duty: 'İZİNLİ',
              note: 'Target note',
              teamId: f.otherTeam)
        ]);
    await (f.db.update(f.db.faaliyetPersonelAtamaTable)
          ..where((r) => r.faaliyetId.equals(target)))
        .write(const FaaliyetPersonelAtamaTableCompanion(
            durum: Value('beklemede')));
    Future<List<FaaliyetPersonelAtamaTableData>> rows(int activity) =>
        (f.db.select(f.db.faaliyetPersonelAtamaTable)
              ..where((r) => r.faaliyetId.equals(activity)))
            .get();
    final sourceBefore =
        jsonEncode((await rows(source)).map((r) => r.toJson()).toList());
    final targetBefore = (await rows(target)).single;
    final targetBytes = jsonEncode(targetBefore.toJson());

    final result = await f.repo.copyActivityToDate(
        activityId: source, newDate: f.day(5), actor: dateChangeAdmin);

    expect(result.addedCount, 1);
    expect(result.alreadyAssignedCount, 1);
    expect(result.conflictSkippedCount, 0);
    final after = await rows(target);
    expect(after, hasLength(2));
    expect(
        jsonEncode(after.singleWhere((r) => r.id == targetBefore.id).toJson()),
        targetBytes);
    final added = after.singleWhere((r) => r.personelId == second);
    expect(added.gorevVeyaIzin, 'GÖREVLİ');
    expect(added.aciklama, 'Added note');
    expect(jsonEncode((await rows(source)).map((r) => r.toJson()).toList()),
        sourceBefore);
    expect(await f.db.select(f.db.gunlukFaaliyetTable).get(), hasLength(2));
  });

  test('matrix subscription opened before copy emits the copied target entry',
      () async {
    final source = await f.create(f.day(2));
    final targetDate = f.day(5);
    final day = DateTime.parse(targetDate).day;
    final iterator = StreamIterator(
        MatrixRepository(f.db).watchMonthlyMatrix(targetDate.substring(0, 7)));
    addTearDown(iterator.cancel);
    expect(
        await iterator.moveNext().timeout(const Duration(seconds: 5)), isTrue);
    expect(iterator.current[f.person]?[day], isNull);
    final nextEmission = iterator.moveNext();

    await f.repo.copyActivityToDate(
        activityId: source, newDate: targetDate, actor: dateChangeAdmin);

    expect(await nextEmission.timeout(const Duration(seconds: 5)), isTrue);
    final copied = iterator.current[f.person]?[day];
    expect(copied?.displayCode, 'X');
    expect(copied?.entries.single.sourceDate, targetDate);
    expect(copied?.entries.single.duty, 'GÖREVLİ');
    expect(copied?.entries.single.activityId, isNot(source));
  });
}

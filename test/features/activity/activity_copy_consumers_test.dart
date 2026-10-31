import 'package:drift/drift.dart' show Value;
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/authorization_exception.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/analytics/data/team_analytics_repository.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

import 'activity_date_team_test_support.dart';

void main() {
  late DateTeamFixture f;
  late int source, second, unselected;
  late String targetDate;
  setUp(() async {
    f = DateTeamFixture();
    await f.initialize();
    Future<int> person(String name) =>
        f.db.into(f.db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: name,
            rutbe: 'Er',
            birlik: 'Test',
            kayitTarihi: '2000-01-01',
            timId: Value(f.team)));
    second = await person('Second selected');
    unselected = await person('Not in source');
    targetDate = f.day(10);
    source = await f.repo.createActivityWithAssignments(
        faaliyetAdi: 'Copy consumer',
        tarih: f.day(5),
        olusturanKullanici: 'admin',
        actor: dateChangeAdmin,
        personnelAssignments: [
          PersonnelAssignmentInput(personnelId: f.person, duty: 'METİ'),
          PersonnelAssignmentInput(
              personnelId: second, duty: 'GÖREVLİ', note: 'Second note'),
        ]);
  });
  tearDown(() => f.db.close());

  test('mixed duties copy exact source people into analytics matrix and Excel',
      () async {
    final result = await f.repo.copyActivityToDate(
        activityId: source, newDate: targetDate, actor: dateChangeAdmin);
    expect(result.addedCount, 2);
    final report = await TeamAnalyticsRepository(f.db).load(
        AnalyticsFilter(start: targetDate, end: targetDate), dateChangeAdmin);
    expect(report.entries.map((r) => (r.personnelId, r.duty)).toSet(),
        {(f.person, 'METİ'), (second, 'GÖREVLİ')});
    expect(report.metrics.personnelTasks, 2);
    expect(report.metrics.uniquePersonnel, 2);
    final date = DateTime.parse(targetDate);
    final matrix = await MatrixRepository(f.db)
        .watchMonthlyMatrix(targetDate.substring(0, 7))
        .first;
    expect(matrix[f.person]?[date.day]?.displayCode, 'X');
    expect(matrix[second]?[date.day]?.displayCode, 'X');
    expect(matrix[unselected]?[date.day], isNull);
    final people = await f.db.select(f.db.personelTable).get();
    final workbook = Excel.decodeBytes(ExcelXmlGenerator.generateExcelBytes(
        personnel: people,
        matrixData: matrix,
        year: date.year,
        month: date.month));
    final sheet = workbook.tables['Aylık Faaliyet Matrisi']!;
    for (var i = 0; i < people.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: date.day + 2, rowIndex: i + 1));
      expect(cell.value.toString(), people[i].id == unselected ? '-' : 'X');
    }
  });

  test('partial conflict retains valid people without changing source',
      () async {
    final before = await (f.db.select(f.db.faaliyetPersonelAtamaTable)
          ..where((r) => r.faaliyetId.equals(source)))
        .get();
    await f.repo.createActivityWithAssignments(
        faaliyetAdi: 'Conflict',
        tarih: targetDate,
        olusturanKullanici: 'admin',
        actor: dateChangeAdmin,
        personnelAssignments: [
          PersonnelAssignmentInput(personnelId: second, duty: 'GÖREVLİ')
        ]);
    final result = await f.repo.copyActivityToDate(
        activityId: source, newDate: targetDate, actor: dateChangeAdmin);
    expect(result.addedCount, 1);
    expect(result.conflictSkippedCount, 1);
    expect(
        await (f.db.select(f.db.faaliyetPersonelAtamaTable)
              ..where((r) => r.faaliyetId.equals(source)))
            .get(),
        before);
  });

  test('non-admin copy is rejected without writes', () async {
    await expectLater(
        f.repo.copyActivityToDate(
            activityId: source,
            newDate: targetDate,
            actor: const UserSessionState(
                username: 'commander', role: UserRole.teamCommander, timId: 1)),
        throwsA(isA<AuthorizationException>()));
    expect(await f.db.select(f.db.gunlukFaaliyetTable).get(), hasLength(1));
  });

  test('foreign and duplicate confirmations are rejected atomically', () async {
    for (final choices in [
      [PersonnelAssignmentInput(personnelId: unselected, duty: 'GÖREVLİ')],
      [
        for (var i = 0; i < 2; i++)
          PersonnelAssignmentInput(personnelId: second, duty: 'GÖREVLİ')
      ],
    ]) {
      await expectLater(
          f.repo.copyActivityToDate(
              activityId: source,
              newDate: targetDate,
              actor: dateChangeAdmin,
              teamConfirmations: choices),
          throwsStateError);
    }
    expect(await f.db.select(f.db.gunlukFaaliyetTable).get(), hasLength(1));
  });
}

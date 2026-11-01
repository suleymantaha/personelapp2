import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/data/activity_repository.dart';
import 'package:personelapp2/features/analytics/data/team_analytics_repository.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/domain/monthly_analytics_report.dart';
import 'package:personelapp2/features/analytics/services/monthly_analytics_excel_exporter.dart';
import 'package:personelapp2/features/matrix/data/matrix_repository.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

void main() {
  test(
      'selected team reassign updates archive matrix analytics and Excel together',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customStatement(
        "INSERT INTO kullanici_table (kullanici_adi, sifre, rol) VALUES ('admin', 'synthetic-test-hash', 'yönetici')");
    addTearDown(db.close);
    const actor = UserSessionState(username: 'admin', role: UserRole.admin);
    final repo = ActivityRepository(db);
    final teams = [
      for (var i = 0; i < 2; i++)
        await db.into(db.timTable).insert(TimTableCompanion.insert(
            timAdi: 'Test $i', olusturmaTarihi: '2026-01-01'))
    ];
    final people = [
      for (var i = 0; i < 3; i++)
        await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
            adSoyad: 'Test Personel $i',
            rutbe: 'Er',
            birlik: 'Test',
            timId: Value(teams[i == 2 ? 1 : 0]),
            kayitTarihi: '2026-01-01'))
    ];
    final activity = await repo.createActivityWithAssignments(
        faaliyetAdi: 'Test Kart',
        tarih: '2026-10-31',
        olusturanKullanici: 'admin',
        actor: actor,
        personnelAssignments: [
          for (var i = 0; i < people.length; i++)
            PersonnelAssignmentInput(
                personnelId: people[i],
                duty: 'HAZIR KITA',
                teamId: teams[i == 2 ? 1 : 0],
                note: 'Korunan not $i')
        ]);
    final before = await db.select(db.faaliyetPersonelAtamaTable).get();
    final selected = before.where((a) => a.gorevTimId == teams.first).toList();
    final matrix = MatrixRepository(db);
    expect((await matrix.watchMonthlyMatrix('2026-11').first).keys,
        unorderedEquals(people));
    await repo.updateExistingAssignmentDuties(
        activityId: activity,
        assignmentIds: selected.map((a) => a.id),
        duty: 'METİ',
        actor: actor);
    final archived = await repo.watchAssignmentsByDate('2026-10-31').first;
    expect(archived.map((a) => a.id), unorderedEquals(before.map((a) => a.id)));
    for (final row in archived) {
      final old = before.singleWhere((a) => a.id == row.id);
      expect(row.aciklama, old.aciklama);
      expect(row.gorevTimId, old.gorevTimId);
      expect(row.gorevVeyaIzin,
          row.personelId == people.last ? 'HAZIR KITA' : 'METİ');
    }
    final cells = await matrix.watchMonthlyMatrix('2026-10').first;
    for (final person in people.take(2)) {
      expect(cells[person]![31]!.displayCode, 'X');
    }
    final november = await matrix.watchMonthlyMatrix('2026-11').first;
    expect(november.keys, [people.last]);
    final analytics = await TeamAnalyticsRepository(db)
        .load(AnalyticsFilter(start: '2026-10-01', end: '2026-10-31'), actor);
    final report =
        MonthlyAnalyticsReport(data: analytics, asOf: DateTime(2026, 11, 1));
    expect(report.assignmentCount, 3);
    expect(report.uniquePersonnel, 3);
    expect(analytics.entries.where((a) => a.duty == 'METİ').length, 2);
    final personnel = await db.select(db.personelTable).get();
    final book = Excel.decodeBytes(ExcelXmlGenerator.generateExcelBytes(
        personnel: personnel, matrixData: cells, year: 2026, month: 10));
    final sheet = book.tables.values.single;
    for (var i = 0; i < 2; i++) {
      expect(sheet.rows[i + 1][33]!.value.toString(), 'X');
    }
    final analyticsBook =
        Excel.decodeBytes(MonthlyAnalyticsExcelExporter.generate(report));
    expect(analyticsBook['Özet'].cell(CellIndex.indexByString('B8')).value,
        IntCellValue(3));
    expect(analyticsBook['Özet'].cell(CellIndex.indexByString('B9')).value,
        IntCellValue(3));
  });
}

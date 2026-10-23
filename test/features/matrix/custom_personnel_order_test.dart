import 'package:excel/excel.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/matrix/domain/matrix_personnel_order.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';

void main() {
  PersonelTableData person(
          int id, String name, String rank, int team, int? order) =>
      PersonelTableData(
          id: id,
          adSoyad: name,
          rutbe: rank,
          birlik: '',
          timId: team,
          aktif: true,
          isDemo: false,
          kayitTarihi: '',
          sortOrder: order);
  TimTableData team(int id, String name, int? order) =>
      TimTableData(id: id, timAdi: name, olusturmaTarihi: '', sortOrder: order);
  FaaliyetPersonelAtamaTableData assignment(PersonelTableData p) =>
      FaaliyetPersonelAtamaTableData(
          id: p.id,
          faaliyetId: 1,
          personelId: p.id,
          gorevTimId: p.timId,
          gorevTimAdi: '1-B Timi',
          gorevVeyaIzin: 'HEYBET',
          durum: 'onaylandi');

  test('matrix uses saved team and person order before rank and name', () {
    final people = [
      person(1, 'Ali', 'J.Alb.', 1, 1),
      person(2, 'Zeki', 'J.Er', 1, 0),
      person(3, 'Veli', 'J.Er', 2, 0),
      person(4, 'Yeni', 'J.Alb.', 1, null),
    ];
    final result = orderMatrixPersonnel(
        people, [team(1, '1-B Timi', 1), team(2, '2-B Timi', 0)]);
    expect(result.map((p) => p.id), [3, 2, 1, 4]);
    expect(people.map((p) => p.id), [1, 2, 3, 4]);
  });

  test('exports preserve rank but use saved order instead of name for ties',
      () {
    final people = [
      person(1, 'Ali', 'J.Er', 1, 1),
      person(2, 'Zeki', 'J.Er', 1, 0),
      person(3, 'Veli', 'J.Alb.', 1, 2),
    ];
    final result = orderAssignmentsForExport(people.map(assignment),
        {for (final p in people) p.id: p}, {1: '1-B Timi'});
    expect(result.map((a) => a.personelId), [3, 2, 1]);
  });

  test('old records without custom order keep official rank/name fallback', () {
    final people = [
      person(1, 'Zeki', 'J.Er', 1, null),
      person(2, 'Ali', 'J.Er', 1, null)
    ];
    expect(
        orderMatrixPersonnel(people, [team(1, '1-B Timi', null)])
            .map((p) => p.id),
        [2, 1]);
  });
  test('native matrix Excel stores names in the saved row order', () {
    final people = [
      person(1, 'Ali', 'J.Alb.', 1, 1),
      person(2, 'Zeki', 'J.Er', 1, 0)
    ];
    final rows = orderMatrixPersonnel(people, [team(1, '1-B Timi', 0)]);
    final bytes = ExcelXmlGenerator.generateExcelBytes(
        personnel: rows, matrixData: {}, year: 2026, month: 10);
    final sheet = Excel.decodeBytes(bytes).tables.values.single;
    expect(sheet.rows.skip(1).map((r) => r[2]?.value.toString()).take(2),
        ['Zeki', 'Ali']);
  });

  test('equal ranks in a combined unit follow saved historical team order', () {
    final a = person(1, 'Ali', 'J.Er', 1, 0);
    final b = person(2, 'Zeki', 'J.Er', 2, 0);
    final rows = [assignment(a), assignment(b)];
    final ordered = orderAssignmentsForExport(
        rows, {1: a, 2: b}, {1: '1-B Timi', 2: '2-B Timi'},
        squadOrders: {1: 1, 2: 0});
    expect(ordered.map((a) => a.personelId), [2, 1]);
  });

  test('missing teams sort after known teams with a consistent order', () {
    final people = [
      person(1, 'A', 'J.Er', 1, null),
      person(2, 'B', 'J.Er', 2, null),
      person(3, 'C', 'J.Er', 3, null)
    ];
    final squads = [team(1, '1-B Timi', 1), team(3, '3-B Timi', 0)];
    for (final input in [
      people,
      people.reversed.toList(),
      [people[1], people[2], people[0]]
    ]) {
      expect(orderMatrixPersonnel(input, squads).map((p) => p.id), [3, 1, 2]);
    }
  });
}

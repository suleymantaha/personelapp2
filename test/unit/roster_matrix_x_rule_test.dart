import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_matrix_x_rule.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';

MilitaryRosterRow row(int id, int number, String rank) => MilitaryRosterRow(
      sNu: number,
      personelId: id,
      birligi: '1-B',
      rutbe: rank,
      adSoyad: 'PERSONEL $id',
      diger: 'Görev',
      groupCode: 'HAZIR_KITA',
    );

const xCell = MatrixDayCell(
  displayCode: 'X',
  entries: [],
  hasConflict: false,
);

Map<int, MatrixDayCell> days(int xCount, {bool pendingOnLastDay = false}) => {
      for (var day = 1; day <= xCount; day++) day: xCell,
      if (pendingOnLastDay)
        31: const MatrixDayCell(
          displayCode: 'B',
          entries: [],
          hasConflict: false,
        ),
    };

void main() {
  test('keeps exactly 20 X days, excludes 21, then ranks remaining rows', () {
    final original = [
      row(1, 1, 'J.Er'),
      row(2, 2, 'J.Er'),
      row(3, 3, 'J.Yzb.'),
      row(4, 4, 'J.Er'),
    ];
    final result = applyRosterMatrixXRule(
        original,
        {
          1: days(20, pendingOnLastDay: true),
          2: days(21),
          3: days(1),
          4: days(20),
        },
        throughDay: 31);

    expect(result.excludedCount, 1);
    expect(result.excludedPeople.single.row.personelId, 2);
    expect(result.excludedPeople.single.xDays, 21);
    expect(result.rows.map((r) => r.personelId), [3, 1, 4]);
    expect(result.rows.map((r) => r.sNu), [1, 2, 3]);
    expect(result.rows.map((r) => r.groupCode), everyElement('HAZIR_KITA'));
    expect(original.map((r) => r.personelId), [1, 2, 3, 4]);
    expect(original.map((r) => r.sNu), [1, 2, 3, 4]);
  });

  test('empty result is explicit and missing person identity is rejected', () {
    final result = applyRosterMatrixXRule([
      row(1, 1, 'J.Er')
    ], {
      1: days(21),
    }, throughDay: 31);
    expect(result.rows, isEmpty);
    expect(result.excludedCount, 1);
    expect(result.excludedPeople.single.xDays, 21);

    final noId = MilitaryRosterRow(
      sNu: 1,
      birligi: '1-B',
      rutbe: 'J.Er',
      adSoyad: 'KİMLİKSİZ',
      diger: '',
    );
    expect(() => applyRosterMatrixXRule([noId], {}, throughDay: 31),
        throwsStateError);
  });

  test('20th X on day 25 still prints; another X on day 26 excludes', () {
    final person = row(7, 1, 'J.Er');
    final throughDay25 = {
      for (var day = 1; day <= 19; day++) day: xCell,
      25: xCell,
    };
    final resultAt20 = applyRosterMatrixXRule(
      [person],
      {7: throughDay25},
      throughDay: 25,
    );
    expect(resultAt20.rows.single.personelId, 7);
    expect(resultAt20.excludedPeople, isEmpty);

    final throughDay26 = {
      ...throughDay25,
      26: xCell,
    };
    final resultAt21 = applyRosterMatrixXRule(
      [person],
      {7: throughDay26},
      throughDay: 26,
    );
    expect(resultAt21.rows, isEmpty);
    expect(resultAt21.excludedPeople.single.row.adSoyad, 'PERSONEL 7');
    expect(resultAt21.excludedPeople.single.xDays, 21);
    expect(throughDay26, hasLength(21));
  });

  test('future X marks do not remove a person from an earlier output day', () {
    final person = row(7, 1, 'J.Er');
    final month = {
      7: {
        for (var day = 1; day <= 19; day++) day: xCell,
        25: xCell,
        26: xCell,
        31: xCell,
      },
    };

    final on25 = applyRosterMatrixXRule([person], month, throughDay: 25);
    expect(on25.rows.single.personelId, 7);
    expect(on25.excludedPeople, isEmpty);

    final on26 = applyRosterMatrixXRule([person], month, throughDay: 26);
    expect(on26.rows, isEmpty);
    expect(on26.excludedPeople.single.xDays, 21);
    expect(month[7], hasLength(22));
  });
}

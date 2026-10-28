import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_rank_order.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';

class RosterMatrixXResult {
  const RosterMatrixXResult({
    required this.rows,
    required this.excludedPeople,
  });

  final List<MilitaryRosterRow> rows;
  final List<RosterMatrixXExcludedPerson> excludedPeople;
  int get excludedCount => excludedPeople.length;
}

class RosterMatrixXExcludedPerson {
  const RosterMatrixXExcludedPerson({
    required this.row,
    required this.xDays,
  });

  final MilitaryRosterRow row;
  final int xDays;
}

/// Matrix data must be scoped to the selected month and authorized user.
/// Only days through the selected output date count toward the X limit.
RosterMatrixXResult applyRosterMatrixXRule(
  List<MilitaryRosterRow> rows,
  Map<int, Map<int, MatrixDayCell>> matrixData, {
  required int throughDay,
}) {
  if (throughDay < 1 || throughDay > 31) {
    throw RangeError.range(throughDay, 1, 31, 'throughDay');
  }
  final included = <MilitaryRosterRow>[];
  final excluded = <RosterMatrixXExcludedPerson>[];
  for (final row in rows) {
    final id = row.personelId;
    if (id == null) throw StateError('Personel kimliği eksik.');
    final xDays = matrixData[id]
            ?.entries
            .where((entry) =>
                entry.key <= throughDay && entry.value.displayCode == 'X')
            .length ??
        0;
    if (xDays > 20) {
      excluded.add(RosterMatrixXExcludedPerson(row: row, xDays: xDays));
    } else {
      included.add(row);
    }
  }
  return RosterMatrixXResult(
    rows: List.unmodifiable(rankOrderedRosterRows(included)),
    excludedPeople: List.unmodifiable(excluded),
  );
}

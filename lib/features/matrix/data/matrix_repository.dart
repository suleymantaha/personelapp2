import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';

class MatrixRepository {
  MatrixRepository(this.db);

  final AppDatabase db;

  Stream<Map<int, Map<int, MatrixDayCell>>> watchMonthlyMatrix(
    String yearMonth,
  ) {
    final monthStart = DateTime.tryParse('$yearMonth-01');
    if (monthStart == null) {
      return Stream.value(const <int, Map<int, MatrixDayCell>>{});
    }
    final nextMonth = DateTime(monthStart.year, monthStart.month + 1);
    final query = db.select(db.faaliyetPersonelAtamaTable).join([
      innerJoin(
        db.gunlukFaaliyetTable,
        db.gunlukFaaliyetTable.id.equalsExp(
          db.faaliyetPersonelAtamaTable.faaliyetId,
        ),
      ),
    ])
      ..where(
        db.gunlukFaaliyetTable.tarih.isBiggerOrEqualValue(
              DateFormat(
                'yyyy-MM-dd',
              ).format(monthStart.subtract(const Duration(days: 1))),
            ) &
            db.gunlukFaaliyetTable.tarih.isSmallerThanValue(
              DateFormat('yyyy-MM-dd').format(nextMonth),
            ),
      );

    return query.watch().map((rows) {
      final entriesByPersonAndDay =
          <int, Map<int, List<MatrixDayEntry>>>{};
      for (final row in rows) {
        final assignment = row.readTable(db.faaliyetPersonelAtamaTable);
        if (assignment.durum == AssignmentStatus.reddedildi) continue;
        final activity = row.readTable(db.gunlukFaaliyetTable);
        final coveredDates = DutyCoverage.coveredDates(
          startDate: activity.tarih,
          duty: assignment.gorevVeyaIzin,
        );
        for (var index = 0; index < coveredDates.length; index++) {
          final coveredDate = coveredDates[index];
          if (!coveredDate.startsWith(yearMonth)) continue;
          final day = int.tryParse(coveredDate.substring(8, 10));
          if (day == null) continue;
          final personDays = entriesByPersonAndDay.putIfAbsent(
            assignment.personelId,
            () => {},
          );
          personDays.putIfAbsent(day, () => []).add(
                MatrixDayEntry(
                  activityId: activity.id,
                  activityName: activity.faaliyetAdi,
                  duty: assignment.gorevVeyaIzin,
                  assignmentStatus: assignment.durum,
                  sourceDate: activity.tarih,
                  isContinuationDay: index > 0,
                  note: assignment.aciklama,
                ),
              );
        }
      }

      return entriesByPersonAndDay.map(
        (personnelId, days) => MapEntry(
          personnelId,
          days.map(
            (day, entries) => MapEntry(day, MatrixDayCell.fromEntries(entries)),
          ),
        ),
      );
    });
  }
}

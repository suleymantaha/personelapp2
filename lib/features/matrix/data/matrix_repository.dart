import 'package:drift/drift.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

class MatrixRepository {
  final AppDatabase db;

  MatrixRepository(this.db);

  /// Returns a stream mapping personnelId to a map of (dayNumber -> dutyStatusString) for a given yearMonth ("YYYY-MM").
  Stream<Map<int, Map<int, String>>> watchMonthlyMatrix(String yearMonth) {
    // Combine activities, assignments, and personnel
    final activityStream = db.select(db.gunlukFaaliyetTable).watch();
    final assignmentStream = db.select(db.faaliyetPersonelAtamaTable).watch();

    return activityStream.asyncMap((activities) async {
      final assignments = await assignmentStream.first;

      // Filter activities matching yearMonth (e.g. "2026-07")
      final monthActivities = activities
          .where((act) => act.tarih.startsWith(yearMonth))
          .toList();

      final actIdToDate = {for (var act in monthActivities) act.id: act.tarih};
      final targetActIds = actIdToDate.keys.toSet();

      // Filter assignments for target activities
      final monthAssignments = assignments
          .where((atama) => targetActIds.contains(atama.faaliyetId))
          .toList();

      final matrixMap = <int, Map<int, String>>{};

      for (final atama in monthAssignments) {
        final dateStr = actIdToDate[atama.faaliyetId];
        if (dateStr == null) continue;

        final dayPart = dateStr.split('-').last;
        final day = int.tryParse(dayPart);
        if (day == null) continue;

        final pMap = matrixMap.putIfAbsent(atama.personelId, () => {});
        pMap[day] = atama.gorevVeyaIzin;
      }

      return matrixMap;
    });
  }
}

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

/// Read-only output projection, deliberately separate from assignment creation,
/// duty coverage, archive records and personnel history.
class HeybetRosterProjection {
  const HeybetRosterProjection(this.db);
  final AppDatabase db;

  static bool isHeybet(String name) =>
      RegExp(r'(^|\s)HEYBET(\s|$)').hasMatch(name.toUpperCase().trim());

  Future<List<MilitaryRosterRow>> appendPreviousDay({
    required List<GunlukFaaliyetTableData> activities,
    required List<MilitaryRosterRow> rows,
    required Map<int, PersonelTableData> personnelById,
    required Map<int, String> squadNames,
  }) async {
    final previousDates = <String>{};
    for (final activity in activities.where((a) => isHeybet(a.faaliyetAdi))) {
      final date = DateTime.tryParse(activity.tarih);
      if (date != null) {
        previousDates.add(
          DateFormat('yyyy-MM-dd')
              .format(DateTime(date.year, date.month, date.day - 1)),
        );
      }
    }
    if (previousDates.isEmpty || personnelById.isEmpty) return rows;
    final sourceActivities = await (db.select(
      db.gunlukFaaliyetTable,
    )..where((t) => t.tarih.isIn(previousDates)))
        .get();
    if (sourceActivities.isEmpty) return rows;
    final sourceDates = {for (final a in sourceActivities) a.id: a.tarih};
    final assignments = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where(
            (t) =>
                t.faaliyetId.isIn(sourceDates.keys) &
                t.personelId.isIn(personnelById.keys) &
                t.durum.equals(AssignmentStatus.onaylandi),
          ))
        .get();
    final seenIds =
        rows.map((r) => r.sourceAssignmentId).whereType<int>().toSet();
    final selectedActivityIds = activities.map((a) => a.id).toSet();
    final eligible = assignments.where((a) {
      final code = MilitaryStructureHelper.getRosterGroupCode(a.gorevVeyaIzin);
      return (code == 'HAZIR_KITA' || code == 'NOBET_HEYETI') &&
          !selectedActivityIds.contains(a.faaliyetId) &&
          !seenIds.contains(a.id);
    });
    final result = [...rows];
    // Keep each source day in a stable block, below all original rows.
    final dates = previousDates.toList()..sort();
    for (final date in dates) {
      final ordered = orderAssignmentsForExport(
        eligible.where((a) => sourceDates[a.faaliyetId] == date),
        personnelById,
        squadNames,
      );
      for (final assignment in ordered) {
        final person = personnelById[assignment.personelId]!;
        result.add(
          MilitaryRosterRow(
            sNu: result.length + 1,
            birligi: 'J.Komd.Öz.Hrk.Tb.Klığı',
            rutbe: person.rutbe,
            adSoyad: person.adSoyad,
            diger: '',
            groupCode: MilitaryStructureHelper.getRosterGroupCode(
              assignment.gorevVeyaIzin,
            ),
            sourceAssignmentId: assignment.id,
            sourceDate: date,
          ),
        );
      }
    }
    return result;
  }
}

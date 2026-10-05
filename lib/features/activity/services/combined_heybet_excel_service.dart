import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

/// One-off, read-only data for the separate combined Excel action.
/// Normal exports, assignments, archive and duty coverage never use this service.
class CombinedHeybetExcelService {
  const CombinedHeybetExcelService(this.db);
  final AppDatabase db;

  static bool isHeybet(String name) =>
      RegExp(r'(^|\s)HEYBET(\s|$)').hasMatch(name.toUpperCase().trim());

  Future<List<GunlukFaaliyetTableData>> listPreviousActivities(
    GunlukFaaliyetTableData activity,
  ) async {
    final date = DateTime.tryParse(activity.tarih);
    if (date == null) return [];
    final previousDate = DateFormat('yyyy-MM-dd')
        .format(DateTime(date.year, date.month, date.day - 1));
    return (db.select(db.gunlukFaaliyetTable)
          ..where((t) => t.tarih.equals(previousDate))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
  }

  Future<List<MilitaryRosterRow>> build({
    required GunlukFaaliyetTableData activity,
    required Set<int> selectedPreviousActivityIds,
    required List<MilitaryRosterRow> currentRows,
    required Map<int, PersonelTableData> personnelById,
    required Map<int, String> squadNames,
  }) async {
    if (!isHeybet(activity.faaliyetAdi)) {
      throw ArgumentError('Birleşik Excel yalnızca Heybet için oluşturulur.');
    }
    // Copy presentation rows; never modify the normal list passed by the caller.
    final result = [
      for (final row in currentRows)
        MilitaryRosterRow(
          sNu: row.sNu,
          birligi: 'J.Komd.Öz.Hrk.Tb.Klığı',
          rutbe: row.rutbe,
          adSoyad: row.adSoyad,
          diger: '',
          groupCode: row.groupCode,
        ),
    ];
    if (selectedPreviousActivityIds.isEmpty || personnelById.isEmpty) {
      return result;
    }
    final previousActivities = (await listPreviousActivities(activity))
        .where((a) => selectedPreviousActivityIds.contains(a.id))
        .toList();
    if (previousActivities.isEmpty) return result;
    // Source assignments are read into a separate local collection only.
    final previousAssignments = await (db.select(db.faaliyetPersonelAtamaTable)
          ..where((t) =>
              t.faaliyetId.isIn(previousActivities.map((a) => a.id)) &
              t.personelId.isIn(personnelById.keys) &
              t.durum.equals(AssignmentStatus.onaylandi)))
        .get();
    final ordered = orderAssignmentsForExport(
      previousAssignments
          .where((a) => DutyOrLeaveType.isOperationalDuty(a.gorevVeyaIzin)),
      personnelById,
      squadNames,
    );
    for (final assignment in ordered) {
      final person = personnelById[assignment.personelId]!;
      result.add(MilitaryRosterRow(
        sNu: result.length + 1,
        birligi: 'J.Komd.Öz.Hrk.Tb.Klığı',
        rutbe: person.rutbe,
        adSoyad: person.adSoyad,
        diger: '',
        groupCode: MilitaryStructureHelper.getRosterGroupCode(
            assignment.gorevVeyaIzin),
      ));
    }
    return result;
  }
}

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

/// Read-only presentation data; does not create assignments or duty marks.
class CombinedHeybetExcelService {
  const CombinedHeybetExcelService(this.db);
  final AppDatabase db;

  static bool isHeybet(String name) =>
      RegExp(r'(^|\s)HEYBET(\s|$)').hasMatch(name.toUpperCase().trim());

  Future<List<GunlukFaaliyetTableData>> listCurrentActivities(
    GunlukFaaliyetTableData activity,
  ) =>
      _activitiesOn(activity.tarih, excludingId: activity.id);

  Future<List<GunlukFaaliyetTableData>> listPreviousActivities(
    GunlukFaaliyetTableData activity,
  ) async {
    final date = DateTime.tryParse(activity.tarih);
    if (date == null) return [];
    return _activitiesOn(
      DateFormat('yyyy-MM-dd')
          .format(DateTime(date.year, date.month, date.day - 1)),
    );
  }

  Future<List<GunlukFaaliyetTableData>> _activitiesOn(
    String date, {
    int? excludingId,
  }) async =>
      (db.select(db.gunlukFaaliyetTable)
            ..where(
              (t) =>
                  t.tarih.equals(date) &
                  (excludingId == null
                      ? const Constant(true)
                      : t.id.isNotValue(excludingId)),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<List<MilitaryRosterRow>> build({
    required GunlukFaaliyetTableData activity,
    required Set<int> selectedPreviousActivityIds,
    Set<int> selectedCurrentActivityIds = const {},
    required List<MilitaryRosterRow> currentRows,
    required Map<int, PersonelTableData> personnelById,
    required Map<int, String> squadNames,
    int? authorizedTeamId,
    int? selectedSquadId,
  }) async {
    if (!isHeybet(activity.faaliyetAdi)) {
      throw ArgumentError('Birleşik çıktı yalnızca Heybet için oluşturulur.');
    }
    final anchor = await (db.select(
      db.gunlukFaaliyetTable,
    )..where((t) => t.id.equals(activity.id)))
        .getSingleOrNull();
    if (anchor == null ||
        anchor.tarih != activity.tarih ||
        !isHeybet(anchor.faaliyetAdi)) {
      throw StateError(
        'Ana faaliyet değişti veya silindi. Listeyi yeniden açın.',
      );
    }
    final result = <MilitaryRosterRow>[];
    final seenPersonnel = <int>{};
    void append(MilitaryRosterRow row) {
      final id = row.personelId;
      if (id != null && !seenPersonnel.add(id)) return;
      result.add(
        MilitaryRosterRow(
          sNu: result.length + 1,
          personelId: id,
          birligi: 'J.Komd.Öz.Hrk.Tb.Klığı',
          rutbe: row.rutbe,
          adSoyad: row.adSoyad,
          diger: '',
          groupCode: row.groupCode,
        ),
      );
    }

    for (final row in currentRows) {
      append(row);
    }
    if (personnelById.isEmpty) return result;

    Future<void> appendActivities(
      List<GunlukFaaliyetTableData> available,
      Set<int> selected,
    ) async {
      final ids = available
          .where((a) => selected.contains(a.id))
          .map((a) => a.id)
          .toSet();
      if (ids.isEmpty) return;
      final assignments = await (db.select(db.faaliyetPersonelAtamaTable)
            ..where(
              (t) =>
                  t.faaliyetId.isIn(ids) &
                  t.personelId.isIn(personnelById.keys),
            ))
          .get();
      final ordered = orderAssignmentsForExport(
        assignments.where(
          (a) =>
              DutyOrLeaveType.isApprovedOperationalDuty(
                a.gorevVeyaIzin,
                a.durum,
              ) &&
              (authorizedTeamId == null || a.gorevTimId == authorizedTeamId) &&
              (selectedSquadId == null || a.gorevTimId == selectedSquadId),
        ),
        personnelById,
        squadNames,
      );
      for (final a in ordered) {
        final person = personnelById[a.personelId]!;
        append(
          MilitaryRosterRow(
            sNu: 0,
            personelId: person.id,
            birligi: '',
            rutbe: person.rutbe,
            adSoyad: person.adSoyad,
            diger: '',
            groupCode: MilitaryStructureHelper.getRosterGroupCode(
              a.gorevVeyaIzin,
            ),
          ),
        );
      }
    }

    await appendActivities(
      await listCurrentActivities(anchor),
      selectedCurrentActivityIds,
    );
    await appendActivities(
      await listPreviousActivities(anchor),
      selectedPreviousActivityIds,
    );
    return result;
  }
}

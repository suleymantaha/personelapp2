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

  Future<List<GunlukFaaliyetTableData>> listActivitiesForDate(
    String date, {
    int? authorizedTeamId,
    int? selectedSquadId,
  }) async {
    DateFormat('yyyy-MM-dd').parseStrict(date);
    final cards = await _activitiesOn(date);
    if (authorizedTeamId == null && selectedSquadId == null) return cards;
    final assignments =
        await (db.select(db.faaliyetPersonelAtamaTable)..where(
              (a) =>
                  a.faaliyetId.isIn(cards.map((c) => c.id)) &
                  (authorizedTeamId == null
                      ? const Constant(true)
                      : a.gorevTimId.equals(authorizedTeamId)) &
                  (selectedSquadId == null
                      ? const Constant(true)
                      : a.gorevTimId.equals(selectedSquadId)),
            ))
            .get();
    final visibleIds = assignments.map((a) => a.faaliyetId).toSet();
    return cards.where((c) => visibleIds.contains(c.id)).toList();
  }

  /// Exports only explicitly selected cards. Day groups are stable, and each
  /// card keeps its own official personnel order instead of a global sort.
  Future<List<MilitaryRosterRow>> buildSelected({
    required String date,
    required List<GunlukFaaliyetTableData> sources,
    required Map<int, PersonelTableData> personnelById,
    required Map<int, String> squadNames,
    int? authorizedTeamId,
    int? selectedSquadId,
  }) async {
    final day = DateFormat('yyyy-MM-dd').parseStrict(date);
    final previous = DateFormat('yyyy-MM-dd')
        .format(DateTime(day.year, day.month, day.day - 1));
    if (sources.any((c) => c.tarih != date && c.tarih != previous)) {
      throw ArgumentError('Kartlar seçilen güne veya önceki güne ait olmalı.');
    }
    return db.transaction(() async {
      final fresh = await (db.select(
        db.gunlukFaaliyetTable,
      )..where((a) => a.id.isIn(sources.map((c) => c.id)))).get();
      for (final source in sources) {
        if (!fresh.any(
          (c) =>
              c.id == source.id &&
              c.tarih == source.tarih &&
              c.faaliyetAdi == source.faaliyetAdi,
        )) {
          throw StateError(
            'Seçilen kart değişti veya silindi. Önizlemeyi yeniden açın.',
          );
        }
      }
      final ordered = [
        ...sources.where((c) => c.tarih == date),
        ...sources.where((c) => c.tarih == previous),
      ];
      final sourceRows = await _rowsForSources(
        ordered,
        personnelById,
        squadNames,
        authorizedTeamId: authorizedTeamId,
        selectedSquadId: selectedSquadId,
      );
      final seen = <int?>{};
      final rows = <MilitaryRosterRow>[];
      for (final row in sourceRows) {
        if (!seen.add(row.personelId)) continue;
        rows.add(
          MilitaryRosterRow(
            sNu: rows.length + 1,
            personelId: row.personelId,
            birligi: 'J.Komd.Öz.Hrk.Tb.Klığı',
            rutbe: row.rutbe,
            adSoyad: row.adSoyad,
            diger: '',
            groupCode: row.groupCode,
          ),
        );
      }
      return rows;
    });
  }

  Future<List<MilitaryRosterRow>> _rowsForSources(
    List<GunlukFaaliyetTableData> sources,
    Map<int, PersonelTableData> people,
    Map<int, String> squadNames, {
    int? authorizedTeamId,
    int? selectedSquadId,
  }) async {
    if (sources.isEmpty || people.isEmpty) return [];
    final assignments =
        await (db.select(db.faaliyetPersonelAtamaTable)..where(
              (a) =>
                  a.faaliyetId.isIn(sources.map((c) => c.id)) &
                  a.personelId.isIn(people.keys),
            ))
            .get();
    final approved = assignments.where(
      (a) =>
          DutyOrLeaveType.isApprovedOperationalDuty(a.gorevVeyaIzin, a.durum) &&
          (authorizedTeamId == null || a.gorevTimId == authorizedTeamId) &&
          (selectedSquadId == null || a.gorevTimId == selectedSquadId),
    );
    final byCard = <int, List<FaaliyetPersonelAtamaTableData>>{};
    for (final assignment in approved) {
      byCard.putIfAbsent(assignment.faaliyetId, () => []).add(assignment);
    }
    return [
      for (final source in sources)
        for (final assignment in orderAssignmentsForExport(
          byCard[source.id] ?? [],
          people,
          squadNames,
        ))
          MilitaryRosterRow(
            sNu: 0,
            personelId: assignment.personelId,
            birligi: '',
            rutbe: people[assignment.personelId]!.rutbe,
            adSoyad: people[assignment.personelId]!.adSoyad,
            diger: '',
            groupCode: MilitaryStructureHelper.getRosterGroupCode(
              assignment.gorevVeyaIzin,
            ),
          ),
    ];
  }

  Future<List<GunlukFaaliyetTableData>> listCurrentActivities(
    GunlukFaaliyetTableData activity,
  ) => _activitiesOn(activity.tarih, excludingId: activity.id);

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
    )..where((t) => t.id.equals(activity.id))).getSingleOrNull();
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
      final byId = {for (final card in available) card.id: card};
      final ordered = [
        for (final id in selected)
          if (byId.containsKey(id)) byId[id]!,
      ];
      final sourceRows = await _rowsForSources(
        ordered,
        personnelById,
        squadNames,
        authorizedTeamId: authorizedTeamId,
        selectedSquadId: selectedSquadId,
      );
      for (final row in sourceRows) {
        append(row);
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

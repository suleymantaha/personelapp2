import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/duty_abbreviation_mapper.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:personelapp2/features/matrix/domain/team_duty_analytics_dto.dart';

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
    ])..where(
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
      final entriesByPersonAndDay = <int, Map<int, List<MatrixDayEntry>>>{};
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
          personDays
              .putIfAbsent(day, () => [])
              .add(
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

  /// Belirli bir timin ilgili yıldaki ve aydaki takvim ve analitik verisini hesaplar.
  Future<TeamMonthlyCalendarDto> getTeamMonthlyCalendar({
    required int timId,
    required String timAdi,
    required int year,
    required int month,
  }) async {
    final yearMonth = '$year-${month.toString().padLeft(2, '0')}';
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final monthStart = DateTime(year, month, 1);
    final nextMonth = DateTime(year, month + 1);
    final people =
        await (db.select(db.personelTable)
          ..where((p) => p.isDemo.equals(false))).get();
    final personnelById = {for (final p in people) p.id: p};
    final history =
        await (db.select(db.timUyelikGecmisiTable)
              ..where(
                (h) => h.tarih.isSmallerThanValue(
                  DateFormat('yyyy-MM-dd').format(nextMonth),
                ),
              )
              ..orderBy([
                (h) => OrderingTerm.desc(h.tarih),
                (h) => OrderingTerm.desc(h.id),
              ]))
            .get();
    final historyByPerson = <int, List<TimUyelikGecmisiTableData>>{};
    for (final entry in history) {
      historyByPerson.putIfAbsent(entry.personelId, () => []).add(entry);
    }
    final rows =
        await (db.select(db.faaliyetPersonelAtamaTable).join([
          innerJoin(
            db.gunlukFaaliyetTable,
            db.gunlukFaaliyetTable.id.equalsExp(
              db.faaliyetPersonelAtamaTable.faaliyetId,
            ),
          ),
        ])..where(
          db.gunlukFaaliyetTable.tarih.isBiggerOrEqualValue(
                DateFormat(
                  'yyyy-MM-dd',
                ).format(monthStart.subtract(const Duration(days: 1))),
              ) &
              db.gunlukFaaliyetTable.tarih.isSmallerThanValue(
                DateFormat('yyyy-MM-dd').format(nextMonth),
              ),
        )).get();
    final groupedByDay = <int, Map<({String duty, String status}), Set<int>>>{};
    final continuingByDay =
        <int, Map<({String duty, String status}), Set<int>>>{};
    var unknownTeamCount = 0;
    for (final row in rows) {
      final assignment = row.readTable(db.faaliyetPersonelAtamaTable);
      if (assignment.durum == AssignmentStatus.reddedildi ||
          !personnelById.containsKey(assignment.personelId)) {
        continue;
      }
      final activity = row.readTable(db.gunlukFaaliyetTable);
      final dates = DutyCoverage.coveredDates(
        startDate: activity.tarih,
        duty: assignment.gorevVeyaIzin,
      );
      if (assignment.gorevTimId == null &&
          assignment.gorevTimAdi == null &&
          dates.any((d) => d.startsWith(yearMonth))) {
        unknownTeamCount++;
      }
      if (assignment.gorevTimId != timId) continue;
      for (final date in dates.where((d) => d.startsWith(yearMonth))) {
        final day = int.parse(date.substring(8, 10));
        final key = (
          duty: assignment.gorevVeyaIzin.trim().toUpperCase(),
          status: assignment.durum,
        );
        groupedByDay
            .putIfAbsent(day, () => {})
            .putIfAbsent(key, () => {})
            .add(assignment.personelId);
        if (date != activity.tarih) {
          continuingByDay
              .putIfAbsent(day, () => {})
              .putIfAbsent(key, () => {})
              .add(assignment.personelId);
        }
      }
    }
    final calendarDays = <TeamDayDutyDto>[];
    final distribution = <String, int>{};
    var operationalDays = 0;
    var personnelDutyDays = 0;
    var availablePersonnelDays = 0;
    var rosterHistoryKnown = unknownTeamCount == 0;
    for (var day = 1; day <= daysInMonth; day++) {
      final date = '$yearMonth-${day.toString().padLeft(2, '0')}';
      final groups = <TeamDutyGroupDto>[];
      final allIds = <int>{};
      final operationalIds = <int>{};
      final dutyTypes = <String>{};
      final availableIds = <int>{};
      for (final person in people) {
        final events =
            historyByPerson[person.id] ?? const <TimUyelikGecmisiTableData>[];
        final last =
            events
                .where((h) => h.tarih.split('T').first.compareTo(date) <= 0)
                .firstOrNull;
        if (last != null) {
          if (last.islem == 'eklendi' && last.timId == timId) {
            availableIds.add(person.id);
          }
        } else if (person.timId == timId &&
            person.kayitTarihi.split('T').first.compareTo(date) <= 0) {
          rosterHistoryKnown = false;
        }
      }
      for (final entry in (groupedByDay[day] ?? {}).entries) {
        final ids =
            entry.value.toList()..sort((a, b) {
              final byName = personnelById[a]!.adSoyad.compareTo(
                personnelById[b]!.adSoyad,
              );
              return byName == 0 ? a.compareTo(b) : byName;
            });
        allIds.addAll(ids);
        if (DutyOrLeaveType.isApprovedOperationalDuty(
          entry.key.duty,
          entry.key.status,
        )) {
          operationalIds.addAll(ids);
          dutyTypes.add(entry.key.duty);
        }
        groups.add(
          TeamDutyGroupDto(
            gorev: entry.key.duty,
            durum: entry.key.status,
            personelIds: ids,
            personelAdlari:
                ids.map((id) => personnelById[id]!.adSoyad).toList(),
            devamEdenPersonelIds:
                (continuingByDay[day]?[entry.key] ?? {}).toList(),
          ),
        );
      }
      groups.sort(
        (a, b) => '${a.gorev}|${a.durum}'.compareTo('${b.gorev}|${b.durum}'),
      );
      availableIds.addAll(operationalIds);
      availablePersonnelDays += availableIds.length;
      personnelDutyDays += operationalIds.length;
      if (operationalIds.isNotEmpty) operationalDays++;
      for (final duty in dutyTypes) {
        distribution[duty] = (distribution[duty] ?? 0) + 1;
      }
      calendarDays.add(
        TeamDayDutyDto(
          tarih: date,
          gunIndex: day,
          gorevKodu:
              groups.isEmpty
                  ? ''
                  : groups.length == 1
                  ? DutyAbbreviationMapper.getAbbreviation(groups.single.gorev)
                  : '${groups.length} grup',
          gorevTamAdi:
              groups.isEmpty
                  ? 'Boş / Serbest'
                  : groups.length == 1
                  ? groups.single.gorev
                  : '${groups.length} görev / durum',
          gorevliPersonelAdlari:
              allIds.map((id) => personnelById[id]!.adSoyad).toList(),
          gorevGruplari: groups,
          isYogunGorev:
              availableIds.isNotEmpty &&
              operationalIds.length / availableIds.length >= 0.7,
        ),
      );
    }
    return TeamMonthlyCalendarDto(
      timId: timId,
      timAdi: timAdi,
      yil: year,
      ay: month,
      gunler: calendarDays,
      ozet: TeamDutySummaryDto(
        timId: timId,
        timAdi: timAdi,
        toplamGorevGunSayisi: operationalDays,
        toplamGorevSaati:
            0, // Gün kapsaması süre değildir; gerçek saat hesabı henüz yok.
        aktifPersonelSayisi:
            people.where((p) => p.aktif && p.timId == timId).length,
        ortalamaYukYuzdesi:
            rosterHistoryKnown && availablePersonnelDays > 0
                ? 100 * personnelDutyDays / availablePersonnelDays
                : 0,
        gorevTuruDagilimi: distribution,
        toplamPersonelGorevGunu: personnelDutyDays,
        bilinmeyenTimAtamaSayisi: unknownTeamCount,
        yukHesabiTam: rosterHistoryKnown,
      ),
    );
  }
}

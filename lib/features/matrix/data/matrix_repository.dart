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

  /// Belirli bir timin ilgili yıldaki ve aydaki takvim ve analitik verisini hesaplar.
  Future<TeamMonthlyCalendarDto> getTeamMonthlyCalendar({
    required int timId,
    required String timAdi,
    required int year,
    required int month,
  }) async {
    final yearMonthStr =
        '$year-${month.toString().padLeft(2, '0')}';
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Tim personelini getir
    final teamPersonnels = await (db.select(db.personelTable)
          ..where((tbl) => tbl.timId.equals(timId)))
        .get();

    final teamPersonnelIds = teamPersonnels.map((p) => p.id).toSet();
    final personnelMap = {for (var p in teamPersonnels) p.id: p.adSoyad};

    // Aylık atamaları getir
    final monthStart = DateTime(year, month, 1);
    final monthEnd = DateTime(year, month + 1, 0);

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
              DateFormat('yyyy-MM-dd')
                  .format(monthStart.subtract(const Duration(days: 1))),
            ) &
            db.gunlukFaaliyetTable.tarih.isSmallerThanValue(
              DateFormat('yyyy-MM-dd')
                  .format(monthEnd.add(const Duration(days: 1))),
            ),
      );

    final rows = await query.get();

    final Map<int, List<TeamDayDutyDto>> dayDutiesMap = {};
    final Map<String, int> gorevTuruCounts = {};
    int totalGorevDays = 0;

    for (var day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$yearMonthStr-${day.toString().padLeft(2, '0')}';
      final List<String> activePersonnel = [];
      String mainDutyName = '';

      for (final row in rows) {
        final assignment = row.readTable(db.faaliyetPersonelAtamaTable);
        if (assignment.durum == AssignmentStatus.reddedildi) continue;
        if (!teamPersonnelIds.contains(assignment.personelId)) continue;

        final activity = row.readTable(db.gunlukFaaliyetTable);
        final coveredDates = DutyCoverage.coveredDates(
          startDate: activity.tarih,
          duty: assignment.gorevVeyaIzin,
        );

        if (coveredDates.contains(dateStr)) {
          final pName = personnelMap[assignment.personelId] ?? 'Personel #${assignment.personelId}';
          if (!activePersonnel.contains(pName)) {
            activePersonnel.add(pName);
          }
          if (mainDutyName.isEmpty) {
            mainDutyName = assignment.gorevVeyaIzin;
          }
        }
      }

      if (activePersonnel.isNotEmpty) {
        totalGorevDays++;
        final abbrev = DutyAbbreviationMapper.getAbbreviation(mainDutyName);
        gorevTuruCounts[mainDutyName] =
            (gorevTuruCounts[mainDutyName] ?? 0) + 1;

        final dto = TeamDayDutyDto(
          tarih: dateStr,
          gunIndex: day,
          gorevKodu: abbrev,
          gorevTamAdi: mainDutyName,
          gorevliPersonelAdlari: activePersonnel,
          isYogunGorev: activePersonnel.length >= (teamPersonnelIds.length * 0.7),
        );
        dayDutiesMap.putIfAbsent(day, () => []).add(dto);
      }
    }

    final List<TeamDayDutyDto> calendarDays = [];
    for (var d = 1; d <= daysInMonth; d++) {
      if (dayDutiesMap.containsKey(d) && dayDutiesMap[d]!.isNotEmpty) {
        calendarDays.add(dayDutiesMap[d]!.first);
      } else {
        calendarDays.add(TeamDayDutyDto(
          tarih: '$yearMonthStr-${d.toString().padLeft(2, '0')}',
          gunIndex: d,
          gorevKodu: '',
          gorevTamAdi: 'Boş / Serbest',
          gorevliPersonelAdlari: const [],
        ));
      }
    }

    final summary = TeamDutySummaryDto(
      timId: timId,
      timAdi: timAdi,
      toplamGorevGunSayisi: totalGorevDays,
      toplamGorevSaati: totalGorevDays * 24.0,
      aktifPersonelSayisi: teamPersonnelIds.length,
      ortalamaYukYuzdesi: (totalGorevDays / daysInMonth) * 100,
      gorevTuruDagilimi: gorevTuruCounts,
    );

    return TeamMonthlyCalendarDto(
      timId: timId,
      timAdi: timAdi,
      yil: year,
      ay: month,
      gunler: calendarDays,
      ozet: summary,
    );
  }
}

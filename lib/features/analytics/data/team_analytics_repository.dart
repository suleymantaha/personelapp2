import 'package:drift/drift.dart';
import 'package:personelapp2/core/auth/domain/user_session.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import '../domain/team_analytics.dart';
import '../domain/monthly_analytics_rows.dart';
import '../domain/analytics_duty_resolver.dart';

/// Reads existing assignment snapshots. Never repairs or backfills source data.
class TeamAnalyticsRepository {
  TeamAnalyticsRepository(this.db);
  final AppDatabase db;

  Future<TeamAnalytics> load(
      AnalyticsFilter filter, UserSessionState? actor) async {
    if (actor == null) return TeamAnalytics(filter: filter, entries: const []);
    return db.transaction(() async {
      final scope = actor.isAdmin
          ? null
          : await PersonnelRepository(db).currentCommanderTeam(actor.username);
      if (!actor.isAdmin && scope == null) {
        return TeamAnalytics(filter: filter, entries: const []);
      }
      final teams = await (db.select(db.timTable)
            ..where((t) =>
                scope == null ? const Constant(true) : t.id.equals(scope)))
          .get();
      final names = {for (final t in teams) t.id: t.timAdi};
      final rows = await _rows(filter);
      final personnel = db.personelTable;
      final nameRows = await (db.selectOnly(personnel)
            ..addColumns([personnel.adSoyad])
            ..where(personnel.isDemo.equals(false)))
          .get();
      final dutyResolver = AnalyticsDutyResolver(
          nameRows.map((r) => r.read(personnel.adSoyad)).whereType<String>());
      final headcount = await _currentHeadcount(scope, filter.teamId);
      return _aggregate(rows, filter, names, scope, actor.isAdmin,
          headcount: headcount,
          headcountAsOf: DateTime.now(),
          dutyResolver: dutyResolver);
    });
  }

  Future<int> _currentHeadcount(int? scope, int? selectedTeam) async {
    final personnel = db.personelTable;
    final count = personnel.id.count();
    final query = db.selectOnly(personnel)..addColumns([count]);
    query.where(personnel.aktif.equals(true) & personnel.isDemo.equals(false));
    if (scope != null) query.where(personnel.timId.equals(scope));
    if (selectedTeam != null) query.where(personnel.timId.equals(selectedTeam));
    return (await query.getSingle()).read(count) ?? 0;
  }

  Future<List<TypedResult>> _rows(AnalyticsFilter filter) {
    final previous = analyticsDate(filter.start)
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);
    return (db.select(db.faaliyetPersonelAtamaTable).join([
      innerJoin(
          db.gunlukFaaliyetTable,
          db.gunlukFaaliyetTable.id
              .equalsExp(db.faaliyetPersonelAtamaTable.faaliyetId)),
      innerJoin(
          db.personelTable,
          db.personelTable.id
              .equalsExp(db.faaliyetPersonelAtamaTable.personelId)),
    ])
          ..where(db.gunlukFaaliyetTable.tarih
                  .isBetweenValues(previous, filter.end) &
              db.personelTable.isDemo.equals(false) &
              db.faaliyetPersonelAtamaTable.durum.equals(filter.status)))
        .get();
  }

  TeamAnalytics _aggregate(List<TypedResult> rows, AnalyticsFilter filter,
      Map<int, String> names, int? scope, bool isAdmin,
      {required int headcount,
      required DateTime headcountAsOf,
      required AnalyticsDutyResolver dutyResolver}) {
    final entries = <AnalyticsEntry>[];
    final unknown = <AnalyticsEntry>[];
    final availableDuties = <String>{};
    final seen = <(int, int, int?, String, String)>{};
    final activities = <(String, String), Set<int>>{};
    var duplicates = 0;
    for (final row in rows) {
      final a = row.readTable(db.faaliyetPersonelAtamaTable);
      final f = row.readTable(db.gunlukFaaliyetTable);
      final p = row.readTable(db.personelTable);
      final duty = dutyResolver.resolve(
          duty: a.gorevVeyaIzin, activityName: f.faaliyetAdi);
      if (!DutyOrLeaveType.isOperationalDuty(duty)) continue;
      if (scope != null && a.gorevTimId != scope) continue;
      if (filter.teamId != null && a.gorevTimId != filter.teamId) continue;
      final dates = DutyCoverage.coveredDates(startDate: f.tarih, duty: duty)
          .where((d) =>
              d.compareTo(filter.start) >= 0 && d.compareTo(filter.end) <= 0)
          .toList();
      if (dates.isEmpty) continue;
      availableDuties.add(duty);
      if (filter.duty != null && duty != analyticsDutyLabel(filter.duty!)) {
        continue;
      }
      if (!seen.add((f.id, p.id, a.gorevTimId, duty, a.durum))) {
        duplicates++;
        continue;
      }
      final entry = AnalyticsEntry(
          activityId: f.id,
          activityName: f.faaliyetAdi,
          sourceDate: f.tarih,
          personnelId: p.id,
          personnelName: p.adSoyad,
          teamId: a.gorevTimId,
          teamName: names[a.gorevTimId] ?? a.gorevTimAdi ?? 'Timi bilinmiyor',
          duty: duty,
          status: a.durum,
          coveredDates: dates);
      if (a.gorevTimId == null) {
        if (isAdmin && a.gorevTimAdi != 'Tim dışı') unknown.add(entry);
        continue;
      }
      names.putIfAbsent(a.gorevTimId!, () => entry.teamName);
      entries.add(entry);
      activities.putIfAbsent(
          (f.tarih, f.faaliyetAdi.trim().toUpperCase()), () => {}).add(f.id);
    }
    entries.sort(_compare);
    unknown.sort(_compare);
    return TeamAnalytics(
        filter: filter,
        entries: entries,
        unknownEntries: unknown,
        teams: names,
        currentHeadcount: headcount,
        headcountAsOf: headcountAsOf,
        availableDuties: availableDuties,
        duplicateAssignments: duplicates,
        possibleDuplicateActivities:
            activities.values.fold(0, (n, ids) => n + ids.length - 1));
  }

  int _compare(AnalyticsEntry a, AnalyticsEntry b) {
    final date = b.sourceDate.compareTo(a.sourceDate);
    if (date != 0) return date;
    final activity = a.activityId.compareTo(b.activityId);
    return activity != 0 ? activity : a.personnelId.compareTo(b.personnelId);
  }
}

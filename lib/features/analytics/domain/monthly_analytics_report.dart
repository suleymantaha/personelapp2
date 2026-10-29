import 'monthly_analytics_rows.dart';
import 'team_analytics.dart';
export 'monthly_analytics_rows.dart';

/// Immutable source-date report shared by UI and XLSX. Covered days deliberately
/// do not turn a single assignment into multiple new assignments.
class MonthlyAnalyticsReport {
  factory MonthlyAnalyticsReport(
      {required TeamAnalytics data, required DateTime asOf}) {
    final rows = _selectedRows(data);
    final byDate = <String, List<AnalyticsEntry>>{};
    for (final row in rows) {
      byDate.putIfAbsent(row.sourceDate, () => []).add(row);
    }
    final today = DateTime(asOf.year, asOf.month, asOf.day);
    final start = analyticsDate(data.filter.start);
    final end = analyticsDate(data.filter.end);
    final days = <MonthlyAnalyticsDay>[];
    // Calendar iteration, rather than Duration(days: 1), is safe across DST.
    for (var date = start;
        !date.isAfter(end);
        date = DateTime(date.year, date.month, date.day + 1)) {
      final label = date.toIso8601String().substring(0, 10);
      final entries = byDate[label] ?? const <AnalyticsEntry>[];
      days.add(MonthlyAnalyticsDay(
          date: label,
          assignments: entries.length,
          uniquePersonnel:
              entries.map((entry) => entry.personnelId).toSet().length,
          isPlanned: date.isAfter(today),
          duties: _duties(entries),
          teams: _teams(data, entries)));
    }
    return MonthlyAnalyticsReport._(data, asOf, rows, days);
  }

  MonthlyAnalyticsReport._(TeamAnalytics data, this.asOf,
      List<AnalyticsEntry> rows, List<MonthlyAnalyticsDay> daily)
      : start = data.filter.start,
        end = data.filter.end,
        teamLabel = data.filter.teamId == null
            ? 'Tüm timler'
            : data.teams[data.filter.teamId] ?? 'Tim #${data.filter.teamId}',
        dutyLabel = data.filter.duty == null
            ? 'Tüm görevler'
            : analyticsDutyLabel(data.filter.duty!),
        status = data.filter.status,
        currentHeadcount = data.currentHeadcount,
        headcountAsOf = data.headcountAsOf,
        assignmentCount = rows.length,
        uniquePersonnel = rows.map((r) => r.personnelId).toSet().length,
        knownTeamAssignments = rows.where((r) => r.teamId != null).length,
        unknownTeamAssignments = rows.where((r) => r.teamId == null).length,
        unclassifiedAssignments = rows
            .where(
                (r) => !isClassifiedAnalyticsDuty(analyticsDutyLabel(r.duty)))
            .length,
        days = List.unmodifiable(daily),
        duties = List.unmodifiable(_duties(rows)),
        teams = List.unmodifiable(_teams(data, rows, includeEmpty: true));

  final String start, end, teamLabel, dutyLabel, status;
  final DateTime asOf;
  final int? currentHeadcount;
  final DateTime? headcountAsOf;
  final int assignmentCount,
      uniquePersonnel,
      knownTeamAssignments,
      unknownTeamAssignments,
      unclassifiedAssignments;
  final List<MonthlyAnalyticsDay> days;
  final List<MonthlyDutyCount> duties;
  final List<MonthlyTeamRow> teams;
  int get recordedDays => days.where((day) => day.assignments > 0).length;
  int get totalDays => days.length;
  double get teamCoverage =>
      assignmentCount == 0 ? 0 : knownTeamAssignments / assignmentCount;
}

List<AnalyticsEntry> _selectedRows(TeamAnalytics data) {
  final filter = data.filter;
  final seen = <(int, int, int?, String)>{};
  return [...data.entries, ...data.unknownEntries].where((row) {
    if (row.sourceDate.compareTo(filter.start) < 0 ||
        row.sourceDate.compareTo(filter.end) > 0 ||
        row.status != filter.status) {
      return false;
    }
    if (filter.teamId != null && row.teamId != filter.teamId) return false;
    final duty = analyticsDutyLabel(row.duty);
    if (filter.duty != null && duty != analyticsDutyLabel(filter.duty!)) {
      return false;
    }
    return seen.add((row.activityId, row.personnelId, row.teamId, duty));
  }).toList(growable: false);
}

List<MonthlyDutyCount> _duties(Iterable<AnalyticsEntry> rows) {
  final counts = <String, int>{};
  for (final row in rows) {
    counts.update(analyticsDutyLabel(row.duty), (n) => n + 1,
        ifAbsent: () => 1);
  }
  final result =
      counts.entries.map((e) => MonthlyDutyCount(e.key, e.value)).toList();
  result.sort((a, b) {
    final count = b.count.compareTo(a.count);
    return count == 0 ? a.duty.compareTo(b.duty) : count;
  });
  return result;
}

List<MonthlyTeamRow> _teams(TeamAnalytics data, Iterable<AnalyticsEntry> rows,
    {bool includeEmpty = false}) {
  final counts = <int, Map<String, int>>{};
  final people = <int, Map<String, Set<int>>>{};
  if (includeEmpty) {
    for (final id in data.teams.keys) {
      if (data.filter.teamId == null || data.filter.teamId == id) {
        counts[id] = {};
      }
    }
  }
  for (final row in rows) {
    final id = row.teamId;
    if (id == null) continue;
    counts
        .putIfAbsent(id, () => {})
        .update(analyticsDutyLabel(row.duty), (n) => n + 1, ifAbsent: () => 1);
    people
        .putIfAbsent(id, () => {})
        .putIfAbsent(analyticsDutyLabel(row.duty), () => {})
        .add(row.personnelId);
  }
  return [
    for (final id in data.sortTeamIds(counts.keys))
      MonthlyTeamRow(id, data.teams[id] ?? 'Tim #$id', counts[id]!,
          uniquePersonnel:
              (people[id]?.values.expand((ids) => ids).toSet() ?? {}).length,
          uniquePersonnelByDuty: {
            for (final duty in (people[id] ?? <String, Set<int>>{}).entries)
              duty.key: duty.value.length,
          })
  ];
}

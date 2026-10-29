import 'dart:convert';
import 'dart:io';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';
import 'package:personelapp2/features/analytics/domain/monthly_analytics_report.dart';
import 'package:personelapp2/features/analytics/domain/analytics_duty_resolver.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/services/monthly_analytics_excel_exporter.dart';

/// Read-only local reconciliation. No personnel names or IDs are printed.
/// Usage: `dart run tool/verify_monthly_analytics.dart backup.json output-dir`
void main(List<String> args) {
  if (args.length != 2) {
    throw ArgumentError('Expected backup path and output dir');
  }
  final backup = jsonDecode(File(args[0]).readAsStringSync()) as Map;
  if (backup['format'] != 'nizam-full-backup' || backup['version'] != 2) {
    throw FormatException('Expected full backup version 2');
  }
  final tables = (backup['payload'] as Map)['tables'] as Map;
  final activities = {
    for (final row in tables['activities'] as List) row['id'] as int: row as Map
  };
  final people = {
    for (final row in tables['personnel'] as List) row['id'] as int: row as Map
  };
  final teams = {
    for (final row in tables['squads'] as List)
      row['id'] as int: row['timAdi'] as String
  };
  final dutyResolver = AnalyticsDutyResolver(
      people.values.map((person) => person['adSoyad'] as String? ?? ''));
  final asOf = DateTime.parse(backup['exportedAt'] as String)
      .add(const Duration(hours: 3)); // Backup audit uses Europe/Istanbul.
  final assignments =
      (tables['assignments'] as List).cast<Map<String, dynamic>>();
  final months = activities.values
      .map((a) => (a['tarih'] as String).substring(0, 7))
      .toSet()
      .toList()
    ..sort();
  final summaries = <Map<String, Object>>[];
  final output = Directory(args[1])..createSync(recursive: true);
  for (final month in months) {
    final first = DateTime.parse('$month-01');
    final last = DateTime(first.year, first.month + 1, 0);
    final filter = AnalyticsFilter(
        start: '$month-01', end: last.toIso8601String().substring(0, 10));
    final known = <AnalyticsEntry>[];
    final unknown = <AnalyticsEntry>[];
    final expected = <String>{};
    final expectedPeople = <int>{};
    final expectedDates = <String>{};
    var expectedKnown = 0;
    for (final a in assignments) {
      final activity = activities[a['faaliyetId']];
      final person = people[a['personelId']];
      if (activity == null ||
          person == null ||
          person['isDemo'] == true ||
          a['durum'] != 'onaylandi') {
        continue;
      }
      if (a['gorevTimId'] == null && a['gorevTimAdi'] == 'Tim dışı') continue;
      final duty = dutyResolver.resolve(duty: a['gorevVeyaIzin'] as String,
          activityName: activity['faaliyetAdi'] as String? ?? '');
      if (!DutyOrLeaveType.isOperationalDuty(duty)) continue;
      final date = activity['tarih'] as String;
      final covered = DutyCoverage.coveredDates(startDate: date, duty: duty)
          .where((d) =>
              d.compareTo(filter.start) >= 0 && d.compareTo(filter.end) <= 0)
          .toList();
      if (covered.isEmpty) continue;
      final entry = AnalyticsEntry(
          activityId: activity['id'] as int,
          activityName: '',
          sourceDate: date,
          personnelId: a['personelId'] as int,
          personnelName: '',
          teamId: a['gorevTimId'] as int?,
          teamName: '',
          duty: duty,
          status: a['durum'] as String,
          coveredDates: covered);
      (entry.teamId == null ? unknown : known).add(entry);
      // Independent source-date oracle; deliberately ignores coverage expansion.
      if (!date.startsWith(month)) continue;
      final key =
          '${a['faaliyetId']}|${a['personelId']}|${a['gorevTimId']}|$duty';
      if (!expected.add(key)) continue;
      if (a['gorevTimId'] != null) expectedKnown++;
      expectedPeople.add(a['personelId'] as int);
      expectedDates.add(date);
    }
    final report = MonthlyAnalyticsReport(
        data: TeamAnalytics(
            filter: filter,
            currentHeadcount: people.values
                .where((p) => p['aktif'] == true && p['isDemo'] != true)
                .length,
            headcountAsOf: asOf,
            entries: known,
            unknownEntries: unknown,
            teams: teams),
        asOf: asOf);
    _check(report.assignmentCount == expected.length, '$month assignments');
    _check(report.uniquePersonnel == expectedPeople.length, '$month people');
    _check(report.recordedDays == expectedDates.length, '$month dates');
    _check(report.knownTeamAssignments == expectedKnown, '$month known teams');
    _check(
        report.days.fold<int>(0, (n, d) => n + d.assignments) ==
            report.assignmentCount,
        '$month daily sum');
    _check(
        report.duties.fold<int>(0, (n, d) => n + d.count) ==
            report.assignmentCount,
        '$month duty sum');
    _check(report.teams.fold<int>(0, (n, t) => n + t.total) == expectedKnown,
        '$month matrix sum');
    final bytes = MonthlyAnalyticsExcelExporter.generate(report);
    File('${output.path}/monthly_$month.xlsx').writeAsBytesSync(bytes);
    summaries.add({
      'currentHeadcount': report.currentHeadcount!,
      'month': month,
      'assignments': report.assignmentCount,
      'people': report.uniquePersonnel,
      'recordedDays': report.recordedDays,
      'knownTeamAssignments': expectedKnown,
      'unknownTeamAssignments': report.unknownTeamAssignments,
      'plannedAssignments': report.days
          .where((d) => d.isPlanned)
          .fold<int>(0, (n, d) => n + d.assignments),
      'unclassifiedAssignments': report.unclassifiedAssignments,
      'xlsxBytes': bytes.length
    });
  }
  final result = const JsonEncoder.withIndent('  ').convert(summaries);
  File('${output.path}/reconciliation.json').writeAsStringSync(result);
  stdout.writeln(result);
}

void _check(bool condition, String metric) {
  if (!condition) throw StateError('Reconciliation failed: $metric');
}

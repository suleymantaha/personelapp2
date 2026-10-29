import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/monthly_analytics_report.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';

AnalyticsEntry entry(int activity, int person, String date,
        {int? team = 1,
        String duty = 'HEYBET',
        String status = 'onaylandi',
        List<String>? covered}) =>
    AnalyticsEntry(
        activityId: activity,
        activityName: 'Test',
        sourceDate: date,
        personnelId: person,
        personnelName: 'Sentetik',
        teamId: team,
        teamName: team == null ? 'Bilinmiyor' : 'Tim $team',
        duty: duty,
        status: status,
        coveredDates: covered ?? [date]);

void main() {
  test('daily different people is a union across teams and unknown assignments',
      () {
    final result = MonthlyAnalyticsReport(
        data: TeamAnalytics(
            filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-01'),
            entries: [
              entry(1, 1, '2026-10-01'),
              entry(2, 1, '2026-10-01', team: 2)
            ],
            unknownEntries: [
              entry(3, 1, '2026-10-01', team: null)
            ]),
        asOf: DateTime(2026, 10, 29));
    expect(result.days.single.uniquePersonnel, 1);
    expect(result.days.single.assignments, 3);
  });
  test('headcount and team people remain distinct from repeated assignments',
      () {
    final result = MonthlyAnalyticsReport(
        data: TeamAnalytics(
            filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-31'),
            currentHeadcount: 10,
            headcountAsOf: DateTime(2026, 10, 29),
            teams: {
              1: '1. Tim'
            },
            entries: [
              entry(1, 1, '2026-10-01'),
              entry(2, 1, '2026-10-02'),
              entry(3, 1, '2026-10-03', duty: 'HAZIR KITA'),
            ]),
        asOf: DateTime(2026, 10, 29));
    expect(result.currentHeadcount, 10);
    expect(result.headcountAsOf, DateTime(2026, 10, 29));
    expect(result.uniquePersonnel, 1);
    expect(result.assignmentCount, 3);
    expect(result.teams.single.uniquePersonnel, 1);
    expect(result.teams.single.uniquePersonnelByDuty,
        {'HEYBET': 1, 'HAZIR KITA': 1});
    expect(result.teams.single.total, 3);
    expect(result.days.first.teams.single.uniquePersonnel, 1);
  });
  test('unavailable headcount is not an empty roster', () {
    final result = MonthlyAnalyticsReport(
        data: TeamAnalytics(
            filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-31'),
            entries: []),
        asOf: DateTime(2026, 10, 29));
    expect(result.currentHeadcount, isNull);
    expect(result.headcountAsOf, isNull);
  });
  final filter = AnalyticsFilter(start: '2026-10-01', end: '2026-10-31');
  MonthlyAnalyticsReport report(List<AnalyticsEntry> entries,
          {List<AnalyticsEntry> unknown = const []}) =>
      MonthlyAnalyticsReport(
          data: TeamAnalytics(
              filter: filter,
              entries: entries,
              unknownEntries: unknown,
              teams: {1: '1. Tim'}),
          asOf: DateTime(2026, 10, 28, 18));

  test('source-date assignments include unknown teams, dedup and retain people',
      () {
    final first = entry(1, 1, '2026-10-02');
    final result = report(
        [first, first, entry(1, 2, '2026-10-02'), entry(2, 1, '2026-10-30')],
        unknown: [entry(3, 3, '2026-10-03', team: null)]);
    expect(result.assignmentCount, 4);
    expect(result.uniquePersonnel, 3);
    expect(result.recordedDays, 3);
    expect(result.totalDays, 31);
    expect(result.knownTeamAssignments, 3);
    expect(result.unknownTeamAssignments, 1);
    expect(result.teamCoverage, .75);
    expect(result.days.fold<int>(0, (n, day) => n + day.assignments), 4);
    expect(result.duties.single.count, 4);
    expect(result.teams.single.total, 3);
    expect(result.days[29].isPlanned, isTrue);
    expect(result.days[27].isPlanned, isFalse);
    expect(result.days[2].teams, isEmpty);
  });

  test('coverage crossing months is not an additional source-date assignment',
      () {
    final result = report([
      entry(1, 1, '2026-09-30',
          duty: 'HAZIR KITA', covered: ['2026-09-30', '2026-10-01']),
      entry(2, 1, '2026-10-31',
          duty: 'HAZIR KITA', covered: ['2026-10-31', '2026-11-01']),
    ]);
    expect(result.assignmentCount, 1);
    expect(result.days.first.assignments, 0);
    expect(result.days.last.assignments, 1);
  });

  test('explicit aliases merge before dedup; ambiguous names remain reviewable',
      () {
    final result = report([
      entry(1, 1, '2026-10-02', duty: 'Hazırkıta'),
      entry(1, 1, '2026-10-02', duty: 'HAZIR KITA'),
      entry(2, 1, '2026-10-03', duty: 'Hazırkıta İsim'),
    ]);
    expect(result.assignmentCount, 2);
    expect(result.duties.map((d) => d.duty), contains('HAZIR KITA'));
    expect(result.unclassifiedAssignments, 1);
  });

  test('empty leap-month report has all days and zero coverage', () {
    final result = MonthlyAnalyticsReport(
        data: TeamAnalytics(
            filter: AnalyticsFilter(start: '2024-02-01', end: '2024-02-29'),
            entries: []),
        asOf: DateTime(2024, 2, 29));
    expect(result.days.length, 29);
    expect(result.assignmentCount, 0);
    expect(result.recordedDays, 0);
    expect(result.teamCoverage, 0);
    expect(result.duties, isEmpty);
    expect(result.teams, isEmpty);
    expect(() => result.days.clear(), throwsUnsupportedError);
  });

  test('authorized teams with no records remain visible with zero totals', () {
    final result = MonthlyAnalyticsReport(
        data: TeamAnalytics(
            filter: filter, entries: [], teams: {1: '1. Tim', 2: '2. Tim'}),
        asOf: DateTime(2026, 10, 28));
    expect(result.teams.map((team) => team.total), [0, 0]);
    expect(result.days.first.teams, isEmpty);
  });

  test('scope and status remain enforced in both summary and team matrix', () {
    final result = MonthlyAnalyticsReport(
        data: TeamAnalytics(
            filter: AnalyticsFilter(
                start: '2026-10-01',
                end: '2026-10-03',
                teamId: 1,
                duty: 'HAZIR KITA'),
            entries: [
              entry(1, 1, '2026-10-01', duty: 'Hazırkıta'),
              entry(2, 2, '2026-10-01', team: 2, duty: 'HAZIR KITA'),
              entry(3, 3, '2026-10-01', duty: 'HEYBET'),
              entry(4, 4, '2026-10-01', duty: 'HAZIR KITA', status: 'beklemede')
            ],
            unknownEntries: [
              entry(5, 5, '2026-10-01', team: null, duty: 'HAZIR KITA')
            ]),
        asOf: DateTime(2026, 10, 2));
    expect(result.assignmentCount, 1);
    expect(result.totalDays, 3);
    expect(result.unknownTeamAssignments, 0);
  });
}

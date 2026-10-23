import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/watch_roster/domain/watch_roster.dart';

AnalyticsEntry entry(int activity, int person, String date, {int? team = 1}) =>
    AnalyticsEntry(
        activityId: activity,
        activityName: 'Görev $activity',
        sourceDate: date,
        personnelId: person,
        personnelName: 'Personel $person',
        teamId: team,
        teamName: '',
        duty: 'MEBS NÖB.',
        status: 'onaylandi',
        coveredDates: [date, '2026-11-01']);

void main() {
  test('dates are chronological and only exact watch duties are included', () {
    final data = TeamAnalytics(
        filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-31'),
        entries: [
          entry(3, 1, '2026-10-31'),
          entry(2, 1, '2026-10-02'),
          AnalyticsEntry(
              activityId: 4,
              activityName: 'Other',
              sourceDate: '2026-10-01',
              personnelId: 1,
              personnelName: 'Other',
              teamId: 1,
              teamName: '',
              duty: 'HEYBET',
              status: 'onaylandi',
              coveredDates: ['2026-10-01'])
        ]);
    final roster = WatchRoster(data);
    expect(roster.dates, ['2026-10-02', '2026-10-31']);
    expect(roster.records('2026-10-01', 'HEYBET'), isEmpty);
    expect(
        watchDuties.keys, ['MEBS NÖB.', 'GARAJ NÖB.', 'TTZA NÖB.', 'NÖB. SB.']);
  });

  test(
      'source month only; distinct people per activity; unknown teams retained',
      () {
    final data = TeamAnalytics(
        filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-31'),
        entries: [
          entry(1, 1, '2026-09-30'),
          entry(2, 1, '2026-10-31'),
          entry(2, 1, '2026-10-31'),
          entry(3, 1, '2026-10-31')
        ],
        unknownEntries: [
          entry(2, 2, '2026-10-31', team: null)
        ]);
    final roster = WatchRoster(data);
    expect(roster.records('2026-10-01', 'MEBS NÖB.'), isEmpty);
    final records = roster.records('2026-10-31', 'MEBS NÖB.');
    expect(records.map((r) => r.activityId), [2, 3]);
    expect(records.first.personnel.map((p) => p.personnelId), [1, 2]);
    expect(roster.records('2026-11-01', 'MEBS NÖB.'), isEmpty);
  });
}

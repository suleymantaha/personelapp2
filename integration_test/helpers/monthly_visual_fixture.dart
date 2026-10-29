import 'package:personelapp2/features/analytics/domain/team_analytics.dart';

/// Synthetic data only; no restored device database or real personnel names.
TeamAnalytics monthlyVisualFixture(AnalyticsFilter filter) {
  final entries = <AnalyticsEntry>[];
  final unknown = <AnalyticsEntry>[];
  const duties = [
    'HEYBET',
    'GÖREVLİ',
    'HAZIR KITA',
    'GÜLÜŞKÜR',
    'GARAJ NÖB.',
    'NÖB. SB.',
    'MEBS NÖB.',
    'TTZA NÖB.',
    'ÇOK UZUN AÇIKLAMALI ÖRNEK GÖREV ADI'
  ];
  var index = 0;
  for (var day = 1; day <= 30; day++) {
    final count = day == 9
        ? 148
        : day == 1
            ? 103
            : 77;
    final date = '2026-10-${day.toString().padLeft(2, '0')}';
    for (var n = 0; n < count; n++) {
      final person = index % 178 + 1;
      final team = index % 29 == 0 ? null : person % 17 + 1;
      final row = AnalyticsEntry(
          activityId: ++index,
          activityName: 'Sentetik',
          sourceDate: date,
          personnelId: person,
          personnelName: 'Sentetik',
          teamId: team,
          teamName: team == null ? 'Bilinmiyor' : '$team. Tim',
          duty: duties[n % duties.length],
          status: 'onaylandi',
          coveredDates: [date]);
      (team == null ? unknown : entries).add(row);
    }
  }
  return TeamAnalytics(
      filter: filter,
      entries: entries,
      unknownEntries: unknown,
      currentHeadcount: 185,
      headcountAsOf: DateTime(2026, 10, 29),
      teams: {for (var team = 1; team <= 17; team++) team: '$team. Tim'});
}

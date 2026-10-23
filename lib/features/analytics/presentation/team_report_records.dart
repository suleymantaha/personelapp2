import '../domain/team_analytics.dart';

/// Presentation counts records, never the matrix's covered calendar cells.
List<List<AnalyticsEntry>> reportRecords(Iterable<AnalyticsEntry> entries) {
  final groups = <(int, String), List<AnalyticsEntry>>{};
  for (final entry in entries) {
    groups.putIfAbsent((entry.activityId, entry.duty), () => []).add(entry);
  }
  return groups.values.toList()
    ..sort((a, b) {
      final date = b.first.sourceDate.compareTo(a.first.sourceDate);
      return date != 0
          ? date
          : b.first.activityId.compareTo(a.first.activityId);
    });
}

int reportPeople(Iterable<AnalyticsEntry> entries) =>
    entries.map((entry) => entry.personnelId).toSet().length;

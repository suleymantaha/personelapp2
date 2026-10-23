import '../../analytics/domain/team_analytics.dart';

const watchDuties = <String, String>{
  'MEBS NÖB.': 'MEBS',
  'GARAJ NÖB.': 'GARAJ',
  'TTZA NÖB.': 'TTZA',
  'NÖB. SB.': 'NÖB. SB.',
};

class WatchRecord {
  WatchRecord(this.activityId, this.activityName, this.personnel);
  final int activityId;
  final String activityName;
  final List<AnalyticsEntry> personnel;
}

/// Uses authorized source records, never the expanded daily matrix marks.
class WatchRoster {
  WatchRoster(TeamAnalytics data) {
    final grouped = <(String, String), Map<int, Map<int, AnalyticsEntry>>>{};
    for (final e in [...data.entries, ...data.unknownEntries]) {
      if (!watchDuties.containsKey(e.duty) ||
          e.sourceDate.compareTo(data.filter.start) < 0 ||
          e.sourceDate.compareTo(data.filter.end) > 0) {
        continue;
      }
      grouped
          .putIfAbsent((e.sourceDate, e.duty), () => {})
          .putIfAbsent(e.activityId, () => {})
          .putIfAbsent(e.personnelId, () => e);
    }
    for (final group in grouped.entries) {
      final ids = group.value.keys.toList()..sort();
      _records[group.key] = [
        for (final id in ids)
          WatchRecord(
              id,
              group.value[id]!.values.first.activityName,
              List.unmodifiable(group.value[id]!.values.toList()
                ..sort((a, b) => a.personnelId.compareTo(b.personnelId)))),
      ];
    }
  }
  final _records = <(String, String), List<WatchRecord>>{};
  bool get isEmpty => _records.isEmpty;
  List<String> get dates =>
      _records.keys.map((key) => key.$1).toSet().toList()..sort();
  List<WatchRecord> records(String date, String duty) =>
      List.unmodifiable(_records[(date, duty)] ?? const <WatchRecord>[]);
}

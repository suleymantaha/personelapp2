import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';

DateTime analyticsDate(String value) {
  final date = DateTime.tryParse(value);
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
      date == null ||
      date.toIso8601String().substring(0, 10) != value) {
    throw ArgumentError.value(value, 'date', 'Geçersiz takvim tarihi');
  }
  return date;
}

class AnalyticsFilter {
  AnalyticsFilter(
      {required this.start,
      required this.end,
      this.teamId,
      this.duty,
      this.status = AssignmentStatus.onaylandi}) {
    final days = analyticsDate(end).difference(analyticsDate(start)).inDays;
    if (days < 0 || days > 365) throw ArgumentError('Aralık 1–366 gün olmalı');
    if (![
      AssignmentStatus.onaylandi,
      AssignmentStatus.beklemede,
      AssignmentStatus.reddedildi
    ].contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
  }
  final String start;
  final String end;
  final int? teamId;
  final String? duty;
  final String status;
  @override
  bool operator ==(Object other) =>
      other is AnalyticsFilter &&
      start == other.start &&
      end == other.end &&
      teamId == other.teamId &&
      duty == other.duty &&
      status == other.status;
  @override
  int get hashCode => Object.hash(start, end, teamId, duty, status);
}

class AnalyticsEntry {
  AnalyticsEntry(
      {required this.activityId,
      required this.activityName,
      required this.sourceDate,
      required this.personnelId,
      required this.personnelName,
      required this.teamId,
      required this.teamName,
      required this.duty,
      required this.status,
      required List<String> coveredDates})
      : coveredDates = List.unmodifiable(coveredDates);
  final int activityId;
  final String activityName;
  final String sourceDate;
  final int personnelId;
  final String personnelName;
  final int? teamId;
  final String teamName;
  final String duty;
  final String status;
  final List<String> coveredDates;
}

class AnalyticsMetrics {
  AnalyticsMetrics(Iterable<AnalyticsEntry> entries, String start, String end) {
    final participationsSet = <(int?, String, int)>{};
    final days = <String>{};
    final people = <int>{};
    final tasks = <(int?, String, int, int)>{};
    final personDays = <(int, String)>{};
    for (final entry in entries) {
      final covered = entry.coveredDates
          .where((d) => d.compareTo(start) >= 0 && d.compareTo(end) <= 0);
      if (covered.isEmpty) continue;
      days.addAll(covered);
      people.add(entry.personnelId);
      personDays.addAll(covered.map((d) => (entry.personnelId, d)));
      if (entry.sourceDate.compareTo(start) < 0 ||
          entry.sourceDate.compareTo(end) > 0) {
        continue;
      }
      participationsSet.add((entry.teamId, entry.duty, entry.activityId));
      tasks
          .add((entry.teamId, entry.duty, entry.activityId, entry.personnelId));
    }
    participations = participationsSet.length;
    dutyDays = days.length;
    uniquePersonnel = people.length;
    personnelTasks = tasks.length;
    personnelDays = personDays.length;
  }
  late final int participations;
  late final int dutyDays;
  late final int uniquePersonnel;
  late final int personnelTasks;
  late final int personnelDays;
}

class AnalyticsMonth {
  const AnalyticsMonth(this.month, this.metrics);
  final String month;
  final AnalyticsMetrics metrics;
}

class TeamAnalytics {
  TeamAnalytics(
      {required this.filter,
      required Iterable<AnalyticsEntry> entries,
      Iterable<AnalyticsEntry> unknownEntries = const [],
      Map<int, String> teams = const {},
      Iterable<String>? availableDuties,
      this.duplicateAssignments = 0,
      this.possibleDuplicateActivities = 0})
      : entries = List.unmodifiable(entries),
        unknownEntries = List.unmodifiable(unknownEntries),
        teams = Map.unmodifiable(teams),
        availableDuties = List.unmodifiable(
            (availableDuties ?? entries.map((e) => e.duty)).toSet().toList()
              ..sort());
  final AnalyticsFilter filter;
  final List<AnalyticsEntry> entries;
  final List<AnalyticsEntry> unknownEntries;
  final Map<int, String> teams;
  final List<String> availableDuties;
  final int duplicateAssignments;
  final int possibleDuplicateActivities;
  /// One ordering for every analytics surface, aligned with personnel and
  /// activity screens. Unknown/custom names remain after the official squads.
  List<int> sortTeamIds(Iterable<int> ids) {
    final sorted = ids.toSet().toList();
    sorted.sort((a, b) {
      final nameA = teams[a] ?? 'Tim #$a';
      final nameB = teams[b] ?? 'Tim #$b';
      final weightA = MilitaryStructureHelper.getSquadOrderWeight(nameA);
      final weightB = MilitaryStructureHelper.getSquadOrderWeight(nameB);
      if (weightA != weightB) return weightA.compareTo(weightB);
      final nameOrder = nameA.compareTo(nameB);
      return nameOrder != 0 ? nameOrder : a.compareTo(b);
    });
    return sorted;
  }

  /// Timlerin görev raporlarındaki sırası (aktif filtre sonuçları).
  List<int> get orderedTeamIds =>
      sortTeamIds(entries.map((e) => e.teamId).whereType<int>());

  /// Filtrede mevcut tüm yetkili timler; görev kaydı olmayanlar da dahil.
  List<int> get orderedAvailableTeamIds => sortTeamIds(teams.keys);

  int get unknownTeamAssignments => unknownEntries.length;
  AnalyticsMetrics get metrics =>
      AnalyticsMetrics(entries, filter.start, filter.end);
  List<String> get duties =>
      (entries.map((e) => e.duty).toSet().toList()..sort());
  List<AnalyticsMonth> get monthly {
    final result = <AnalyticsMonth>[];
    var month = analyticsDate(filter.start);
    month = DateTime(month.year, month.month);
    final end = analyticsDate(filter.end);
    while (!month.isAfter(end)) {
      final label = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      final last = DateTime(month.year, month.month + 1, 0);
      final monthStart = '$label-01';
      final monthEnd = '$label-${last.day.toString().padLeft(2, '0')}';
      result.add(AnalyticsMonth(
          label,
          AnalyticsMetrics(
              entries,
              monthStart.compareTo(filter.start) < 0
                  ? filter.start
                  : monthStart,
              monthEnd.compareTo(filter.end) > 0 ? filter.end : monthEnd)));
      month = DateTime(month.year, month.month + 1);
    }
    return List.unmodifiable(result);
  }

  TeamAnalytics forTeam(int id) => TeamAnalytics(
      filter: filter,
      entries: entries.where((e) => e.teamId == id),
      teams: {id: teams[id] ?? 'Tim #$id'});
  TeamAnalytics forDuty(String duty) => TeamAnalytics(
      filter: filter,
      entries: entries.where((e) => e.duty == duty),
      teams: teams);
}

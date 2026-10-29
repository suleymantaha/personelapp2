import 'package:personelapp2/features/activity/domain/conflict_checker.dart';

/// Only a verified spelling alias is merged; ambiguous imported labels stay visible.
String analyticsDutyLabel(String value) {
  final label = value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  if (label.replaceAll('İ', 'I').replaceAll(' ', '') == 'HAZIRKITA') {
    return 'HAZIR KITA';
  }
  return label;
}

bool isClassifiedAnalyticsDuty(String duty) =>
    DutyOrLeaveType.allDuties.contains(duty) ||
    const {'DDE', 'HEYBET AKŞAM'}.contains(duty);

class MonthlyDutyCount {
  const MonthlyDutyCount(this.duty, this.count);
  final String duty;
  final int count;
}

class MonthlyTeamRow {
  MonthlyTeamRow(this.teamId, this.name, Map<String, int> duties,
      {this.uniquePersonnel = 0,
      Map<String, int> uniquePersonnelByDuty = const {}})
      : duties = Map.unmodifiable(duties),
        uniquePersonnelByDuty = Map.unmodifiable(uniquePersonnelByDuty);
  final int teamId;
  final String name;
  final Map<String, int> duties;
  final int uniquePersonnel;
  final Map<String, int> uniquePersonnelByDuty;
  int get total => duties.values.fold(0, (sum, value) => sum + value);
}

class MonthlyAnalyticsDay {
  MonthlyAnalyticsDay(
      {required this.date,
      required this.assignments,
      this.uniquePersonnel = 0,
      required this.isPlanned,
      required List<MonthlyDutyCount> duties,
      required List<MonthlyTeamRow> teams})
      : duties = List.unmodifiable(duties),
        teams = List.unmodifiable(teams);
  final String date;
  final int assignments;
  final int uniquePersonnel;
  final bool isPlanned;
  final List<MonthlyDutyCount> duties;
  final List<MonthlyTeamRow> teams;
}

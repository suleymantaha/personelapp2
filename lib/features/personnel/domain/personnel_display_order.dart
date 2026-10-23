import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

/// Saved positions win; unpositioned records follow the saved list.
int compareSavedOrder(int? a, int? b) {
  if (a == b) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int compareSquads(TimTableData a, TimTableData b) {
  final saved = compareSavedOrder(a.sortOrder, b.sortOrder);
  if (saved != 0) return saved;
  final official = MilitaryStructureHelper.getSquadOrderWeight(a.timAdi)
      .compareTo(MilitaryStructureHelper.getSquadOrderWeight(b.timAdi));
  if (official != 0) return official;
  final name = a.timAdi.compareTo(b.timAdi);
  return name != 0 ? name : a.id.compareTo(b.id);
}

int comparePersonnelWithinTeam(PersonelTableData a, PersonelTableData b) {
  final saved = compareSavedOrder(a.sortOrder, b.sortOrder);
  if (saved != 0) return saved;
  final rank = getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe));
  if (rank != 0) return rank;
  final name = a.adSoyad.compareTo(b.adSoyad);
  return name != 0 ? name : a.id.compareTo(b.id);
}

List<TimTableData> orderDisplaySquads(Iterable<TimTableData> squads) =>
    squads.toList()..sort(compareSquads);

List<PersonelTableData> orderDisplayPersonnel(
  Iterable<PersonelTableData> personnel,
  Iterable<TimTableData> squads,
) {
  final teams = {for (final team in squads) team.id: team};
  return personnel.toList()
    ..sort((a, b) {
      if (a.timId != b.timId) {
        if (a.timId == null) return 1;
        if (b.timId == null) return -1;
        final teamA = teams[a.timId];
        final teamB = teams[b.timId];
        if (teamA != null && teamB != null) {
          final team = compareSquads(teamA, teamB);
          if (team != 0) return team;
        } else {
          if (teamA != null) return -1;
          if (teamB != null) return 1;
          final id = a.timId!.compareTo(b.timId!);
          if (id != 0) return id;
        }
      }
      return comparePersonnelWithinTeam(a, b);
    });
}

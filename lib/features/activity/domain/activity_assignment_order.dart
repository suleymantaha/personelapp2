import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

/// Applies the official roster rules used by PDF, print and Excel exports.
///
/// The pasted-text order is deliberately ignored. Duties are ordered first,
/// followed by the official unit order, rank and personnel name. Assignment id
/// is used only as a final deterministic tie-breaker.
List<FaaliyetPersonelAtamaTableData> orderAssignmentsForExport(
  Iterable<FaaliyetPersonelAtamaTableData> assignments,
  Map<int, PersonelTableData> personnelById,
  Map<int, String> squadNames,
) {
  return assignments.toList()
    ..sort((a, b) {
      final categoryA = MilitaryStructureHelper.getDutyCategoryOrder(
        a.gorevVeyaIzin,
      );
      final categoryB = MilitaryStructureHelper.getDutyCategoryOrder(
        b.gorevVeyaIzin,
      );
      if (categoryA != categoryB) return categoryA.compareTo(categoryB);

      final personA = personnelById[a.personelId];
      final personB = personnelById[b.personelId];

      // Nöbet heyeti is a single official unit, so its internal order starts
      // directly with rank rather than the personnel's normal team.
      if (categoryA != 10) {
        final unitA = _rosterUnit(a, personA, squadNames);
        final unitB = _rosterUnit(b, personB, squadNames);
        final unitComparison = MilitaryStructureHelper.getSquadOrderWeight(
          unitA,
        ).compareTo(MilitaryStructureHelper.getSquadOrderWeight(unitB));
        if (unitComparison != 0) return unitComparison;

        final unitNameComparison = unitA.compareTo(unitB);
        if (unitNameComparison != 0) return unitNameComparison;
      }

      final rankComparison = getRankWeight(
        personA?.rutbe ?? '',
      ).compareTo(getRankWeight(personB?.rutbe ?? ''));
      if (rankComparison != 0) return rankComparison;

      final nameComparison = (personA?.adSoyad ?? '').compareTo(
        personB?.adSoyad ?? '',
      );
      if (nameComparison != 0) return nameComparison;
      return a.id.compareTo(b.id);
    });
}

String _rosterUnit(
  FaaliyetPersonelAtamaTableData assignment,
  PersonelTableData? person,
  Map<int, String> squadNames,
) {
  return MilitaryStructureHelper.getRosterBirlikName(
    timName: squadNames[person?.timId] ?? '',
    birlik: person?.birlik ?? '',
    duty: assignment.gorevVeyaIzin,
  );
}

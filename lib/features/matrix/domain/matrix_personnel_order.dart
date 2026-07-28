import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

/// Aylık çizelgede personeli resmi tim sırası, rütbe ve ada göre sıralar.
///
/// Time atanmamış personel listenin sonunda gösterilir.
List<PersonelTableData> orderMatrixPersonnel(
  Iterable<PersonelTableData> personnel,
  Iterable<TimTableData> squads,
) {
  final squadNames = {for (final squad in squads) squad.id: squad.timAdi};

  return personnel.toList()
    ..sort((a, b) {
      final timA = a.timId;
      final timB = b.timId;

      if (timA == null && timB != null) return 1;
      if (timA != null && timB == null) return -1;

      if (timA != timB) {
        final nameA = squadNames[timA] ?? '';
        final nameB = squadNames[timB] ?? '';
        final weightComparison = MilitaryStructureHelper.getSquadOrderWeight(
          nameA,
        ).compareTo(MilitaryStructureHelper.getSquadOrderWeight(nameB));
        if (weightComparison != 0) return weightComparison;

        final nameComparison = nameA.compareTo(nameB);
        if (nameComparison != 0) return nameComparison;
      }

      final rankComparison =
          getRankWeight(a.rutbe).compareTo(getRankWeight(b.rutbe));
      if (rankComparison != 0) return rankComparison;
      return a.adSoyad.compareTo(b.adSoyad);
    });
}

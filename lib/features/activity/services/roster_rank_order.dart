import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

/// An optional export view. The selected card order and stored rows stay intact.
List<MilitaryRosterRow> rankOrderedRosterRows(List<MilitaryRosterRow> rows) {
  final indexed = rows.asMap().entries.toList()
    ..sort((a, b) {
      final rank =
          getRankWeight(a.value.rutbe).compareTo(getRankWeight(b.value.rutbe));
      return rank != 0 ? rank : a.key.compareTo(b.key);
    });

  return [
    for (var i = 0; i < indexed.length; i++)
      MilitaryRosterRow(
        sNu: i + 1,
        personelId: indexed[i].value.personelId,
        birligi: indexed[i].value.birligi,
        rutbe: indexed[i].value.rutbe,
        adSoyad: indexed[i].value.adSoyad,
        diger: indexed[i].value.diger,
        groupCode: indexed[i].value.groupCode,
      ),
  ];
}

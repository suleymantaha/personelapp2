import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

// Group lengths observed in the 133-person reference XLSX. All field values
// below are synthetic. The shorter signed case represents the 105-row photo.
const _groupLengths = [
  5,
  19,
  2,
  9,
  7,
  12,
  4,
  7,
  9,
  11,
  2,
  7,
  7,
  11,
  9,
  2,
  4,
  1,
  5,
];

List<MilitaryRosterRow> a4ReferenceRows(int count) {
  final rows = <MilitaryRosterRow>[];
  for (final (group, length) in _groupLengths.indexed) {
    for (var row = 0; row < length && rows.length < count; row++) {
      final number = rows.length + 1;
      rows.add(MilitaryRosterRow(
        sNu: number,
        personelId: number,
        birligi: '${group + 1}-A Timi',
        rutbe: row == 0 ? 'J.Asb.Kd.Bçvş.' : 'J.Uzm.Çvş.',
        adSoyad: number % 17 == 0
            ? 'ÖRNEK ${number.toString().padLeft(3, '0')} UZUN AD SOYAD'
            : 'ÖRNEK ${number.toString().padLeft(3, '0')} PERSONEL',
        diger: group >= 16 ? 'ÖRNEK GÖREV' : '',
        groupCode: group >= 16 ? 'HAZIR_KITA' : 'DIGER',
      ));
    }
  }
  return rows;
}

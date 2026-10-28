import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_rank_order.dart';

MilitaryRosterRow row(int number, String name, String rank, int id) =>
    MilitaryRosterRow(
      sNu: number,
      personelId: id,
      birligi: '1-B',
      rutbe: rank,
      adSoyad: name,
      diger: 'Görev',
      groupCode: 'HAZIR_KITA',
    );

void main() {
  test(
      'rank option sorts globally, keeps same-rank order and renumbers only copies',
      () {
    final original = [
      row(1, 'Er A', 'J.Er', 1),
      row(2, 'Yüzbaşı', 'J.Yzb.', 2),
      row(3, 'Er B', 'J.Er', 3),
      row(4, 'Astsubay', 'J.Asb.Çvş.', 4),
      row(5, 'Bilinmeyen', 'Özel', 5),
    ];

    final sorted = rankOrderedRosterRows(original);

    expect(sorted.map((r) => r.personelId), [2, 4, 1, 3, 5]);
    expect(sorted.map((r) => r.sNu), [1, 2, 3, 4, 5]);
    expect(sorted.map((r) => r.groupCode), everyElement('HAZIR_KITA'));
    expect(sorted.map((r) => r.birligi), everyElement('1-B'));
    expect(sorted.map((r) => r.diger), everyElement('Görev'));
    expect(original.map((r) => r.personelId), [1, 2, 3, 4, 5]);
    expect(original.map((r) => r.sNu), [1, 2, 3, 4, 5]);
  });
}

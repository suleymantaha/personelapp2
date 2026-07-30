import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/activity_assignment_order.dart';

void main() {
  const squads = {1: '1-B Timi', 6: '6-B Timi'};
  const personnel = {
    1: PersonelTableData(
      id: 1,
      adSoyad: 'Astsubay Altı',
      rutbe: 'J.Asb.Çvş.',
      birlik: '',
      timId: 6,
      kayitTarihi: '',
    ),
    2: PersonelTableData(
      id: 2,
      adSoyad: 'Uzman İki',
      rutbe: 'J.Uzm.Çvş.',
      birlik: '',
      timId: 1,
      kayitTarihi: '',
    ),
    3: PersonelTableData(
      id: 3,
      adSoyad: 'Astsubay Bir',
      rutbe: 'J.Asb.Bçvş.',
      birlik: '',
      timId: 1,
      kayitTarihi: '',
    ),
  };

  FaaliyetPersonelAtamaTableData assignment(
    int id,
    int personnelId,
    String duty,
  ) {
    return FaaliyetPersonelAtamaTableData(
      id: id,
      faaliyetId: 1,
      personelId: personnelId,
      gorevVeyaIzin: duty,
      durum: 'onaylandi',
    );
  }

  test('ignores paste order and applies duty category rules', () {
    final ordered = orderAssignmentsForExport(
      [
        assignment(1, 1, 'GÜLÜŞKÜR'),
        assignment(2, 2, 'HAZIR KITA'),
        assignment(3, 3, 'DEVRİYE'),
        assignment(4, 1, 'NÖBETÇİ HEYETİ'),
      ],
      personnel,
      squads,
    );

    expect(ordered.map((item) => item.id), [4, 3, 2, 1]);
  });

  test('orders a duty group by official unit, rank and name', () {
    final ordered = orderAssignmentsForExport(
      [
        assignment(1, 1, 'DEVRİYE'),
        assignment(2, 2, 'DEVRİYE'),
        assignment(3, 3, 'DEVRİYE'),
      ],
      personnel,
      squads,
    );

    expect(ordered.map((item) => item.personelId), [3, 2, 1]);
  });

  test('orders Nöbet Heyeti by official duty order before rank and name', () {
    final ordered = orderAssignmentsForExport(
      [
        assignment(6, 3, 'KULE NÖB.'),
        assignment(5, 3, 'TTZA NÖB.'),
        assignment(4, 3, 'GARAJ NÖB.'),
        assignment(3, 3, 'MEBS NÖB.'),
        assignment(2, 2, 'NÖB.SB.'),
        assignment(1, 1, 'HEYBET KOMUTANI'),
      ],
      personnel,
      squads,
    );

    expect(ordered.map((item) => item.id), [1, 2, 3, 4, 5, 6]);
  });

  test('does not mutate the source assignment list', () {
    final first = assignment(2, 2, 'GÜLÜŞKÜR');
    final second = assignment(1, 1, 'NÖBETÇİ HEYETİ');
    final source = [first, second];

    final ordered = orderAssignmentsForExport(source, personnel, squads);

    expect(source, [first, second]);
    expect(ordered, [second, first]);
  });
}

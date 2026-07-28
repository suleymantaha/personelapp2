import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/matrix/domain/matrix_personnel_order.dart';

void main() {
  PersonelTableData person(
    int id,
    String name,
    String rank, {
    int? timId,
  }) {
    return PersonelTableData(
      id: id,
      adSoyad: name,
      rutbe: rank,
      birlik: '',
      timId: timId,
      kayitTarihi: '',
    );
  }

  test('orders by official team, rank, name and puts unassigned last', () {
    const squads = [
      TimTableData(id: 1, timAdi: '7-B Timi', olusturmaTarihi: ''),
      TimTableData(id: 2, timAdi: 'K.H', olusturmaTarihi: ''),
      TimTableData(id: 3, timAdi: '2-B Timi', olusturmaTarihi: ''),
    ];
    final personnel = [
      person(1, 'Zeki', 'J.Ütğm.', timId: 1),
      person(2, 'Timsiz', 'J.Alb.'),
      person(3, 'Bora', 'J.Ütğm.', timId: 3),
      person(4, 'Cem', 'J.Bnb.', timId: 2),
      person(5, 'Ali', 'J.Bnb.', timId: 2),
    ];

    final ordered = orderMatrixPersonnel(personnel, squads);

    expect(
      ordered.map((person) => person.adSoyad),
      ['Ali', 'Cem', 'Bora', 'Zeki', 'Timsiz'],
    );
  });
}

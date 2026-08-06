import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_search_service.dart';

void main() {
  const personnel = [
    PersonelTableData(
      id: 1,
      adSoyad: 'Ahmet Yılmaz',
      rutbe: 'J.Asb.Çvş.',
      birlik: 'K.H',
      kayitTarihi: '2026-01-01',
    ),
    PersonelTableData(
      id: 2,
      adSoyad: 'Mehmet Demir',
      rutbe: 'J.Uzm.Çvş.',
      birlik: '1-B Timi',
      kayitTarihi: '2026-01-01',
    ),
  ];

  test('personeli ad, rütbe ve birlik alanlarında arar', () {
    expect(
      PersonnelSearchService.searchPersonnel('yilmaz', personnel),
      [personnel.first],
    );
    expect(
      PersonnelSearchService.searchPersonnel('uzm', personnel),
      [personnel.last],
    );
    expect(
      PersonnelSearchService.searchPersonnel('1 b timi', personnel),
      [personnel.last],
    );
  });

  test('farklı alanlardan gelen kelimeleri birlikte eşleştirir', () {
    expect(
      PersonnelSearchService.searchPersonnel('mehmet uzm 1 b', personnel),
      [personnel.last],
    );
  });
}

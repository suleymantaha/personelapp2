import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';

void main() {
  group('getRankWeight tests', () {
    test('Officer ranks should be senior to NCOs and Enlisted', () {
      expect(getRankWeight('ALBAY'), lessThan(getRankWeight('YÜZBAŞI')));
      expect(getRankWeight('YÜZBAŞI'), lessThan(getRankWeight('TEĞMEN')));
      expect(getRankWeight('TEĞMEN'), lessThan(getRankWeight('ASB.KD.BÇVŞ')));
    });

    test('NCO ranks should be senior to Specialist Sergeants', () {
      expect(getRankWeight('ASB.KD.BÇVŞ'), lessThan(getRankWeight('ASB.ÇVŞ')));
      expect(getRankWeight('ASB.ÇVŞ'), lessThan(getRankWeight('UZM.ÇVŞ')));
    });

    test('Specialist Sergeants should be senior to Private Enlisted', () {
      expect(getRankWeight('UZM.ÇVŞ'), lessThan(getRankWeight('SÖZ.ER')));
      expect(getRankWeight('SÖZ.ER'), lessThan(getRankWeight('ER')));
    });

    test('Unknown ranks should return weight 300', () {
      expect(getRankWeight('SİVİL MEMUR'), equals(300));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  group('BulkTextParser.parsePersonnelList', () {
    test('parses numbered and bullet personnel with normalized ranks', () {
      final result = BulkTextParser.parsePersonnelList('''
Personel Listesi
1. J.Asb.Çvş. Ahmet YILMAZ
• J.Uzm.Çvş. Mehmet DEMİR
''');

      expect(result.personnel, hasLength(2));
      expect(result.personnel[0].rawName, 'Ahmet YILMAZ');
      expect(result.personnel[0].rawRank, 'J.Asb.Çvş.');
      expect(result.personnel[1].rawName, 'Mehmet DEMİR');
      expect(result.personnel[1].rawRank, 'J.Uzm.Çvş.');
    });

    test('keeps an unranked name and reports a warning', () {
      final result = BulkTextParser.parsePersonnelList('Ali VELİ');

      expect(result.personnel.single.rawName, 'Ali VELİ');
      expect(result.personnel.single.rawRank, isEmpty);
      expect(result.issues.single.code, 'unknown_rank');
    });
  });
}

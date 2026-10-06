import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  group('BulkTextParser Extended (Military Branches & Ranks)', () {
    test('parses personnel line with branch prefix J.Per.Asb.Kd.Üçvş. correctly', () {
      final result = BulkTextParser.parsePersonnelList(
        '1. J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN',
      );

      expect(result.personnel, hasLength(1));
      final person = result.personnel.single;
      expect(person.rawRank, equals('J.Asb.Kd.Üçvş.'));
      expect(person.rawName, equals('Ahmet Mustafa ÇALIŞKAN'));
      expect(person.rawIndex, equals(1));
      expect(result.issues.where((i) => i.code == 'unknown_rank'), isEmpty);
      expect(result.issues.where((i) => i.code == 'invalid_personnel'), isEmpty);
    });

    test('parses full block with diverse branch prefixed ranks without warnings', () {
      const input = '''
14.08.2026 1. JÖH TİMİ İSİM LİSTESİ
1. J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN
2. J.İkm.Asb.Bçvş. Mehmet YILMAZ
3. J.Mu.Asb.Kd.Çvş. Ali KAYA
4. J.Bkm.Uzm.Çvş. Hasan DEMİR
5. J.Asyş.Tğm. Burak CAN
''';

      final result = BulkTextParser.parse(input);
      expect(result.hasBlockingIssues, isFalse);
      expect(result.blocks, hasLength(1));

      final block = result.blocks.single;
      expect(block.personnelList, hasLength(5));

      expect(block.personnelList[0].rawRank, equals('J.Asb.Kd.Üçvş.'));
      expect(block.personnelList[0].rawName, equals('Ahmet Mustafa ÇALIŞKAN'));

      expect(block.personnelList[1].rawRank, equals('J.Asb.Bçvş.'));
      expect(block.personnelList[1].rawName, equals('Mehmet YILMAZ'));

      expect(block.personnelList[2].rawRank, equals('J.Asb.Kd.Çvş.'));
      expect(block.personnelList[2].rawName, equals('Ali KAYA'));

      expect(block.personnelList[3].rawRank, equals('J.Uzm.Çvş.'));
      expect(block.personnelList[3].rawName, equals('Hasan DEMİR'));

      expect(block.personnelList[4].rawRank, equals('J.Tğm.'));
      expect(block.personnelList[4].rawName, equals('Burak CAN'));

      expect(result.issues.where((i) => i.code == 'unknown_rank'), isEmpty);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  group('BulkTextParser Edge Cases', () {
    test('splits multiple personnel on the same line', () {
      const input = '''
*02.08.2026*
*11-B Timi Gülüşkür İsim Listesi*
5. J.Uzm.Çvş. Yusuf TUŞ 6.J.Uzm.Çvş. Ertuğrul BAĞCI
''';
      final result = BulkTextParser.parse(input);
      expect(result.blocks.single.personnelList, hasLength(2));
      expect(result.blocks.single.personnelList[0].rawName, 'Yusuf TUŞ');
      expect(result.blocks.single.personnelList[1].rawName, 'Ertuğrul BAĞCI');
    });

    test('recognizes space-separated time ranges like 08:00 20:00', () {
      const input = '''
*02.08.2026*
*11-B Timi Gülüşkür İsim Listesi*
08:00 20:00
1. J.Asb.Ü.Çvş. Selahattin ÇAKIR
''';
      final result = BulkTextParser.parse(input);
      for (final issue in result.issues) {
        print('Issue: ${issue.code} - ${issue.message} - line: ${issue.rawLine}');
      }
      expect(result.issues.any((i) => i.code == 'invalid_personnel'), isFalse);
      expect(result.blocks.single.personnelList, hasLength(1));
    });

    test('recognizes abbreviated rank J.Asb.Ü.Çvş.', () {
      const input = '''
*02.08.2026*
*11-B Timi Gülüşkür İsim Listesi*
1. J.Asb.Ü.Çvş. Selahattin ÇAKIR
''';
      final result = BulkTextParser.parse(input);
      final person = result.blocks.single.personnelList.single;
      expect(person.rawRank, 'J.Asb.Üçvş.');
      expect(person.rawName, 'Selahattin ÇAKIR');
    });

    test('filters parenthetical location sub-headers and footer instruction notes', () {
      const input = '''
*02.08.2026*
*9/B GÖREV Listesi*
(Altın Kaz çiftliği)
1) J.Asb.Çvş.Ahmet TINAS
*Sabit kalınacak*
''';
      final result = BulkTextParser.parse(input);
      expect(result.blocks.single.personnelList, hasLength(1));
      expect(result.blocks.single.personnelList.single.rawName, 'Ahmet TINAS');
    });

    test('normalizes team format 3B- to 3/B and parses numbering without dot like 10J.Uzm.Çvş.', () {
      const input = '''
3B- 01.08.2026 *Hazır Kıta* İsim Listesi;
10J.Uzm.Çvş. Abdusamed ÖZAĞAÇKAYA
''';
      final result = BulkTextParser.parse(input);
      expect(result.blocks.single.parsedTimName, '3/B');
      expect(result.blocks.single.personnelList.single.rawName, 'Abdusamed ÖZAĞAÇKAYA');
    });
  });
}

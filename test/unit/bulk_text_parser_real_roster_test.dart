import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  test('parses a mixed roster without treating shifts or summaries as people',
      () {
    const input = '''
*30.07.2026*
*10/B Timi Heybet İsim Listesi*
1)J.Asb.Üçvş. Onur GÜNER
7-B Heybet Listesi
30.07.2026 Perşembe
1- J.Asb.Üçvş. Ferdi ERDOĞAN
30.07.2026
2-B Heybet Listesi
1) J.Uzm.Çvş. Abdul Samet HANCI
6/B Heybet listesi
30.07.2026
1-J.Asb.Kd.Üçvş. Ömer Ali DARILMAZ
30.07.2026
11-B Timi hazır kıta İsim Listesi
1) J.Asb.Üçvş. Selahattin ÇAKIR
*30.07.2026*
*9/B Gülüşkür Listesi*
*08:00-19:30 Arası*
1) J.Asb.Çvş.Ahmet TINAS (24 Saat Kalacak)
2)J.Uzm.Çvş.Ramazan BOSTAN
*19:30-06:30 Arası*
3) J.Asb.Çvş.Ahmet TINAS
4)J.Uzm.Çvş.Alperen KARA (24 Saat Kalacak)
TOLAM 3 KİŞİ 2 KİŞİ 24 SAAT KALACAK
30.07.2026
5-B Heybet Listesi
1) J.Ütğm. Okan TOPUZ
2) J.Asb. Çvş.Abdulaziz CAN
''';

    final result = BulkTextParser.parse(input);

    expect(result.hasBlockingIssues, isFalse);
    expect(result.blocks, hasLength(7));
    expect(
      result.blocks.map((block) => block.parsedTimName),
      ['10/B', '7/B', '2/B', '6/B', '11/B', '9/B', '5/B'],
    );
    final guluskur = result.blocks.singleWhere(
      (block) => block.parsedActivityType == DutyOrLeaveType.guluskur,
    );
    expect(guluskur.personnelList, hasLength(4));
    expect(guluskur.parsedTimeRange, isNull);
    expect(
      guluskur.personnelList.where((person) => person.rawName == 'Ahmet TINAS'),
      hasLength(2),
    );
    expect(
      guluskur.personnelList.any(
        (person) => person.rawName.contains('24 Saat'),
      ),
      isFalse,
    );
    expect(result.blocks.last.personnelList.first.rawRank, 'J.Ütğm.');
    expect(result.blocks.last.personnelList.first.rawName, 'Okan TOPUZ');
    expect(result.ignoredLineCount, 5);
  });
}

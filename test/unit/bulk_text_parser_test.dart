import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  test('BulkTextParser should correctly parse sample military text format', () {
    const rawText = '''
6 / B Gülüşkür isim listesi 

25.07.2026  Cumartesi

08.00-19.30

1-J.Asb.üçvş. Erdem BUYAR
2-J.Uzm.Çvş. Erol SARI
3-J.Uzm.Çvş. Abalı Abdullah VURUR
4-J.Uzm.Çvş. Durmuş ÖZKAN

19.30-09.00

1-J.Asb.Kd.Üçvş. Ömer Ali DARILMAZ
2-J.Uzm.Çvş. Furkan DÜNDAR
3-J.Uzm.Çvş. Mehmet YILDIRIM
4-J.Uzm.Çvş. Mehmet Ali ÇAVDAR
7-B Hazır Kıta Listesi

25.07.2026 Cumartesi

1- J.Asb.Üçvş. Ferdi ERDOĞAN
2- J.Uzm.Çvş. Kudret SARIOĞLU
3- J.Uzm.Çvş. Emin SOLUKEL
4- J.Uzm.Çvş. Orhan YENTÜRK
5- J.Uzm.Çvş. Vahit KARACA
6- J.Uzm.Çvş. Sefa YÜCEL
7- J.Uzm.Çvş. Soner SAMUR
8- J.Uzm.Çvş. Mesut KOÇ
9- J.Uzm.Çvş. Seit Abdulveli TÜRKOĞLU
3B- 26.07.2026 *Gülüşkür* İsim Listesi 

08:00/20:00

1-J.Asb.Üçvş. Gökhan GÖKMEN
2-J.Uzm.Çvş. Murat Dursun HÜNERCİ  
3-J.Uzm.Çvş. Nevzat GÜL 
4-J.Uzm.Çvş. Onur ÇELİK 
5-J.Uzm.Çvş. Ömer SAVAŞ 
''';

    final blocks = BulkTextParser.parse(rawText);

    expect(blocks.length, greaterThanOrEqualTo(4));

    // Block 1
    expect(blocks[0].parsedTimName, equals('6/B'));
    expect(blocks[0].parsedActivityType, equals('Gülüşkür'));
    expect(blocks[0].parsedDate, equals('2026-07-25'));
    expect(blocks[0].parsedTimeRange, equals('08:00 - 19:30'));
    expect(blocks[0].personnelList.length, equals(4));
    expect(blocks[0].personnelList[0].rawName, equals('Erdem BUYAR'));
    expect(blocks[0].personnelList[0].rawRank, equals('J.Asb.Üçvş.'));

    // Block 2 (Second Shift)
    expect(blocks[1].parsedTimName, equals('6/B'));
    expect(blocks[1].parsedTimeRange, equals('19:30 - 09:00'));
    expect(blocks[1].personnelList.length, equals(4));

    // Block 3
    expect(blocks[2].parsedTimName, equals('7/B'));
    expect(blocks[2].parsedActivityType, equals('Hazır Kıta'));
    expect(blocks[2].personnelList.length, equals(9));
    expect(blocks[2].personnelList[0].rawName, equals('Ferdi ERDOĞAN'));
  });
}

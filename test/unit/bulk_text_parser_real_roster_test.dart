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
    expect(result.blocks.last.personnelList.first.sourceLineNumber, 27);
    expect(result.ignoredLineCount, 5);
    expect(result.declaredTotals, hasLength(1));
    expect(result.declaredTotals.single.expectedCount, 3);
    expect(result.declaredTotals.single.teamName, '9/B');
  });

  test(
      'parses full user prompt with Turkish text months and unranked personnel names',
      () {
    const input = '''
*30.07.2026*
*10/B Timi Heybet İsim Listesi*

1)J.Asb.Üçvş. Onur GÜNER 
2)J.Uzm.Çvş. Ümit GÜNGÖR 
3)J.Uzm.Çvş. Eyüp ŞERBETÇİ 
4)J.Uzm.Çvş. İrfan AKTAŞ
5)J.Uzm.Çvş. Sefa HANAY
7-B Heybet Listesi

30.07.2026 Perşembe

1- J.Asb.Üçvş. Ferdi ERDOĞAN
2- J.Asb.Çvş. A.Furkan ERYILMAZ
3- J.Uzm.Çvş. Kudret SARIOĞLU
4- J.Uzm.Çvş. Emin SOLUKEL
5- J.Uzm.Çvş. Orhan YENTÜRK
6- J.Uzm.Çvş. Vahit KARACA
7- J.Uzm.Çvş. Sefa YÜCEL
8- J.Uzm.Çvş. Soner SAMUR
9- J.Uzm.Çvş. Mesut KOÇ
10- J.Uzm.Çvş. Seit Abdulveli TÜRKOĞLU
30.07.2026
2-B Heybet Listesi

1) J.Uzm.Çvş. Abdul Samet HANCI
6/B Heybet listesi 

30.07.2026

1-J.Asb.Kd.Üçvş. Ömer Ali DARILMAZ
2-J.Asb.Üçvş. Erdem BUYAR
3-J.Uzm.Çvş. Abalı Abdullah VURUR
4-J.Uzm.Çvş. Mehmet Ali ÇAVDAR
5-J.Uzm.Çvş.Durmuş ÖZKAN
6-J.Uzm.Çvş. Erol SARI
7-J.Uzm.Çvş. Mehmet YILDIRIM
8-J.Uzm.Çvş. Furkan DÜNDAR
30.07.2026

11-B Timi hazır kıta  İsim Listesi

1) J.Asb.Üçvş. Selahattin ÇAKIR
2) J.Asb.Kd.Çvş. İrfan ATEN
3) J.Uzm.Çvş. Ufuk Erdem SEVİNÇ 
4) J.Uzm.Çvş. Bilal AYKIZ 
5) J.Uzm.Çvş. Hüseyin ORUCTUTAN  
6) J.Uzm.Çvş. Yunus KÖSE 
7) J.Uzm.Çvş. Cihat ÇELİK
8) J.Uzm.Çvş. Ercan ÖZEN
9) J.Uzm.Çvş. Yusuf TUŞ
10. J.Uzm.Çvş. Mesut ÇELİK
*30.07.2026*
*9/B Gülüşkür Listesi* 

*08:00-19:30 Arası*

1) J.Asb.Çvş.Ahmet TINAS (24 Saat Kalacak)
2)J.Uzm.Çvş.Ramazan BOSTAN
3) J.Uzm.Çvş.M.Delil KARAKEÇİ
4)J.Uzm.Çvş.Ergin Dinç 
5)J.Uzm.Çvş.Alperen KARA (24 Saat Kalacak)

*19:30-06:30 Arası*
6) J.Asb.Çvş.Ahmet TINAS
7)  J.Uzm.Çvş. Hüseyin KILIÇ
8) J.Uzm.Çvş.Nuri MENEVŞE
9) J.Uzm.Çvş Abdullah ÖZDEMİR
10) J.Uzm.Çvş.Uğur Can UYSAL
11)J.Uzm.Çvş.Alperen KARA (24 Saat Kalacak)
TOLAM 9 KİŞİ 2 KİŞİ 24 SAAT KALACAK
30.07.2026
5-B Heybet Listesi

1) J.Ütğm. Okan TOPUZ
2) J.Asb. Çvş.Abdulaziz CAN
3) J.Uzm.Çvş İsmail KAYA
4) J.Uzm.Çvş Erdal AKBAL
5) J.Uzm Çvş Hakan ÖZYAŞAR
6) J.Uzm.Çvş Selami CON
7) J.Uzm.Çvş. Mehmet Akif Köroğlu
8) J.Uzm.Çvş. Mustafa KARAKUYU
9) J.Uzm.Çvş. Cabir DENİZ
10) J.Uzm.Çvş. Erhan KARAOĞLAN

31 temmuz 2026

Oğuzhan ayaz
31 Temmuz Heybet
Ferhat Ayyıldız
31 temmuz  heybet
Nuri demir
''';

    final result = BulkTextParser.parse(input);

    expect(result.blocks.first.parsedTimName, '10/B');
    expect(result.blocks.first.personnelList, hasLength(5));

    final july31Block = result.blocks.firstWhere(
      (b) => b.parsedDate == '2026-07-31',
    );
    expect(july31Block.parsedActivityType, DutyOrLeaveType.heybet);
    expect(
      july31Block.personnelList.map((p) => p.rawName),
      containsAll(['Oğuzhan ayaz', 'Ferhat Ayyıldız', 'Nuri demir']),
    );
  });

  test('ignores invisible unicode format chars around the first date line', () {
    // WhatsApp kopyalarında satır başına/sonuna yapışan görünmez karakterler:
    // U+200E (LRM), U+200B (ZWSP), U+FEFF (BOM/ZWNBSP).
    const input = '\u200E*30.07.2026*\u200B\n'
        '*10/B Timi Heybet İsim Listesi*\n'
        '1)J.Asb.Üçvş. Onur GÜNER\n'
        '7-B Heybet Listesi\n'
        '30.07.2026 Perşembe\n'
        '1- J.Asb.Üçvş. Ferdi ERDOĞAN\n';

    final result = BulkTextParser.parse(input);

    expect(result.hasBlockingIssues, isFalse);
    expect(result.blocks, hasLength(2));
    expect(
      result.blocks.map((block) => block.parsedDate),
      everyElement('2026-07-30'),
    );
  });

  test('parses chaotic date, shift and unranked-name combinations safely', () {
    const input = '''
06 Ağustos 2026
Muhammed Ali Yakar
06 Ağustos heybet
Recep göral
Ferhat Ayyıldız
İlyas Teksan
06 AĞUSTOS 2026

AHMET MUSTAFA ÇALIŞKAN
OĞUZHAN AYAZ
SABAH
6 Ağustos

Ferhat AKKEŞ

Sabah
6 ağustos heybet

Serdar AÇIKGÖZ
Mehmet AKDOĞAN

Sabah
6 Ağustos Heybet
Hasan Akbaş
06 Ağustos
Recai KAYA
Akşam heybet
Nuri demir akşam
5 ağustos heybet
Mahmut DEMİRBAŞ
Serdar AÇIKGÖZ
Mehmet AKDOĞAN
Recai KAYA
17.30
05 AĞUSTOS 2026

AHMET MUSTAFA ÇALIŞKAN
OĞUZHAN AYAZ
05 Ağustos heybet
Recep göral
Ferhat Ayyıldız
5 Ağustos Hasan Akbaş
5 Ağustos Muhammet GÜRDEN
5 Ağustos Penah Can İŞLEK
Nuri demir
akşam
''';

    final result = BulkTextParser.parse(input);
    final names = result.blocks
        .expand((block) => block.personnelList)
        .map((person) => person.rawName)
        .toList();

    expect(result.blocks.map((block) => block.parsedDate).toSet(), {
      '2026-08-05',
      '2026-08-06',
    });
    expect(
      names,
      containsAll(<String>[
        'Muhammed Ali Yakar',
        'AHMET MUSTAFA ÇALIŞKAN',
        'Ferhat AKKEŞ',
        'Nuri demir',
        'Hasan Akbaş',
        'Muhammet GÜRDEN',
        'Penah Can İŞLEK',
      ]),
    );
    expect(names, isNot(contains('SABAH')));
    expect(names, isNot(contains('Sabah')));
    expect(names, isNot(contains('akşam')));
    expect(names, isNot(contains('17.30')));
    expect(names.any((name) => name.contains('Ağustos')), isFalse);
    expect(names.any((name) => name.toLowerCase().endsWith(' akşam')), isFalse);
  });

  test(
      'preserves Turkish dates while extracting names from inline date and shift text',
      () {
    const input = '''
05 AĞUSTOS 2026
2/B Heybet Listesi
AHMET MUSTAFA ÇALIŞKAN
OĞUZHAN AYAZ
5 Ağustos Hasan Akbaş
5 Ağustos Muhammet GÜRDEN
Nuri Demir AKŞAM
Sabah

06 AĞUSTOS 2026
2/B Heybet Listesi
Muhammed Ali YAKAR
Recep Göral
İlyas Teksan AKŞAM
''';

    final result = BulkTextParser.parse(input);

    expect(result.hasBlockingIssues, isFalse);
    expect(result.blocks, hasLength(2));

    final august5 = result.blocks.singleWhere(
      (block) => block.parsedDate == '2026-08-05',
    );
    expect(august5.parsedTimName, '2/B');
    expect(august5.parsedActivityType, DutyOrLeaveType.heybet);
    expect(
      august5.personnelList.map((person) => person.rawName),
      [
        'AHMET MUSTAFA ÇALIŞKAN',
        'OĞUZHAN AYAZ',
        'Hasan Akbaş',
        'Muhammet GÜRDEN',
        'Nuri Demir',
      ],
    );

    final august6 = result.blocks.singleWhere(
      (block) => block.parsedDate == '2026-08-06',
    );
    expect(august6.parsedTimName, '2/B');
    expect(august6.parsedActivityType, DutyOrLeaveType.heybet);
    expect(
      august6.personnelList.map((person) => person.rawName),
      ['Muhammed Ali YAKAR', 'Recep Göral', 'İlyas Teksan'],
    );

    final allNames = result.blocks
        .expand((block) => block.personnelList)
        .map((person) => person.rawName)
        .toList();
    expect(allNames, isNot(contains('Sabah')));
    expect(allNames.any((name) => name.contains('Ağustos')), isFalse);
    expect(
      allNames.any((name) => name.toUpperCase().endsWith(' AKŞAM')),
      isFalse,
    );
  });
}

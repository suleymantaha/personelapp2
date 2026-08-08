import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  test('parse full user request text cleanly without issues', () {
    const input = '''
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
6/B Görev (Adliye) listesi 

30.07.2026

1-J.Asb.Kd.Üçvş. Ömer Ali DARILMAZ
2-J.Asb.Üçvş. Erdem BUYAR
3-J.Uzm.Çvş. Abalı Abdullah VURUR
4-J.Uzm.Çvş. Mehmet Ali ÇAVDAR
5-J.Uzm.Çvş.Durmuş ÖZKAN
6-J.Uzm.Çvş. Erol SARI
7-J.Uzm.Çvş. Mehmet YILDIRIM
8-J.Uzm.Çvş. Furkan DÜNDAR
*30.07.2026*
*10/B Timi  Altın Kaz Çiftliği Görev İsim Listesi*

1)J.Asb.Üçvş. Onur GÜNER 
2)J.Asb.Üçvş. Göker KIZILIRMAK
3)J.Uzm.Çvş. Eyüp ŞERBETÇİ 
4)J.Uzm.Çvş. Emre SARI
5)J.Uzm.Çvş. Kerem AKSU
6)J.Uzm.Çvş. İrfan AKTAŞ 
7)J.Uzm.Çvş. Ümit GÜNGÖR 
8)J.Uzm.Çvş. Harun KARABACAK 
9)J.Uzm.Çvş. Sefa HANAY
31.07.2026
5-B Hazır Kıta Listesi

1) J.Asb. Çvş.Abdulaziz CAN
2) J.Uzm.Çvş İsmail KAYA
3) J.Uzm.Çvş Erhan KARAOĞLAN
4) J.Uzm Çvş Hakan ÖZYAŞAR
5) J.Uzm.Çvş Selami CON
6) J.Uzm.Çvş. Mehmet Akif Köroğlu
7) J.Uzm.Çvş. Mustafa KARAKUYU
8) J.Uzm.Çvş. Cabir DENİZ
7-B Görev İsim Listesi (Altınkaz Kaz Çiftliği)

31.07.2026 Cuma

1- J.Asb.Üçvş. Ferdi ERDOĞAN
2- J.Uzm.Çvş. Kudret SARIOĞLU
3- J.Uzm.Çvş. Emin SOLUKEL
4- J.Uzm.Çvş. Orhan YENTÜRK
5- J.Uzm.Çvş. Vahit KARACA
6- J.Uzm.Çvş. Sefa YÜCEL
7- J.Uzm.Çvş. Soner SAMUR
8- J.Uzm.Çvş. Mesut KOÇ
6/B Gülüşkür isim listesi 

31.07.2026  Cuma

08.00-19.30

1-J.Asb.Kd.Üçvş. Ömer Ali DARILMAZ
2-J.Uzm.Çvş. Furkan DÜNDAR
3-J.Uzm.Çvş. Mehmet YILDIRIM
4-J.Uzm.Çvş. Mehmet Ali ÇAVDAR
5-J.Uzm.Çvş. Kenan KAYAPINAR

19.30-09.00

1-J.Asb.üçvş. Erdem BUYAR
2-J.Uzm.Çvş. Erol SARI
3-J.Uzm.Çvş. Abalı Abdullah VURUR
4-J.Uzm.Çvş. Durmuş ÖZKAN
*02.08.2026*
*10/B Timi Hazır Kıta İsim Listesi*

1)J.Asb.Üçvş. Onur GÜNER 
2)J.Asb.Üçvş. Göker KIZILIRMAK
3)J.Uzm.Çvş. Eyüp ŞERBETÇİ 
4)J.Uzm.Çvş. Emre SARI
5)J.Uzm.Çvş. Kerem AKSU
6)J.Uzm.Çvş. İrfan AKTAŞ 
7)J.Uzm.Çvş. Ümit GÜNGÖR 
8)J.Uzm.Çvş. Harun KARABACAK
9)J.Uzm.Çvş. Ömer KARACAOĞLU
10)J.Uzm.Çvş. Sefa HANAY
*01.08.2026*
*1/B İhtiyat Listesi*

1- J.Asb.Üçvş. Ali CENGİZ
2- J.Uzm.Çvş. Mehmet KAYA
3- J.Uzm.Çvş. Mehmet LELİK
4- J.Uzm.Çvş. Koray UÇAR
5- J.Uzm.Çvş. Kemal ÖZCAN
6- J.Uzm.Çvş. Mehmet BİLEK
7- J.Uzm.Çvş. Harun Reşit GÜRDAL
8- J.Uzm.Çvş.Ferdi AKAR
*11-B Timi Gülüşkür İsim  Listesi*

02.08.2026

08:00 20:00

1.J.Asb.Ü.Çvş. Selahattin ÇAKIR
2.J.Uzm.Çvş. Ufuk Erdem SEVİNÇ
3.J.Uzm.Çvş.Bilal AYKIZ
4.J.Uzm.Çvş.Hüseyin ORUÇTUTAN
5.J.Uzm.Çvş.Mesut ÇELİK 

20:00 08:00 

1.J.Asb.Kd.Çvş. İrfan ATEN
2.J.Uzm.Çvş. Yunus KÖSE
3.J.Uzm.Çvş. Cihat ÇELİK
4.J.Uzm.Çvş. Ercan ÖZEN
5. J.Uzm.Çvş. Yusuf TUŞ 6.J.Uzm.Çvş. Ertuğrul BAĞCI
*02.08.2026*
*9/B GÖREV  Listesi*
(Altın Kaz çiftliği)
1) J.Asb.Çvş.Ahmet TINAS
2) J.Uzm.Çvş.Uğur Can UYSAL
3) J.Uzm.Çvş.Nuri MENEVŞE
4) J.Uzm.Çvş. Ergin DİNÇ
5)J.Uzm.Çvş.Alperen KARA
6)J.Uzm.Çvş.Hüseyin KILIÇ
7)J.Uzm Çvş.Abdullah ÖZDEMİR
8)J.Uzm.Çvş.M.Delil KARAKEÇİ
*01.08.2026*

*1/B Görev İsim Listesi (Altın Kaz Çiftliği)*

1- J.Asb.Üçvş. Ali CENGİZ
2- J.Uzm.Çvş. Mehmet KAYA
3- J.Uzm.Çvş. Mehmet LELİK
4- J.Uzm.Çvş. Koray UÇAR
5- J.Uzm.Çvş. Kemal ÖZCAN
6- J.Uzm.Çvş. Mehmet BİLEK
7- J.Uzm.Çvş. Harun Reşit GÜRDAL
8- J.Uzm.Çvş.Ferdi AKAR
03.08.2026
5-B Görev (Altınkaz Çiftliği İsim Listesi)

1) J.Asb. Çvş.Abdulaziz CAN
2) J.Uzm.Çvş İsmail KAYA
3) J.Uzm.Çvş Erhan KARAOĞLAN
4) J.Uzm Çvş Hakan ÖZYAŞAR
5) J.Uzm.Çvş Selami CON
6) J.Uzm.Çvş. Mehmet Akif Köroğlu
7) J.Uzm.Çvş. Mustafa KARAKUYU
8) J.Uzm.Çvş. Cabir DENİZ
3B- 01.08.2026 *Hazır Kıta* İsim Listesi;

1-J.Asb.Üçvş. Gökhan GÖKMEN
2-J.Uzm.Çvş.Murat D. HÜNERCİ  
3- J.Uzm.Çvş.Nevzat GÜL 
4-J.Uzm.Çvş.Onur ÇELİK 
5-J.Uzm.Çvş.Ömer SAVAŞ 
 6-J.Uzm.Çvş. Uğur ÇAVDAR 
7-J.Uzm.Çvş. Furkan KOÇ
8-J.Uzm.Çvş.Yasin MİRİK 
9-J.Uzm.Cvş. Erhan AYHAN
10J.Uzm.Çvş. Abdusamed ÖZAĞAÇKAYA
11-J.Uzm.Çvş. Mustafa ÇALIŞKAN
03.08.2026 
6/B Hazır kıta isim listesi 

1-J.Asb.Kd.Üçvş Ömer Ali DARILMAZ 
2-J.Asb.Üçvş. Erdem BUYAR
3-J.Uzm.Çvş. Furkan DÜNDAR
4-J.Uzm.Çvş. Mehmet YILDIRIM
5-J.Uzm.Çvş. Durmuş ÖZKAN
6-J.Uzm.Çvş. Erol SARI
7-J.Uzm.Çvş. A.Abdullah VURUR
8-J.Uzm.Çvş. Mehmet Ali ÇAVDAR
9-J.Uzm.Çvş. Kenan KAYAPINAR
03.08.2026
2 Bölük Heybet Listesi
1) J.Ütğm Okan TOPUZ
7-B Gülüşkür Listesi

03.08.2026 Pazartesi

08.00-20.00
1- J.Asb.Üçvş. Ferdi ERDOĞAN
2- J.Uzm.Çvş. Kudret SARIOĞLU
3- J.Uzm.Çvş. Emin SOLUKEL
4- J.Uzm.Çvş. Orhan YENTÜRK
5- J.Uzm.Çvş. Vahit KARACA

20.00-09.00
1-  J.Asb.Üçvş. Ferdi ERDOĞAN
2- J.Uzm.Çvş. Sefa YÜCEL
3- J.Uzm.Çvş. Soner SAMUR
4- J.Uzm.Çvş. Mesut KOÇ
5- J.Uzm.Çvş. Seit Abdulveli TÜRKOĞLU
*03.08.2026*

*1/B Heybet Listesi*

1- J.Ütğm.Mehmet CEYLAN 
2- J.Asb.Üçvş. Ali CENGİZ
3- J.Uzm.Çvş. Koray UÇAR
4- J.Uzm.Çvş. Kemal ÖZCAN
5- J.Uzm.Çvş. Mehmet BİLEK
6- J.Uzm.Çvş. Harun Reşit GÜRDAL
7- J.Uzm.Çvş.Ferdi AKAR
01.08.2026
2-B Gülüşkür Listesi

1) J.Tğm. Anılcan ÇİFTÇİ
2) J.Asb.Üçvş. Yasin Ömer ATABAY
3) J.Uzm.Çvş. Kemal ÜNAL
4) J.Uzm.Çvş. Ali TOPAL
5) J.Uzm.Çvş. Emre GÜNGÖR
6) J.Uzm.Çvş. AbdülKerim TUT
7) J.Uzm.Çvş. Turan KAFFAR

       *Sabit kalınacak*
''';

    final result = BulkTextParser.parse(input);

    expect(result.hasBlockingIssues, isFalse);
    expect(result.issues, isEmpty);
    expect(result.blocks, hasLength(19));

    final team3bPersonnel = result.blocks
        .where((b) => b.parsedTimName == '3B')
        .expand((b) => b.personnelList)
        .toList();
    expect(
      team3bPersonnel.any((p) => p.rawName == 'Abdusamed ÖZAĞAÇKAYA'),
      isTrue,
    );

    // Verify multi-personnel single-line splitting (Yusuf TUŞ & Ertuğrul BAĞCI)
    final tim11GuluskurPersonnel = result.blocks
        .where((b) => b.parsedTimName == '11/B' && b.parsedActivityType == DutyOrLeaveType.guluskur)
        .expand((b) => b.personnelList)
        .toList();
    expect(tim11GuluskurPersonnel, hasLength(11));
    expect(
      tim11GuluskurPersonnel.any((p) => p.rawName == 'Yusuf TUŞ'),
      isTrue,
    );
    expect(
      tim11GuluskurPersonnel.any((p) => p.rawName == 'Ertuğrul BAĞCI'),
      isTrue,
    );

    // Verify parenthetical location note (Altın Kaz çiftliği) is filtered
    final aug2Task = result.blocks.firstWhere(
      (b) => b.parsedDate == '2026-08-02',
    );
    expect(aug2Task.personnelList.length, greaterThanOrEqualTo(8));

    // Verify footer note (*Sabit kalınacak*) is filtered
    final aug1Guluskur = result.blocks.firstWhere(
      (b) => b.parsedDate.contains('01.08') || b.parsedDate.contains('2026-08-01'),
    );
    expect(aug1Guluskur.personnelList.length, greaterThanOrEqualTo(7));
  });

  test('parse multi-date bottom-labeled duty list into separate cards', () {
    const input = '''
Hüseyin Ermumcu
Erdal Karataş
03 AĞUSTOS 2026

AHMET MUSTAFA ÇALIŞKAN
OĞUZHAN AYAZ
Nuri demir
03 Ağustos heybet 
Recep göral
Ferhat Ayyıldız
İlyas Tekşan
3 Ağustos Heybet 
Serdar AÇIKGÖZ
3 agustos 
Hasan akbaş
04 AĞUSTOS 2026

AHMET MUSTAFA ÇALIŞKAN
OĞUZHAN AYAZ
4 Ağustos Heybet 
Muhammet GÜRDEN
04 Ağustos heybet 
Recep göral
Ferhat Ayyıldız
İlyas Tekşan
04 Ağustos heybet 
Mahmut DEMİRBAŞ 
Mehmet AKDOĞAN
4 ağustos heybet
Serdar AÇIKGÖZ
4 ağustos heybet
Penah Can İŞLEK
Hüseyin Ermumcu
Erdal Karataş
5 ağustos heybet
Mahmut DEMİRBAŞ
Serdar AÇIKGÖZ
Mehmet AKDOĞAN
05 AĞUSTOS 2026

AHMET MUSTAFA ÇALIŞKAN
OĞUZHAN AYAZ
05 Ağustos heybet 
Recep göral
Ferhat Ayyıldız
5 Ağustos Hasan Akbaş
5 Ağustos Muhammet GÜRDEN
5 Ağustos Penah Can İŞLEK
5 Ağustos 🖐️
Hüseyin Ermumcu 
Erdal Karataş
Nuri demir 
akşam
06 Ağustos 2026
Muhammed Ali Yakar
06 Ağustos heybet 
Recep göral
Ferhat Ayyıldız
İlyas Teksan
06 AĞUSTOS 2026

AHMET MUSTAFA ÇALIŞKAN
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
7 ağustos Heybet

Muhammed Ali YAKAR
Serdar AÇIKGÖZ
Mehmet AKDOĞAN

SABAH
07 AĞUSTOS 2026

AHMET MUSTAFA ÇALIŞKAN
OĞUZHAN AYAZ
07 AĞUSTOS Heybet 
Hasan Akbaş
07 Ağustos heybet
Atilla Çeliker
Recep Göral
İlyas Teksan
Ferhat Ayyıldız
Nuri demir AKŞAM
7 Ağustos 
Ferhat AKKEŞ 
Sabah
''';

    final result = BulkTextParser.parse(input);
    expect(result.blocks.length, greaterThanOrEqualTo(10));
  });
}

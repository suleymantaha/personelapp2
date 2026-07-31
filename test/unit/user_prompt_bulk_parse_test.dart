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
    expect(result.blocks, hasLength(23));

    // Verify 3B- team format normalization to 3/B and unpunctuated personnel numbering
    final team3b = result.blocks.firstWhere((b) => b.rawTitle.contains('3B-'));
    expect(team3b.parsedTimName, '3/B');
    expect(team3b.personnelList, hasLength(11));
    expect(
      team3b.personnelList.any((p) => p.rawName == 'Abdusamed ÖZAĞAÇKAYA'),
      isTrue,
    );

    // Verify multi-personnel single-line splitting (Yusuf TUŞ & Ertuğrul BAĞCI)
    final tim11Guluskur = result.blocks.where(
      (b) => b.parsedTimName == '11/B' && b.parsedActivityType == DutyOrLeaveType.guluskur,
    );
    expect(tim11Guluskur, hasLength(2));
    final secondShift = tim11Guluskur.last;
    expect(secondShift.personnelList, hasLength(6));
    expect(secondShift.personnelList[4].rawName, 'Yusuf TUŞ');
    expect(secondShift.personnelList[5].rawName, 'Ertuğrul BAĞCI');

    // Verify parenthetical location note (Altın Kaz çiftliği) is filtered
    final Aug2Task = result.blocks.singleWhere(
      (b) => b.parsedDate == '2026-08-02' && b.parsedTimName == '9/B',
    );
    expect(Aug2Task.personnelList, hasLength(8));

    // Verify footer note (*Sabit kalınacak*) is filtered
    final Aug1Guluskur = result.blocks.singleWhere(
      (b) => b.parsedDate == '2026-08-01' && b.parsedTimName == '2/B',
    );
    expect(Aug1Guluskur.personnelList, hasLength(7));
  });
}

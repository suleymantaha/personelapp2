import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  group('Raw User Text Import Test', () {
    test('should parse complex multi-date text without critical errors', () {
      const rawText = '''
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

      final result = BulkTextParser.parse(rawText);

      expect(result.blocks, isNotEmpty);
      if (kDebugMode) {
        print('Total blocks parsed: ${result.blocks.length}');
      }
      if (kDebugMode) {
        print('Issues count: ${result.issues.length}');
      }
      for (var i = 0; i < result.blocks.length; i++) {
        final b = result.blocks[i];
        if (kDebugMode) {
          print(
          'Block ${i + 1}: Date="${b.parsedDate}", Duty="${b.parsedActivityType}", PersonnelCount=${b.personnelList.length}',
        );
        }
        for (final p in b.personnelList) {
          if (kDebugMode) {
            print('   - Person: ${p.rawName}');
          }
        }
      }

      for (final issue in result.issues) {
        if (kDebugMode) {
          print('Issue L${issue.lineNumber}: [${issue.code}] ${issue.message}');
        }
      }
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/ocr/roster_ocr_name_extractor.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  group('RosterOcrNameExtractor', () {
    test('extracts names from an Excel roster screenshot OCR dump', () {
      const rawText = '''
14.08.2026 TARİHLİ HEYBET / NÖBET GÖREVLİ İSİM ÇİZELGESİ
S.NU RÜTBESİ ADI SOYADI AÇIKLAMALAR
1 J.Uzm.Çvş. Kerem KOYUNCU GARAJ NÖB.
2 J.Uzm.Çvş. Saffet ÇİMEN TTZA NÖB
3 J.Asb.Üçvş. Tuncay AKTAŞ SABAH
4 J.Uzm.Çvş. Bünyamin ÖZKARTAL SABAH
5 J.Uzm.Çvş. Adil Ümit AKTAR SABAH
Sayfa 1
''';

      final result = RosterOcrNameExtractor.extract(rawText);

      expect(result.names.map((name) => name.rawName), [
        'Kerem KOYUNCU',
        'Saffet ÇİMEN',
        'Tuncay AKTAŞ',
        'Bünyamin ÖZKARTAL',
        'Adil Ümit AKTAR',
      ]);
      expect(result.defaultDate, '2026-08-14');
      expect(result.names.first.activityHint, 'GARAJ NÖB.');
      expect(result.names[1].activityHint, 'TTZA NÖB.');
      expect(result.names[2].activityHint, 'SABAH');
      expect(result.names.every((name) => name.rawName != 'Sayfa'), isTrue);

      final parsed = BulkTextParser.parse(result.toBulkImportText());
      expect(parsed.blocks.map((block) => block.parsedActivityType), [
        DutyOrLeaveType.garajNob,
        DutyOrLeaveType.ttzaNob,
        DutyOrLeaveType.heybet,
      ]);
      expect(parsed.blocks.expand((block) => block.personnelList).length, 5);
      expect(parsed.hasBlockingIssues, isFalse);
    });

    test('extracts visible names even when date and duty are absent', () {
      const rawText = '''
WhatsApp Image
AYKUT AKCAN
Coşkun POSTLU
Halil İbrahim ÖNEN
Erkan KARCI
''';

      final result = RosterOcrNameExtractor.extract(rawText);

      expect(result.defaultDate, isNull);
      expect(result.names.map((name) => name.rawName), [
        'AYKUT AKCAN',
        'Coşkun POSTLU',
        'Halil İbrahim ÖNEN',
        'Erkan KARCI',
      ]);
      expect(result.names.every((name) => name.activityHint == null), isTrue);

      final parsed = BulkTextParser.parse(result.toBulkImportText());
      expect(parsed.blocks.single.personnelList, hasLength(4));
      expect(
          parsed.issues.map((issue) => issue.code), contains('missing_date'));
      expect(parsed.hasBlockingIssues, isTrue);
    });

    test('does not treat roster labels and shifts as personnel', () {
      const rawText = '''
ADI SOYADI
AÇIKLAMALAR
SABAH
GARAJ NÖB.
TTZA NÖB
RÜTBESİ
Sayfa 1
''';

      final result = RosterOcrNameExtractor.extract(rawText);

      expect(result.names, isEmpty);
      expect(result.ignoredLineCount, greaterThan(0));
    });
  });
}

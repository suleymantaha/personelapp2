import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/ocr/roster_ocr_name_extractor.dart';

void main() {
  group('RosterOcrNameExtractor Hard Cases', () {
    test('extracts personnel with military branch prefixes (J.Per.Asb.Kd.Üçvş.)', () {
      const rawText = '''
14.08.2026 GÖREVLİ İSİM LİSTESİ
1 J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN SABAH
2 J.İkm.Uzm.Çvş. Kemal DEMİR GARAJ NÖB.
''';

      final result = RosterOcrNameExtractor.extract(rawText);

      expect(result.names, hasLength(2));
      expect(result.names.first.rawName, equals('Ahmet Mustafa ÇALIŞKAN'));
      expect(result.names.first.rawRank, equals('J.Asb.Kd.Üçvş.'));
      expect(result.names[1].rawName, equals('Kemal DEMİR'));
      expect(result.names[1].rawRank, equals('J.Uzm.Çvş.'));
    });

    test('recovers personnel names when OCR confuses digits (0sman KAYA -> Osman KAYA)', () {
      const rawText = '''
1. 0sman KAYA SABAH
2. Ahmet Y1LMAZ AKŞAM
''';

      final result = RosterOcrNameExtractor.extract(rawText);

      expect(result.names, hasLength(2));
      expect(result.names.first.rawName, equals('Osman KAYA'));
      expect(result.names[1].rawName, equals('Ahmet YILMAZ'));
    });

    test('stitches split personnel lines across rows (First Name + Last Name)', () {
      const rawText = '''
1. J.Uzm.Çvş. Ali İhsan
KORKMAZ
2. J.Asb.Kd.Çvş. Mehmet
KAYA
''';

      final result = RosterOcrNameExtractor.extract(rawText);

      expect(result.names, hasLength(2));
      expect(result.names.first.rawName, equals('Ali İhsan KORKMAZ'));
      expect(result.names.first.rawRank, equals('J.Uzm.Çvş.'));
      expect(result.names[1].rawName, equals('Mehmet KAYA'));
      expect(result.names[1].rawRank, equals('J.Asb.Kd.Çvş.'));
    });
  });
}

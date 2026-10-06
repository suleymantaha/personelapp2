import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/military_rank_normalizer.dart';

void main() {
  group('MilitaryRankNormalizer', () {
    test('extracts rank and name for branch-prefixed ranks like J.Per.Asb.Kd.Üçvş.', () {
      final parsed = MilitaryRankNormalizer.extractRankAndName(
        'J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN',
      );

      expect(parsed.standardRank, equals('J.Asb.Kd.Üçvş.'));
      expect(parsed.cleanName, equals('Ahmet Mustafa ÇALIŞKAN'));
      expect(parsed.rawRank, equals('J.Per.Asb.Kd.Üçvş.'));
    });

    test('extracts various military branches correctly', () {
      final cases = [
        ('J.İkm.Asb.Bçvş. Mehmet YILMAZ', 'J.Asb.Bçvş.', 'Mehmet YILMAZ'),
        ('J.Mu.Asb.Kd.Çvş. Ali KAYA', 'J.Asb.Kd.Çvş.', 'Ali KAYA'),
        ('J.Bkm.Uzm.Çvş. Hasan DEMİR', 'J.Uzm.Çvş.', 'Hasan DEMİR'),
        ('J.Asyş.Tğm. Burak CAN', 'J.Tğm.', 'Burak CAN'),
        ('J.İst.Ütğm. Murat POLAT', 'J.Ütğm.', 'Murat POLAT'),
        ('J.Mly.Astğm. Caner AKIN', 'J.Astğm.', 'Caner AKIN'),
        ('J.Tbp.Bnb. Dr. Serkan ÖZ', 'J.Bnb.', 'Dr. Serkan ÖZ'),
        ('J.Uzm.Çvş. Ferhat KORKMAZ', 'J.Uzm.Çvş.', 'Ferhat KORKMAZ'),
      ];

      for (final (input, expectedRank, expectedName) in cases) {
        final res = MilitaryRankNormalizer.extractRankAndName(input);
        expect(res.standardRank, equals(expectedRank), reason: 'Failed for rank of: $input');
        expect(res.cleanName, equals(expectedName), reason: 'Failed for name of: $input');
      }
    });

    test('strips leading line numbers, bullets and delimiters before parsing', () {
      final cases = [
        ('1. J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN', 'J.Asb.Kd.Üçvş.', 'Ahmet Mustafa ÇALIŞKAN'),
        ('| 02 | J.Uzm.Çvş. Kemal AK', 'J.Uzm.Çvş.', 'Kemal AK'),
        ('3- J.Asb.Çvş. Selim KOÇ', 'J.Asb.Çvş.', 'Selim KOÇ'),
        ('4) J.İkm.Asb.Üçvş. Ömer FARUK', 'J.Asb.Üçvş.', 'Ömer FARUK'),
      ];

      for (final (input, expectedRank, expectedName) in cases) {
        final res = MilitaryRankNormalizer.extractRankAndName(input);
        expect(res.standardRank, equals(expectedRank));
        expect(res.cleanName, equals(expectedName));
      }
    });

    test('returns null standardRank and full cleanName when no rank is present', () {
      final res = MilitaryRankNormalizer.extractRankAndName('Ahmet Mustafa ÇALIŞKAN');
      expect(res.standardRank, isNull);
      expect(res.cleanName, equals('Ahmet Mustafa ÇALIŞKAN'));
    });

    test('corrects OCR digit substitutions inside words', () {
      expect(MilitaryRankNormalizer.cleanOcrDigits('0sman KAYA'), equals('Osman KAYA'));
      expect(MilitaryRankNormalizer.cleanOcrDigits('Ahmet Y1LMAZ'), equals('Ahmet YILMAZ'));
      expect(MilitaryRankNormalizer.cleanOcrDigits('5alih DEMİR'), equals('Salih DEMİR'));
      expect(MilitaryRankNormalizer.cleanOcrDigits('Kerem K0YUNCU'), equals('Kerem KOYUNCU'));
      // Standalone numbers (e.g. sequence numbers) should not be altered
      expect(MilitaryRankNormalizer.cleanOcrDigits('1. Ahmet YILMAZ'), equals('1. Ahmet YILMAZ'));
    });
  });
}

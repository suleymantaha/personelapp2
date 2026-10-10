import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/turkish_date_helper.dart';

void main() {
  group('TurkishDateHelper Month Operations', () {
    test('parseMonthNumber parses variations of Turkish months', () {
      expect(TurkishDateHelper.parseMonthNumber('Ocak'), 1);
      expect(TurkishDateHelper.parseMonthNumber('ocak'), 1);
      expect(TurkishDateHelper.parseMonthNumber('1'), 1);
      expect(TurkishDateHelper.parseMonthNumber('01'), 1);
      expect(TurkishDateHelper.parseMonthNumber('oca'), 1);

      // Türkçe karakter dönüşümleri
      expect(TurkishDateHelper.parseMonthNumber('şubat'), 2);
      expect(TurkishDateHelper.parseMonthNumber('subat'), 2);
      expect(TurkishDateHelper.parseMonthNumber('SUBAT'), 2);

      expect(TurkishDateHelper.parseMonthNumber('ağustos'), 8);
      expect(TurkishDateHelper.parseMonthNumber('agustos'), 8);
      expect(TurkishDateHelper.parseMonthNumber('AGUSTOS'), 8);
      expect(TurkishDateHelper.parseMonthNumber('ağu'), 8);
      expect(TurkishDateHelper.parseMonthNumber('agu'), 8);
      expect(TurkishDateHelper.parseMonthNumber('08'), 8);

      expect(TurkishDateHelper.parseMonthNumber('eylül'), 9);
      expect(TurkishDateHelper.parseMonthNumber('eylul'), 9);

      expect(TurkishDateHelper.parseMonthNumber('kasım'), 11);
      expect(TurkishDateHelper.parseMonthNumber('kasim'), 11);

      expect(TurkishDateHelper.parseMonthNumber('aralık'), 12);
      expect(TurkishDateHelper.parseMonthNumber('aralik'), 12);

      expect(TurkishDateHelper.parseMonthNumber('geçersiz'), isNull);
      expect(TurkishDateHelper.parseMonthNumber(''), isNull);
      expect(TurkishDateHelper.parseMonthNumber(null), isNull);
    });

    test('getMonthName returns proper standard, uppercase, short and military formats', () {
      expect(TurkishDateHelper.getMonthName(1), 'Ocak');
      expect(TurkishDateHelper.getMonthName(1, uppercase: true), 'OCAK');
      expect(TurkishDateHelper.getMonthName(1, short: true), 'Oca');
      expect(TurkishDateHelper.getMonthName(1, military: true), 'OCA');

      expect(TurkishDateHelper.getMonthName(8), 'Ağustos');
      expect(TurkishDateHelper.getMonthName(8, uppercase: true), 'AĞUSTOS');
      expect(TurkishDateHelper.getMonthName(8, short: true), 'Ağu');
      expect(TurkishDateHelper.getMonthName(8, military: true), 'AGU');

      expect(TurkishDateHelper.getMonthName(12), 'Aralık');
      expect(TurkishDateHelper.getMonthName(12, uppercase: true), 'ARALIK');
      expect(TurkishDateHelper.getMonthName(12, military: true), 'ARA');

      expect(TurkishDateHelper.getMonthName(0), '');
      expect(TurkishDateHelper.getMonthName(13), '');
    });

    test('normalizeMonth normalizes messy user input', () {
      expect(TurkishDateHelper.normalizeMonth('agustos'), 'Ağustos');
      expect(TurkishDateHelper.normalizeMonth('AGUSTOS', uppercase: true), 'AĞUSTOS');
      expect(TurkishDateHelper.normalizeMonth('kasim', short: true), 'Kas');
      expect(TurkishDateHelper.normalizeMonth('subat', military: true), 'ŞUB');
    });
  });

  group('TurkishDateHelper Day Operations', () {
    test('parseDayOfWeek parses regular and folded day names', () {
      expect(TurkishDateHelper.parseDayOfWeek('Pazartesi'), 1);
      expect(TurkishDateHelper.parseDayOfWeek('pzt'), 1);
      expect(TurkishDateHelper.parseDayOfWeek('çarşamba'), 3);
      expect(TurkishDateHelper.parseDayOfWeek('carsamba'), 3);
      expect(TurkishDateHelper.parseDayOfWeek('Pazar'), 7);
      expect(TurkishDateHelper.parseDayOfWeek('gecersiz'), isNull);
    });

    test('getDayName returns day name matching DateTime.weekday', () {
      expect(TurkishDateHelper.getDayName(1), 'Pazartesi');
      expect(TurkishDateHelper.getDayName(1, uppercase: true), 'PAZARTESİ');
      expect(TurkishDateHelper.getDayName(1, short: true), 'Pzt');

      expect(TurkishDateHelper.getDayName(7), 'Pazar');
      expect(TurkishDateHelper.getDayName(7, uppercase: true), 'PAZAR');
      expect(TurkishDateHelper.getDayName(7, short: true), 'Paz');
    });
  });

  group('TurkishDateHelper Date Formatters', () {
    final sampleDate = DateTime(2026, 8, 15, 14, 30); // 15 Ağustos 2026 Cumartesi

    test('formatOfficialDate formats official dates correctly', () {
      expect(
        TurkishDateHelper.formatOfficialDate(sampleDate),
        '15 AĞUSTOS 2026',
      );
      expect(
        TurkishDateHelper.formatOfficialDate(sampleDate, uppercase: false),
        '15 Ağustos 2026',
      );
      expect(
        TurkishDateHelper.formatOfficialDate(sampleDate, includeDayName: true),
        '15 AĞUSTOS 2026 CUMARTESİ',
      );
      expect(
        TurkishDateHelper.formatOfficialDate(sampleDate, includeDayName: true, uppercase: false),
        '15 Ağustos 2026 Cumartesi',
      );
    });

    test('formatMilitaryDtg formats DTG correctly', () {
      // 15 1430 AGU 26
      expect(
        TurkishDateHelper.formatMilitaryDtg(sampleDate),
        '15 1430 AGU 26',
      );
    });

    test('formatDateDotted and formatDateIso', () {
      expect(TurkishDateHelper.formatDateDotted(sampleDate), '15.08.2026');
      expect(TurkishDateHelper.formatDateIso(sampleDate), '2026-08-15');
    });
  });
}

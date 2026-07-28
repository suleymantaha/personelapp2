import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';

void main() {
  test('24 saatlik görev ay sınırında iki takvim gününü kapsar', () {
    expect(
      DutyCoverage.coveredDates(
        startDate: '2026-07-31',
        duty: 'HAZIR KITA',
      ),
      ['2026-07-31', '2026-08-01'],
    );
  });

  test('Kule Nöbeti ve genel Nöbetçi tek gün kalır', () {
    expect(
      DutyCoverage.coveredDates(
        startDate: '2026-07-31',
        duty: 'KULE NÖB.',
      ),
      ['2026-07-31'],
    );
    expect(
      DutyCoverage.coveredDates(
        startDate: '2026-07-31',
        duty: 'NÖBETÇİ',
      ),
      ['2026-07-31'],
    );
  });
}

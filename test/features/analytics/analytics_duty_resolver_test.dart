import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/analytics_duty_resolver.dart';

void main() {
  final resolver = AnalyticsDutyResolver(['Adı GEÇEN', 'KEN UYARI']);
  test('an ordinary word starting with a rank is never a personnel line', () {
    expect(resolver.resolve(duty: 'ERKEN UYARI', activityName: 'Heybet'),
        'ERKEN UYARI');
  });
  test('valid custom classified override is preserved', () {
    expect(resolver.resolve(duty: 'DDE', activityName: 'Heybet'), 'DDE');
  });
  test('unclassified parent and leave parent cannot justify projection', () {
    for (final parent in ['Sentetik faaliyet', 'RAPORLU', 'İZİNLİ']) {
      expect(
          resolver.resolve(
              duty: '.Uzm.Çvş. Adı GEÇEN(6B)', activityName: parent),
          '.Uzm.Çvş. Adı GEÇEN(6B)'.toUpperCase());
    }
  });
  test('numbered exact personnel line can use recognized parent task', () {
    expect(
        resolver.resolve(
            duty: '6-J.Uzm.Çvş. Adı GEÇEN(Keskin Timi)',
            activityName: 'Heybet'),
        'HEYBET');
  });
  test('nearby person name is not a fuzzy match', () {
    const source = '.Uzm.Çvş. Adı GEÇMEYEN(Keskin Timi)';
    expect(resolver.resolve(duty: source, activityName: 'Heybet'),
        source.toUpperCase());
  });
}

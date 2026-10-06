import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/official_roster_title.dart';

void main() {
  group('OfficialRosterTitle', () {
    test('creates the requested official title without time range', () {
      expect(
        OfficialRosterTitle.format(
          'Heybet Tepe Pusu Faaliyeti',
          '2026-07-27',
        ),
        'KOVANCILAR JÖH TB.K.LIĞI 27.07.2026 TARİHİ '
        'HEYBET TEPE PUSU FAALİYETİ PERSONEL İSİM LİSTESİ',
      );
    });

    test('creates official title with time range when provided', () {
      expect(
        OfficialRosterTitle.format(
          'Heybet Tepe Pusu Faaliyeti',
          '2026-10-01',
          timeRange: '06.00-08.00',
        ),
        'KOVANCILAR JÖH TB.K.LIĞI 01.10.2026 TARİHİ (06.00-08.00 SAATLERİ ARASI) '
        'HEYBET TEPE PUSU FAALİYETİ PERSONEL İSİM LİSTESİ',
      );
    });

    test('ignores empty or whitespace-only time range', () {
      expect(
        OfficialRosterTitle.format(
          'Heybet Tepe Pusu Faaliyeti',
          '2026-10-01',
          timeRange: '   ',
        ),
        'KOVANCILAR JÖH TB.K.LIĞI 01.10.2026 TARİHİ '
        'HEYBET TEPE PUSU FAALİYETİ PERSONEL İSİM LİSTESİ',
      );
    });

    test('handles iso date format correctly', () {
      expect(
        OfficialRosterTitle.format(
          'Başka Bir Faaliyet Başlığı',
          '2026-07-27T00:00:00.000',
        ),
        'KOVANCILAR JÖH TB.K.LIĞI 27.07.2026 TARİHİ '
        'HEYBET TEPE PUSU FAALİYETİ PERSONEL İSİM LİSTESİ',
      );
    });
  });
}

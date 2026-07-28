import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/official_roster_title.dart';

void main() {
  group('OfficialRosterTitle', () {
    test('creates the requested official title', () {
      expect(
        OfficialRosterTitle.format(
          'Heybet Tepe Pusu Faaliyeti',
          '2026-07-27',
        ),
        'KOVANCILAR JÖH TB.K.LIĞI HEYBET TEPE PUSU FAALİYETİ '
        'İSİM LİSTESİ - 27.07.2026',
      );
    });

    test('ignores other entered headings and keeps the single official title', () {
      expect(
        OfficialRosterTitle.format(
          'Başka Bir Faaliyet Başlığı',
          '2026-07-27T00:00:00.000',
        ),
        'KOVANCILAR JÖH TB.K.LIĞI HEYBET TEPE PUSU FAALİYETİ '
        'İSİM LİSTESİ - 27.07.2026',
      );
    });

    test('uses the default activity for a generic daily activity name', () {
      expect(
        OfficialRosterTitle.format('Günlük Faaliyet', '27.07.2026'),
        'KOVANCILAR JÖH TB.K.LIĞI HEYBET TEPE PUSU FAALİYETİ '
        'İSİM LİSTESİ - 27.07.2026',
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/duty_abbreviation_mapper.dart';

void main() {
  test('operational duty codes match the team calendar', () {
    expect(DutyAbbreviationMapper.getAbbreviation('HEYBET'), 'HEY');
    expect(DutyAbbreviationMapper.getAbbreviation('GÖREVLİ'), 'GÖR');
    expect(DutyAbbreviationMapper.getAbbreviation('GARAJ NÖB.'), 'GAR');
    expect(DutyAbbreviationMapper.getAbbreviation('MEBS NÖB.'), 'MEB');
    expect(DutyAbbreviationMapper.getAbbreviation('HAZIR KITA'), 'H.K');
    expect(DutyAbbreviationMapper.getAbbreviation('NÖBETÇİ'), 'Nbt');
  });

  test('known duty colors are distinct from generic unknown colors', () {
    final fallback = DutyAbbreviationMapper.getBadgeBgColor(
      'CUSTOM_UNKNOWN_DUTY',
      isDark: true,
    );
    for (final duty in ['HEYBET', 'GÖREVLİ', 'HAZIR KITA']) {
      expect(
        DutyAbbreviationMapper.getBadgeBgColor(duty, isDark: true),
        isNot(fallback),
      );
    }
  });

  test('unknown assignment codes retain their original fallback behavior', () {
    expect(DutyAbbreviationMapper.getAbbreviation('DİĞER'), 'DİĞ');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';

void main() {
  group('MilitaryStructureHelper.getRosterBirlikName', () {
    test('uses the team name for a regular duty', () {
      final result = MilitaryStructureHelper.getRosterBirlikName(
        timName: '1-B Timi',
        birlik: "1'inci Bl.",
        duty: 'DEVRİYE',
      );

      expect(result, '1-B Timi');
    });

    test('uses the company name for Hazır Kıta', () {
      final result = MilitaryStructureHelper.getRosterBirlikName(
        timName: '2-B Timi',
        birlik: "1'inci Bl.",
        duty: 'HAZIR KITA',
      );

      expect(result, "1'inci Bl.");
    });

    test('uses the company name for Gülüşkür', () {
      final result = MilitaryStructureHelper.getRosterBirlikName(
        timName: '6-B Timi',
        birlik: "2'nci Bl.",
        duty: 'GÜLÜŞKÜR',
      );

      expect(result, "2'nci Bl.");
    });

    test('normalizes slash and spaced team variants', () {
      for (final team in ['6/B', '6 / B', '6-B', '6-B Timi']) {
        expect(
          MilitaryStructureHelper.getRosterBirlikName(
            timName: team,
            birlik: '',
            duty: 'GÜLÜŞKÜR',
          ),
          "2'nci Bl.",
        );
        expect(
          MilitaryStructureHelper.getOfficialBirlikName(team),
          '6-B Timi',
        );
      }
    });

    test('uses Nöbet Heyeti instead of a KH fallback unit', () {
      final result = MilitaryStructureHelper.getRosterBirlikName(
        timName: '',
        birlik: 'KH',
        duty: 'NÖBETÇİ HEYETİ',
      );

      expect(result, 'Nöbet Heyeti');
    });
  });

  group('roster duty rules', () {
    test('classifies special and guard duty groups consistently', () {
      expect(
        MilitaryStructureHelper.getRosterGroupCode('Hazır Kıta'),
        'HAZIR_KITA',
      );
      expect(
        MilitaryStructureHelper.getRosterGroupCode('Gülüşkür'),
        'GULUSKUR',
      );
      expect(
        MilitaryStructureHelper.getRosterGroupCode('Nöbetçi Heyeti'),
        'NOBET_HEYETI',
      );
    });

    test('keeps guard description and falls back to duty when it is empty', () {
      expect(
        MilitaryStructureHelper.getDigerCellText(
          'Nöbetçi Heyeti',
          aciklama: 'Ana Nizamiyede',
        ),
        'Ana Nizamiyede',
      );
      expect(
        MilitaryStructureHelper.getDigerCellText(
          'Nöbetçi Heyeti',
          aciklama: '  ',
        ),
        'Nöbetçi Heyeti',
      );
    });

    test('orders parent companies separately for contiguous special rows', () {
      expect(
        MilitaryStructureHelper.getSquadOrderWeight("1'inci Bl."),
        lessThan(MilitaryStructureHelper.getSquadOrderWeight("2'nci Bl.")),
      );
      expect(
        MilitaryStructureHelper.getSquadOrderWeight("2'nci Bl."),
        lessThan(MilitaryStructureHelper.getSquadOrderWeight("3'üncü Bl.")),
      );
    });
  });
}

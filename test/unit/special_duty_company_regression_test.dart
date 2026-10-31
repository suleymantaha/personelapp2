import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

void main() {
  final companies = {
    "1'inci Bl.": ["1'inci Bl. K.H", "1'İNCİ BL. K.H", '1.BL.K.H'],
    "2'nci Bl.": ["2'nci Bl. K.H", "2'NCİ BL. K.H", '2.BL.K.H'],
    "3'üncü Bl.": ["3'üncü Bl. K.H", "3'ÜNCÜ BL. K.H", '3.BL.K.H'],
  };
  for (final company in companies.entries) {
    for (final name in company.value) {
      test('special duties map $name to ${company.key}', () {
        for (final duty in ['HAZIR KITA', 'GÜLÜŞKÜR']) {
          expect(
            MilitaryStructureHelper.getRosterBirlikName(
              timName: name,
              birlik: '',
              duty: duty,
            ),
            company.key,
          );
        }
      });
    }
    test('regular duties preserve ${company.value.first}', () {
      expect(
        MilitaryStructureHelper.getRosterBirlikName(
          timName: company.value.first,
          birlik: '',
          duty: 'DEVRİYE',
        ),
        company.value.first,
      );
    });
  }

  test(
      'master XLSX merges special duties across companies within each activity',
      () {
    final rows = [
      _row(1, "1'inci Bl.", 'HAZIR_KITA', 'HAZIR KITA'),
      _row(2, "2'nci Bl.", 'HAZIR_KITA', 'HAZIR KITA'),
      _row(3, "2'nci Bl.", 'HAZIR_KITA', 'HAZIR KITA'),
      _row(4, "3'üncü Bl.", 'GULUSKUR', 'GÜLÜŞKÜR'),
      _row(5, 'K.H', 'GULUSKUR', 'GÜLÜŞKÜR'),
    ];
    final bytes = MilitaryRosterExporter.generateMasterDailyExcelBytes(
      title: 'Faaliyetler',
      activities: [
        for (final title in ['Birinci Faaliyet', 'İkinci Faaliyet'])
          MasterActivityData(
            faaliyetAdi: title,
            tarih: '01.11.2026',
            olusturanKullanici: 'Test',
            rows: rows,
          ),
      ],
    );
    final excel = Excel.decodeBytes(bytes);
    final merges = excel.getMergedCells('Tüm Faaliyetler');
    final dutyMerges = merges.where((range) => range.startsWith('G')).toList();
    expect(
        dutyMerges, unorderedEquals(['G4:G6', 'G7:G8', 'G10:G12', 'G13:G14']));
    expect(merges, containsAll(['B5:B6', 'B11:B12']));
    expect(merges, isNot(contains('B4:B6')));
    final sheet = excel['Tüm Faaliyetler'];
    for (final address in ['G4', 'G10']) {
      expect(sheet.cell(CellIndex.indexByString(address)).value.toString(),
          'HAZIR KITA');
    }
    for (final address in ['G7', 'G13']) {
      expect(sheet.cell(CellIndex.indexByString(address)).value.toString(),
          'GÜLÜŞKÜR');
    }
  });
}

MilitaryRosterRow _row(
        int number, String company, String group, String label) =>
    MilitaryRosterRow(
      sNu: number,
      birligi: company,
      rutbe: 'J.Er',
      adSoyad: 'Personel $number',
      diger: label,
      groupCode: group,
    );

import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

void main() {
  final sameBirlikRows = [
    MilitaryRosterRow(
      sNu: 1,
      birligi: '1. TİM',
      rutbe: 'UZM.J.II.KAD.ÇVŞ.',
      adSoyad: 'Birinci Personel',
      diger: '',
    ),
    MilitaryRosterRow(
      sNu: 2,
      birligi: '  1.   tim ',
      rutbe: 'UZM.J.VI.KAD.ÇVŞ.',
      adSoyad: 'İkinci Personel',
      diger: '',
    ),
    MilitaryRosterRow(
      sNu: 3,
      birligi: '1. TİM',
      rutbe: 'UZM.J.ÇVŞ.',
      adSoyad: 'Üçüncü Personel',
      diger: '',
    ),
  ];

  test('single activity Excel merges consecutive BİRLİĞİ cells', () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Faaliyet',
      tarih: '2026-07-27',
      rows: sameBirlikRows,
    );
    final excel = Excel.decodeBytes(bytes);

    expect(excel.getMergedCells('İsim Listesi'), contains('B4:B6'));
  });

  test('master Excel merges consecutive BİRLİĞİ cells per activity', () {
    final bytes = MilitaryRosterExporter.generateMasterDailyExcelBytes(
      title: 'Faaliyetler',
      activities: [
        MasterActivityData(
          faaliyetAdi: 'Faaliyet',
          tarih: '27.07.2026',
          olusturanKullanici: 'Test',
          rows: sameBirlikRows,
        ),
      ],
    );
    final excel = Excel.decodeBytes(bytes);

    expect(excel.getMergedCells('Tüm Faaliyetler'), contains('B5:B7'));
  });

  test('Hazır Kıta merges both BİRLİĞİ and DİĞER cells', () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Faaliyet',
      tarih: '2026-07-27',
      rows: _specialRows('HAZIR_KITA', 'HAZIR KITA'),
    );
    final excel = Excel.decodeBytes(bytes);
    final merges = excel.getMergedCells('İsim Listesi');

    expect(merges, containsAll(['B4:B5', 'E4:E5']));
  });

  test('Gülüşkür merges both BİRLİĞİ and DİĞER cells in master Excel', () {
    final rows = _specialRows('GULUSKUR', 'GÜLÜŞKÜR');
    final bytes = MilitaryRosterExporter.generateMasterDailyExcelBytes(
      title: 'Faaliyetler',
      activities: [
        MasterActivityData(
          faaliyetAdi: 'Faaliyet',
          tarih: '27.07.2026',
          olusturanKullanici: 'Test',
          rows: rows,
        ),
      ],
    );
    final excel = Excel.decodeBytes(bytes);
    final merges = excel.getMergedCells('Tüm Faaliyetler');

    expect(merges, containsAll(['B5:B6', 'E5:E6']));
  });

  test('Nöbet Heyeti merges BİRLİĞİ but preserves individual DİĞER cells', () {
    final rows = [
      MilitaryRosterRow(
        sNu: 1,
        birligi: 'Nöbet Heyeti',
        rutbe: 'UZM.J.ÇVŞ.',
        adSoyad: 'Birinci Personel',
        diger: 'Ana Nizamiye',
        groupCode: 'NOBET_HEYETI',
      ),
      MilitaryRosterRow(
        sNu: 2,
        birligi: 'Nöbet Heyeti',
        rutbe: 'UZM.J.ÇVŞ.',
        adSoyad: 'İkinci Personel',
        diger: 'Kule Nöbeti',
        groupCode: 'NOBET_HEYETI',
      ),
    ];
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Faaliyet',
      tarih: '2026-07-27',
      rows: rows,
    );
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['İsim Listesi'];
    final merges = excel.getMergedCells('İsim Listesi');

    expect(merges, contains('B4:B5'));
    expect(merges, isNot(contains('E4:E5')));
    expect(sheet.cell(CellIndex.indexByString('E4')).value?.toString(),
        'Ana Nizamiye');
    expect(sheet.cell(CellIndex.indexByString('E5')).value?.toString(),
        'Kule Nöbeti');
  });

  test('same-name master sections include time and creator and stay separate',
      () {
    final bytes = MilitaryRosterExporter.generateMasterDailyExcelBytes(
      title: 'Faaliyetler',
      activities: [
        MasterActivityData(
          faaliyetAdi: 'Görev',
          tarih: '28.07.2026',
          olusturanKullanici: 'Ali',
          olusturmaTarihi: '2026-07-28T08:15:00',
          rows: _specialRows('HAZIR_KITA', 'HAZIR KITA'),
        ),
        MasterActivityData(
          faaliyetAdi: 'Görev',
          tarih: '28.07.2026',
          olusturanKullanici: 'Veli',
          olusturmaTarihi: '2026-07-28T10:45:00',
          rows: _specialRows('HAZIR_KITA', 'HAZIR KITA'),
        ),
      ],
    );
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Tüm Faaliyetler'];

    expect(
      sheet.cell(CellIndex.indexByString('A3')).value?.toString(),
      'GÖREV (28.07.2026 - 08:15 - Ali)',
    );
    expect(
      sheet.cell(CellIndex.indexByString('A8')).value?.toString(),
      'GÖREV (28.07.2026 - 10:45 - Veli)',
    );
    expect(
      excel.getMergedCells('Tüm Faaliyetler'),
      containsAll(['E5:E6', 'E10:E11']),
    );
  });

  test('Excel keeps adjacent Hazır Kıta and Gülüşkür merge blocks separate',
      () {
    final rows = [
      ..._specialRows('HAZIR_KITA', 'HAZIR KITA'),
      ..._specialRows('GULUSKUR', 'GÜLÜŞKÜR').map(
        (row) => MilitaryRosterRow(
          sNu: row.sNu + 2,
          birligi: row.birligi,
          rutbe: row.rutbe,
          adSoyad: row.adSoyad,
          diger: row.diger,
          groupCode: row.groupCode,
        ),
      ),
    ];
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Faaliyet',
      tarih: '2026-07-29',
      rows: rows,
    );
    final excel = Excel.decodeBytes(bytes);
    final merges = excel.getMergedCells('İsim Listesi');

    expect(
      merges,
      containsAll(['B4:B5', 'E4:E5', 'B6:B7', 'E6:E7']),
    );
    expect(merges, isNot(contains('B4:B7')));
  });

  test('combined archive Excel renders one continuous table like PDF', () {
    final rows = [
      ..._specialRows('HAZIR_KITA', 'HAZIR KITA'),
      ..._specialRows('GULUSKUR', 'GÜLÜŞKÜR').map(
        (row) => MilitaryRosterRow(
          sNu: row.sNu + 2,
          birligi: row.birligi,
          rutbe: row.rutbe,
          adSoyad: row.adSoyad,
          diger: row.diger,
          groupCode: row.groupCode,
        ),
      ),
    ];

    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'GÜNLÜK TÜM FAALİYETLER',
      tarih: '29.07.2026',
      rows: rows,
    );
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['İsim Listesi'];

    expect(
      sheet.cell(CellIndex.indexByString('A1')).value?.toString(),
      contains('29.07.2026'),
    );
    expect(
      sheet.cell(CellIndex.indexByString('A3')).value?.toString(),
      'S. NU',
    );
    expect(sheet.cell(CellIndex.indexByString('A4')).value?.toString(), '1');
    expect(sheet.cell(CellIndex.indexByString('A7')).value?.toString(), '4');
    expect(
      excel.getMergedCells('İsim Listesi'),
      containsAll(['B4:B5', 'E4:E5', 'B6:B7', 'E6:E7']),
    );
  });

  test('Excel table cells have printable borders', () {
    final rows = _specialRows('HAZIR_KITA', 'HAZIR KITA');

    final singleExcel = Excel.decodeBytes(
      MilitaryRosterExporter.generateMilitaryExcelBytes(
        faaliyetAdi: 'Faaliyet',
        tarih: '29.07.2026',
        rows: rows,
      ),
    );
    final masterExcel = Excel.decodeBytes(
      MilitaryRosterExporter.generateMasterDailyExcelBytes(
        title: 'Faaliyetler',
        activities: [
          MasterActivityData(
            faaliyetAdi: 'Görev',
            tarih: '29.07.2026',
            olusturanKullanici: 'Test',
            rows: rows,
          ),
        ],
      ),
    );

    for (final cell in [
      singleExcel['İsim Listesi'].cell(CellIndex.indexByString('A3')),
      singleExcel['İsim Listesi'].cell(CellIndex.indexByString('A4')),
      masterExcel['Tüm Faaliyetler'].cell(CellIndex.indexByString('A4')),
      masterExcel['Tüm Faaliyetler'].cell(CellIndex.indexByString('A5')),
    ]) {
      expect(cell.cellStyle?.leftBorder.borderStyle, BorderStyle.Thin);
      expect(cell.cellStyle?.rightBorder.borderStyle, BorderStyle.Thin);
      expect(cell.cellStyle?.topBorder.borderStyle, BorderStyle.Thin);
      expect(cell.cellStyle?.bottomBorder.borderStyle, BorderStyle.Thin);
    }
  });

  test('Excel renders three aligned rank summary boxes', () {
    final rows = [
      _summaryRow(1, 'HAZIR_KITA', 'J.Yzb.'),
      _summaryRow(2, 'HAZIR_KITA', 'J.Asb.Çvş.'),
      _summaryRow(3, 'HAZIR_KITA', 'Uzm.J.'),
      _summaryRow(4, 'HAZIR_KITA', 'J.Uzm.Çvş.'),
      _summaryRow(5, 'HAZIR_KITA', 'J.Söz.Er'),
      _summaryRow(6, 'GULUSKUR', 'J.Er'),
      _summaryRow(7, 'NOBET_HEYETI', 'J.Yzb.'),
      _summaryRow(8, 'DIGER', 'J.Uzm.Çvş.'),
    ];

    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Faaliyet',
      tarih: '29.07.2026',
      rows: rows,
    );
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['İsim Listesi'];
    final cellTexts = sheet.rows
        .expand((row) => row)
        .map((cell) => cell?.value?.toString())
        .whereType<String>()
        .toList();

    expect(
      excel.getMergedCells('İsim Listesi'),
      containsAll(['A13:B13', 'C13:D13', 'E13:F13']),
    );
    expect(sheet.cell(CellIndex.indexByString('A13')).value?.toString(),
        'Hazır Kıta');
    expect(sheet.cell(CellIndex.indexByString('C13')).value?.toString(),
        'Gülüşkür');
    expect(sheet.cell(CellIndex.indexByString('E13')).value?.toString(),
        'Diğer Tüm Personel');
    expect(
        cellTexts,
        containsAll([
          'SB. 1',
          'ASB. 1',
          'UZM.J. 1',
          'J.UZM.ÇVŞ. 1',
          'ER/SÖZ.ER 1',
          'Toplam 5',
          'Toplam 1',
          'Toplam 2',
        ]));
    expect(cellTexts, isNot(contains('GÖREV VE MEVCUT ÖZETİ')));
    expect(
      cellTexts.where((text) => text.startsWith('ER/SÖZ.ER')),
      hasLength(2),
    );
  });

  test('Excel hides zero rank lines but keeps zero totals', () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Boş Faaliyet',
      tarih: '29.07.2026',
      rows: const [],
    );
    final excel = Excel.decodeBytes(bytes);
    final texts = excel['İsim Listesi']
        .rows
        .expand((row) => row)
        .map((cell) => cell?.value?.toString())
        .whereType<String>()
        .toList();

    expect(texts.where((text) => text == 'Toplam 0'), hasLength(3));
    expect(texts, isNot(contains('SB. 0')));
    expect(texts, isNot(contains('ASB. 0')));
    expect(texts, isNot(contains('UZM.J. 0')));
    expect(texts, isNot(contains('J.UZM.ÇVŞ. 0')));
    expect(texts, isNot(contains('ER/SÖZ.ER 0')));
  });

  test('Excel print settings include summary and repeat table headers', () {
    final rows = _specialRows('HAZIR_KITA', 'HAZIR KITA');
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Faaliyet',
      tarih: '29.07.2026',
      rows: rows,
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    final workbook = archive.findFile('xl/workbook.xml');
    final workbookXml = utf8.decode(workbook!.content as List<int>);

    expect(
      workbookXml,
      contains(
        '<definedName name="_xlnm.Print_Area" localSheetId="0">'
        "'İsim Listesi'!\$A\$1:\$F\$9"
        '</definedName>',
      ),
    );
    expect(
      workbookXml,
      contains(
        '<definedName name="_xlnm.Print_Titles" localSheetId="0">'
        "'İsim Listesi'!\$3:\$3"
        '</definedName>',
      ),
    );

    final worksheet = archive.files.firstWhere(
      (file) =>
          file.name.startsWith('xl/worksheets/sheet') &&
          file.name.endsWith('.xml'),
    );
    final worksheetXml = utf8.decode(worksheet.content as List<int>);
    expect(worksheetXml, contains('showGridLines="0"'));
    expect(worksheetXml, contains('<pageSetUpPr fitToPage="1"/>'));
    expect(
      worksheetXml,
      contains(
        '<pageSetup paperSize="9" orientation="landscape" '
        'fitToWidth="1" fitToHeight="0"/>',
      ),
    );
  });

  test('Excel wraps long text and increases row height', () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Çok Uzun Faaliyet Başlığı İle Yazdırma Kontrolü',
      tarih: '29.07.2026',
      rows: [
        MilitaryRosterRow(
          sNu: 1,
          birligi: 'Çok Uzun Birlik ve Tim Açıklaması',
          rutbe: 'J.UZM.ÇVŞ.',
          adSoyad: 'Çok Uzun İsimli Bir Personelin Tam Adı Soyadı',
          diger: 'Ana Nizamiye ve çevre emniyeti için uzun görev açıklaması',
        ),
      ],
    );
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['İsim Listesi'];

    expect(
      sheet.cell(CellIndex.indexByString('D4')).cellStyle?.wrap,
      TextWrapping.WrapText,
    );
    expect(sheet.getRowHeight(3), greaterThan(20));
  });

  test('master Excel includes a global summary and print configuration', () {
    final bytes = MilitaryRosterExporter.generateMasterDailyExcelBytes(
      title: 'Tüm Faaliyetler',
      activities: [
        MasterActivityData(
          faaliyetAdi: 'Görev',
          tarih: '29.07.2026',
          olusturanKullanici: 'Test',
          rows: [
            _summaryRow(1, 'HAZIR_KITA', 'J.Yzb.'),
            _summaryRow(2, 'GULUSKUR', 'J.Er'),
            _summaryRow(3, 'DIGER', 'J.Uzm.Çvş.'),
          ],
        ),
      ],
    );
    final excel = Excel.decodeBytes(bytes);
    final texts = excel['Tüm Faaliyetler']
        .rows
        .expand((row) => row)
        .map((cell) => cell?.value?.toString())
        .whereType<String>()
        .toList();
    expect(
      texts,
      containsAll(['Hazır Kıta', 'Gülüşkür', 'Diğer Tüm Personel']),
    );

    final archive = ZipDecoder().decodeBytes(bytes);
    final workbookXml = utf8.decode(
      archive.findFile('xl/workbook.xml')!.content as List<int>,
    );
    expect(workbookXml, contains("'Tüm Faaliyetler'!\$4:\$4"));
    expect(workbookXml, contains("'Tüm Faaliyetler'!\$A\$1:\$F\$"));
  });
}

MilitaryRosterRow _summaryRow(int sNu, String groupCode, String rank) =>
    MilitaryRosterRow(
      sNu: sNu,
      birligi: "1'inci Bl.",
      rutbe: rank,
      adSoyad: 'Personel $sNu',
      diger: groupCode,
      groupCode: groupCode,
    );

List<MilitaryRosterRow> _specialRows(String groupCode, String dutyLabel) => [
      MilitaryRosterRow(
        sNu: 1,
        birligi: "1'inci Bl.",
        rutbe: 'UZM.J.ÇVŞ.',
        adSoyad: 'Birinci Personel',
        diger: dutyLabel,
        groupCode: groupCode,
      ),
      MilitaryRosterRow(
        sNu: 2,
        birligi: "1'inci Bl.",
        rutbe: 'UZM.J.ÇVŞ.',
        adSoyad: 'İkinci Personel',
        diger: dutyLabel,
        groupCode: groupCode,
      ),
    ];

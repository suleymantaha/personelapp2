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

  test('special duty summary shows officer NCO specialist and other counts',
      () {
    final rows = [
      _summaryRow(1, 'HAZIR_KITA', 'J.Yzb.'),
      _summaryRow(2, 'HAZIR_KITA', 'J.Asb.Çvş.'),
      _summaryRow(3, 'HAZIR_KITA', 'Uzm.J.'),
      _summaryRow(4, 'HAZIR_KITA', 'J.Uzm.Çvş.'),
      _summaryRow(5, 'HAZIR_KITA', 'J.Söz.Er'),
      _summaryRow(6, 'GULUSKUR', 'J.Er'),
    ];

    expect(
      MilitaryRosterExporter.specialDutyRankSummary(
        'Hazır Kıta',
        'HAZIR_KITA',
        rows,
      ),
      'Hazır Kıta: 5 Personel '
      '(Subay: 1 • Astsubay: 1 • Uzman Jandarma: 1 • '
      'Uzman Erbaş: 1 • Diğer: 1)',
    );
    expect(
      MilitaryRosterExporter.specialDutyRankSummary(
        'Gülüşkür',
        'GULUSKUR',
        rows,
      ),
      'Gülüşkür: 1 Personel '
      '(Subay: 0 • Astsubay: 0 • Uzman Jandarma: 0 • '
      'Uzman Erbaş: 0 • Diğer: 1)',
    );
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

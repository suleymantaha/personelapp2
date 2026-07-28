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
    expect(sheet.cell(CellIndex.indexByString('E4')).value?.toString(), 'Ana Nizamiye');
    expect(sheet.cell(CellIndex.indexByString('E5')).value?.toString(), 'Kule Nöbeti');
  });
}

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

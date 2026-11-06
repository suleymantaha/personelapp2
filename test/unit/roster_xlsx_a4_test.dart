import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';

List<MilitaryRosterRow> _rows(int count, {bool special = false}) =>
    List.generate(count, (i) {
      return MilitaryRosterRow(
        sNu: i + 1,
        birligi: special
            ? '1. Tim'
            : '${i < 23 ? 1 : i < 54 ? 2 : 3}. Tim',
        rutbe: 'J.Uzm.Çvş.',
        adSoyad: 'Deneme Personel ${i + 1}',
        diger: special && i == 0 ? 'HAZIR KITA' : '',
        groupCode: special ? 'HAZIR_KITA' : 'DIGER',
      );
    });

String _xml(List<int> bytes, String file) => utf8.decode(
      ZipDecoder().decodeBytes(bytes).findFile(file)!.content as List<int>,
    );

String _worksheet(List<int> bytes) => _xml(bytes, 'xl/worksheets/sheet1.xml');

List<int> _breaks(String xml) => RegExp(r'<brk id="(\d+)"')
    .allMatches(xml)
    .map((match) => int.parse(match.group(1)!))
    .toList();

double _height(String xml, int row) => double.parse(
      RegExp('<row[^>]*r="$row"[^>]*\\bht="([^"]+)"')
          .firstMatch(xml)!
          .group(1)!,
    );

List<int> _single(List<MilitaryRosterRow> rows, {bool signed = false}) =>
    MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Sentetik Görev',
      tarih: '2026-10-06',
      rows: rows,
      includeSignatures: signed,
    );

void main() {
  for (final signed in [false, true]) {
    test('105 personnel occupy two balanced A4 pages (signed: $signed)', () {
      final bytes = _single(_rows(105), signed: signed);
      final xml = _worksheet(bytes);
      expect(xml, contains('paperSize="9" orientation="portrait"'));
      expect(_breaks(xml), [56]);
      final scale =
          int.parse(RegExp(r'scale="(\d+)"').firstMatch(xml)!.group(1)!);
      expect(scale, inInclusiveRange(84, 90));
      final workbook = _xml(bytes, 'xl/workbook.xml');
      expect(workbook, contains(r'!$1:$2'));
      expect(workbook, contains(signed ? r'!$A$1:$G$113' : r'!$A$1:$G$107'));
      final sheet = Excel.decodeBytes(bytes)['İsim Listesi'];
      expect(sheet.rows.skip(2).take(105).map((r) => r[0]!.value.toString()),
          List.generate(105, (i) => '${i + 1}'));
      if (signed) {
        expect(sheet.cell(CellIndex.indexByString('A109')).value.toString(),
            'TANZİM EDEN');
      }
    });
  }

  test('a page break restarts unit and special-duty merged labels', () {
    final bytes = _single(_rows(105, special: true));
    final breakRow = _breaks(_worksheet(bytes)).single;
    final sheet = Excel.decodeBytes(bytes)['İsim Listesi'];
    expect(sheet.rows[breakRow][1]?.value.toString(), '1. Tim');
    expect(sheet.rows[breakRow][6]?.value.toString(), 'HAZIR KITA');
    expect(sheet.spannedItems, contains('B${breakRow + 1}:B107'));
    expect(sheet.spannedItems, contains('G3:G$breakRow'));
  });

  test('unmerged continuation keeps each original duty value', () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Sentetik Görev',
      tarih: '2026-10-06',
      rows: _rows(105, special: true),
      mergeCells: false,
    );
    final breakRow = _breaks(_worksheet(bytes)).single;
    final sheet = Excel.decodeBytes(bytes)['İsim Listesi'];
    expect(sheet.rows[2][6]?.value.toString(), 'HAZIR KITA');
    expect(sheet.rows[breakRow][1]?.value.toString(), '1. Tim');
    expect(sheet.rows[breakRow][6]?.value.toString(), isEmpty);
  });

  test('wrapped signer roles retain their full height inside the print area',
      () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
      faaliyetAdi: 'Sentetik Görev',
      tarih: '2026-10-06',
      rows: _rows(105),
      includeSignatures: true,
      signers: const [
        RosterSigner('TANZİM EDEN', 'Personel A', 'J.Yb.', 'Görev A'),
        RosterSigner(
            'TASDİK EDEN', 'Personel B', 'J.Yb.', 'Satır 1\nSatır 2\nSatır 3'),
      ],
    );
    final xml = _worksheet(bytes);
    expect(_height(xml, 113), greaterThanOrEqualTo(36));
    expect(_breaks(xml), everyElement(lessThan(106)));
    expect(_xml(bytes, 'xl/workbook.xml'), contains(r'!$A$1:$G$113'));
  });

  test('master Excel keeps activity headers with personnel and wraps rows', () {
    final first = _rows(52);
    first[0] = MilitaryRosterRow(
      sNu: 1,
      birligi: '1. Tim',
      rutbe: 'J.Uzm.Çvş.',
      adSoyad: 'BİRİNCİ\nİKİNCİ\nÜÇÜNCÜ\nDÖRDÜNCÜ',
      diger: '',
    );
    final bytes = MilitaryRosterExporter.generateMasterDailyExcelBytes(
      title: 'Sentetik Günlük Liste',
      activities: [
        MasterActivityData(
          faaliyetAdi: 'Birinci Görev',
          tarih: '2026-10-06',
          olusturanKullanici: 'test',
          rows: first,
        ),
        MasterActivityData(
          faaliyetAdi: 'İkinci Görev',
          tarih: '2026-10-06',
          olusturanKullanici: 'test',
          rows: _rows(53),
        ),
      ],
    );
    final xml = _worksheet(bytes);
    expect(_height(xml, 4), greaterThanOrEqualTo(50));
    expect(_breaks(xml), [55]);
  });

  test('105 densely wrapped rows use extra pages without shrinking type', () {
    final rows = List.generate(
      105,
      (i) => MilitaryRosterRow(
        sNu: i + 1,
        birligi: '1. Tim',
        rutbe: 'Er',
        adSoyad: 'BİRİNCİ\nİKİNCİ\nÜÇÜNCÜ\nDÖRDÜNCÜ',
        diger: '',
      ),
    );
    final xml = _worksheet(_single(rows, signed: true));
    expect(_breaks(xml).length, greaterThan(1));
    expect(_height(xml, 3), greaterThanOrEqualTo(50));
    final scale =
        int.parse(RegExp(r'scale="(\d+)"').firstMatch(xml)!.group(1)!);
    expect(scale, greaterThanOrEqualTo(84));
  });

  test('three-page roster uses nearby unit breaks without adding a page', () {
    final rows = List.generate(
      133,
      (i) => MilitaryRosterRow(
        sNu: i + 1,
        birligi: '${i ~/ 52 + 1}. Tim',
        rutbe: 'Er',
        adSoyad: 'Deneme Personel ${i + 1}',
        diger: '',
      ),
    );
    expect(_breaks(_worksheet(_single(rows))), [54, 106]);
  });
}

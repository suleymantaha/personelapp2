import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/analytics/domain/team_analytics.dart';
import 'package:personelapp2/features/analytics/domain/monthly_analytics_report.dart';
import 'package:personelapp2/features/analytics/services/monthly_analytics_excel_exporter.dart';
// ignore: depend_on_referenced_packages
import 'package:xml/xml.dart';

void main() {
  test('freezes matrix labels and headers without changing numeric counts', () {
    final bytes =
        MonthlyAnalyticsExcelExporter.generate(report(headcount: 2407));
    final archive = ZipDecoder().decodeBytes(bytes);
    for (var id = 1; id <= 5; id++) {
      final sheet = XmlDocument.parse(utf8.decode(archive
          .findFile('xl/worksheets/sheet$id.xml')!
          .content as List<int>));
      final views = sheet.findAllElements('sheetViews').single;
      final pane = views.findAllElements('pane').single;
      expect(pane.getAttribute('state'), 'frozen');
      expect(pane.getAttribute('ySplit'), '1');
      expect(pane.getAttribute('xSplit'), id == 4 ? '1' : null);
      expect(pane.getAttribute('topLeftCell'), id == 4 ? 'B2' : 'A2');
      expect(pane.getAttribute('activePane'),
          id == 4 ? 'bottomRight' : 'bottomLeft');
      expect(views.findAllElements('selection').single.getAttribute('pane'),
          id == 4 ? 'bottomRight' : 'bottomLeft');
    }
    final book = Excel.decodeBytes(bytes);
    final count = book['Özet'].cell(CellIndex.indexByString('B17'));
    expect(count.value, IntCellValue(2407));
    expect(count.cellStyle!.numberFormat.formatCode, '#,##0');
    expect(book['Özet'].cell(CellIndex.indexByString('B8')).value,
        IntCellValue(3));
  });

  test('one person with three assignments is never counted as a full team', () {
    final book = Excel.decodeBytes(MonthlyAnalyticsExcelExporter.generate(
        report(repeatedPerson: true, headcount: 17)));
    Object? cell(String sheet, String at) =>
        book[sheet].cell(CellIndex.indexByString(at)).value;
    expect(cell('Özet', 'A8'),
        TextCellValue('Toplam görevlendirme (kişi sayısı değil)'));
    expect(cell('Özet', 'B8'), IntCellValue(3));
    expect(cell('Özet', 'B9'), IntCellValue(1));
    expect(cell('Özet', 'B17'), IntCellValue(17));
    expect(cell('Özet', 'B18'), TextCellValue('2026-10-29'));
    expect(cell('Tim Matrisi', 'B1'),
        TextCellValue('=ÖZEL & <GÖREV> · farklı kişi'));
    expect(cell('Tim Matrisi', 'C1'),
        TextCellValue('=ÖZEL & <GÖREV> · görevlendirme'));
    expect(cell('Tim Matrisi', 'B2'), IntCellValue(1));
    expect(cell('Tim Matrisi', 'C2'), IntCellValue(2));
    expect(cell('Tim Matrisi', 'D2'), IntCellValue(1));
    expect(cell('Tim Matrisi', 'E2'), IntCellValue(1));
    expect(cell('Tim Matrisi', 'F2'), IntCellValue(1));
    expect(cell('Tim Matrisi', 'G2'), IntCellValue(3));
  });

  test('unknown current headcount is distinct from a known zero', () {
    for (final count in <int?>[null, 0]) {
      final book = Excel.decodeBytes(MonthlyAnalyticsExcelExporter.generate(
          report(empty: true, headcount: count)));
      expect(book['Özet'].cell(CellIndex.indexByString('B17')).value,
          count == null ? TextCellValue('Bilinmiyor') : IntCellValue(0));
      expect(book['Özet'].cell(CellIndex.indexByString('B18')).value,
          TextCellValue(count == null ? 'Bilinmiyor' : '2026-10-29'));
    }
  });

  test('exports scoped totals, literal labels and cell-linked editable charts',
      () {
    final bytes = MonthlyAnalyticsExcelExporter.generate(report());
    final book = Excel.decodeBytes(bytes);
    expect(book.tables.keys,
        ['Özet', 'Günlük', 'Görevler', 'Tim Matrisi', 'Kalite']);
    Object? value(String sheet, String cell) =>
        book[sheet].cell(CellIndex.indexByString(cell)).value;
    expect(value('Özet', 'B8'), IntCellValue(3));
    expect(value('Özet', 'B2'), TextCellValue('2026-10-01'));
    expect(value('Özet', 'B3'), TextCellValue('2026-10-02'));
    expect(value('Özet', 'B4'), TextCellValue('2026-10-01'));
    expect(value('Özet', 'B5'), TextCellValue('Tüm timler'));
    expect(value('Özet', 'B6'), TextCellValue('Tüm görevler'));
    expect(value('Özet', 'B7'), TextCellValue('Onaylanan'));
    expect(value('Günlük', 'B2'), IntCellValue(2));
    expect(value('Günlük', 'B3'), IntCellValue(1));
    expect(value('Günlük', 'D2'), IntCellValue(2));
    expect(value('Günlük', 'E2'), IntCellValue(0));
    expect(value('Günlük', 'D3'), IntCellValue(0));
    expect(value('Günlük', 'E3'), IntCellValue(1));
    expect(value('Görevler', 'A2'), TextCellValue('=ÖZEL & <GÖREV>'));
    expect(value('Tim Matrisi', 'A2'), TextCellValue('@Tim'));
    expect(value('Tim Matrisi', 'B2'), IntCellValue(2));
    expect(value('Kalite', 'B2'), IntCellValue(1));
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.findFile('xl/worksheets/_rels/sheet1.xml.rels'), isNull);
    String xml(String path) =>
        utf8.decode(archive.findFile(path)!.content as List<int>);
    final contentTypes = XmlDocument.parse(xml('[Content_Types].xml'));
    final parts = contentTypes
        .findAllElements('Override')
        .map((e) => e.getAttribute('PartName'))
        .toList();
    expect(parts.toSet().length, parts.length);
    expect(chartSheets(archive), {'Günlük': 1, 'Görevler': 1});
    for (final file in archive.files
        .where((f) => f.name.endsWith('.xml') || f.name.endsWith('.rels'))) {
      expect(() => XmlDocument.parse(utf8.decode(file.content as List<int>)),
          returnsNormally);
    }
    expect(xml('xl/worksheets/_rels/sheet2.xml.rels'),
        contains('../drawings/drawing1.xml'));
    expect(xml('xl/drawings/_rels/drawing1.xml.rels'),
        contains('../charts/chart1.xml'));
    expect(xml('[Content_Types].xml'), contains('/xl/charts/chart2.xml'));
    final daily = XmlDocument.parse(xml('xl/charts/chart1.xml'));
    expect(daily.findAllElements('c:f').map((e) => e.innerText), [
      "'Günlük'!\$A\$2:\$A\$3",
      "'Günlük'!\$D\$2:\$D\$3",
      "'Günlük'!\$A\$2:\$A\$3",
      "'Günlük'!\$E\$2:\$E\$3"
    ]);
    expect(cache(daily, 'c:numCache'), ['2', '0', '0', '1']);
    final duties = XmlDocument.parse(xml('xl/charts/chart2.xml'));
    expect(duties.findAllElements('c:f').map((e) => e.innerText),
        ["'Görevler'!\$A\$2:\$A\$3", "'Görevler'!\$B\$2:\$B\$3"]);
    expect(cache(duties, 'c:strCache'), ['=ÖZEL & <GÖREV>', '+DIĞER']);
    expect(xml('[Content_Types].xml'),
        contains('application/vnd.openxmlformats-officedocument.drawing+xml'));
    expect(
        duties.findAllElements('c:barDir').single.getAttribute('val'), 'bar');
    expect(cache(duties, 'c:numCache'), ['2', '1']);
    expect(xml('xl/worksheets/sheet3.xml'), isNot(contains('<f>')));
    expect(xml('xl/sharedStrings.xml'), contains('2026-10-01'));
  });

  test('empty report retains zero days without invalid chart ranges', () {
    final bytes = MonthlyAnalyticsExcelExporter.generate(report(empty: true));
    final book = Excel.decodeBytes(bytes);
    expect(book['Özet'].cell(CellIndex.indexByString('B8')).value,
        IntCellValue(0));
    expect(book['Günlük'].cell(CellIndex.indexByString('B2')).value,
        IntCellValue(0));
    expect(book['Günlük'].cell(CellIndex.indexByString('C3')).value,
        TextCellValue('Kayıt yok'));
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.findFile('xl/charts/chart1.xml'), isNotNull);
    expect(archive.findFile('xl/charts/chart2.xml'), isNull);
    expect(book['Görevler'].cell(CellIndex.indexByString('A2')).value,
        TextCellValue('Kayıt yok'));
  });

  test('unknown-team-only data remains visible outside the team matrix', () {
    final bytes =
        MonthlyAnalyticsExcelExporter.generate(report(unknownOnly: true));
    final book = Excel.decodeBytes(bytes);
    expect(book['Özet'].cell(CellIndex.indexByString('B8')).value,
        IntCellValue(1));
    expect(book['Kalite'].cell(CellIndex.indexByString('B2')).value,
        IntCellValue(1));
    expect(book['Tim Matrisi'].cell(CellIndex.indexByString('B2')).value,
        IntCellValue(0));
    expect(book['Tim Matrisi'].cell(CellIndex.indexByString('C2')).value,
        IntCellValue(0));
  });
}

List<String> cache(XmlDocument doc, String tag) => [
      for (final node in doc.findAllElements(tag))
        for (final value in node.findAllElements('c:v')) value.innerText
    ];

Map<String, int> chartSheets(Archive archive) {
  XmlDocument read(String path) => XmlDocument.parse(
      utf8.decode(archive.findFile(path)!.content as List<int>));
  final relationships = {
    for (final rel
        in read('xl/_rels/workbook.xml.rels').findAllElements('Relationship'))
      rel.getAttribute('Id'): rel.getAttribute('Target')!,
  };
  final result = <String, int>{};
  for (final sheet in read('xl/workbook.xml').findAllElements('sheet')) {
    final path = relationships[sheet.getAttribute('r:id')]!;
    final rels = archive.findFile(
        'xl/${path.replaceFirst('worksheets/', 'worksheets/_rels/')}.rels');
    if (rels == null) continue;
    final drawings = XmlDocument.parse(utf8.decode(rels.content as List<int>))
        .findAllElements('Relationship')
        .where((r) => r.getAttribute('Type')!.endsWith('/drawing'))
        .length;
    if (drawings > 0) result[sheet.getAttribute('name')!] = drawings;
  }
  return result;
}

MonthlyAnalyticsReport report(
    {bool empty = false,
    bool unknownOnly = false,
    bool repeatedPerson = false,
    int? headcount}) {
  AnalyticsEntry entry(int id, int? team, String date, String duty) =>
      AnalyticsEntry(
          activityId: id,
          activityName: 'Sentetik',
          sourceDate: date,
          personnelId: repeatedPerson ? 1 : id,
          personnelName: 'Sentetik $id',
          teamId: team,
          teamName: team == null ? 'Bilinmiyor' : '@Tim',
          duty: duty,
          status: 'onaylandi',
          coveredDates: [date]);
  return MonthlyAnalyticsReport(
      data: TeamAnalytics(
        filter: AnalyticsFilter(start: '2026-10-01', end: '2026-10-02'),
        teams: const {1: '@Tim'},
        entries: empty || unknownOnly
            ? []
            : [
                entry(1, 1, '2026-10-01', '=Özel & <Görev>'),
                entry(2, 1, '2026-10-01', '=Özel & <Görev>'),
                if (repeatedPerson) entry(4, 1, '2026-10-02', '+Diğer'),
              ],
        unknownEntries: empty || repeatedPerson
            ? []
            : [entry(3, null, '2026-10-02', '+Diğer')],
        currentHeadcount: headcount,
        headcountAsOf: headcount == null ? null : DateTime(2026, 10, 29),
      ),
      asOf: DateTime(2026, 10, 1));
}

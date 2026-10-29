import 'dart:convert';
import 'package:archive/archive.dart';
// ignore: depend_on_referenced_packages
import 'package:xml/xml.dart';
import '../domain/monthly_analytics_report.dart';
import 'monthly_excel_chart_xml.dart';

const _relationship =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

List<int> addMonthlyExcelCharts(
    List<int> bytes, MonthlyAnalyticsReport report) {
  // excel's empty template retains a sheet1 drawing relationship even after
  // Sheet1 is deleted. Rebuild the package before adding our own drawings so
  // readers that follow orphan relationships cannot show a phantom chart.
  final archive = Archive();
  for (final file in ZipDecoder().decodeBytes(bytes).files) {
    if (file.name.startsWith('xl/drawings/') ||
        file.name.startsWith('xl/worksheets/_rels/')) {
      continue;
    }
    archive.addFile(file);
  }
  final types = XmlDocument.parse(_read(archive, '[Content_Types].xml'));
  types.rootElement.children.removeWhere((node) =>
      node is XmlElement &&
      (node.getAttribute('PartName') ?? '').startsWith('/xl/drawings/'));
  void chart(int index, int sheetId, List<String> labels, List<int> values,
      {required bool horizontal, List<int>? planned}) {
    if (labels.isEmpty) return;
    final sheet =
        XmlDocument.parse(_read(archive, 'xl/worksheets/sheet$sheetId.xml'));
    sheet.rootElement.children.add(XmlElement(XmlName('drawing'), [
      XmlAttribute(XmlName('xmlns:r'), _relationship),
      XmlAttribute(XmlName('r:id'), 'monthlyChart'),
    ]));
    _write(archive, 'xl/worksheets/sheet$sheetId.xml', sheet.toXmlString());
    _write(archive, 'xl/worksheets/_rels/sheet$sheetId.xml.rels',
        _rels('monthlyChart', 'drawing', '../drawings/drawing$index.xml'));
    _write(
        archive, 'xl/drawings/drawing$index.xml', monthlyChartDrawing(index));
    _write(archive, 'xl/drawings/_rels/drawing$index.xml.rels',
        _rels('rId1', 'chart', '../charts/chart$index.xml'));
    _write(
        archive,
        'xl/charts/chart$index.xml',
        monthlyChartXml(
          horizontal ? 'Görevler' : 'Günlük',
          labels,
          values,
          horizontal: horizontal,
          planned: planned,
        ));
    for (final part in ['drawing', 'chart']) {
      final path = part == 'drawing' ? 'drawings/drawing' : 'charts/chart';
      final type = part == 'drawing' ? 'drawing' : 'drawingml.chart';
      types.rootElement.children.add(XmlElement(XmlName('Override'), [
        XmlAttribute(XmlName('PartName'), '/xl/$path$index.xml'),
        XmlAttribute(XmlName('ContentType'),
            'application/vnd.openxmlformats-officedocument.$type+xml'),
      ]));
    }
  }

  chart(1, 2, report.days.map((d) => d.date).toList(),
      report.days.map((d) => d.isPlanned ? 0 : d.assignments).toList(),
      horizontal: false,
      planned:
          report.days.map((d) => d.isPlanned ? d.assignments : 0).toList());
  chart(2, 3, report.duties.map((d) => d.duty).toList(),
      report.duties.map((d) => d.count).toList(),
      horizontal: true);
  _freezeHeaders(archive);
  _write(archive, '[Content_Types].xml', types.toXmlString());
  return ZipEncoder().encode(archive)!;
}

void _freezeHeaders(Archive archive) {
  for (var id = 1; id <= 5; id++) {
    final path = 'xl/worksheets/sheet$id.xml';
    final sheet = XmlDocument.parse(_read(archive, path));
    final view = sheet.findAllElements('sheetView').single;
    // pane must precede selection in CT_SheetView. Replace both, retaining
    // workbookViewId and any unrelated view settings from the encoder.
    view.children.removeWhere((node) =>
        node is XmlElement &&
        const {'pane', 'selection'}.contains(node.name.local));
    final pane = id == 4 ? 'bottomRight' : 'bottomLeft';
    final cell = id == 4 ? 'B2' : 'A2';
    view.children.insertAll(0, XmlDocument.parse('''<root>
      <pane ${id == 4 ? 'xSplit="1"' : ''} ySplit="1"
        topLeftCell="$cell" activePane="$pane" state="frozen"/>
      <selection pane="$pane" activeCell="$cell" sqref="$cell"/>
      </root>''').rootElement.children.map((node) => node.copy()).toList());
    _write(archive, path, sheet.toXmlString());
  }
}

String _read(Archive archive, String path) =>
    utf8.decode(archive.findFile(path)!.content as List<int>);

void _write(Archive archive, String path, String text) {
  final bytes = utf8.encode(text);
  archive.addFile(ArchiveFile(path, bytes.length, bytes));
}

String _rels(String id, String type, String target) =>
    '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="$id" Type="$_relationship/$type" Target="$target"/>
</Relationships>''';

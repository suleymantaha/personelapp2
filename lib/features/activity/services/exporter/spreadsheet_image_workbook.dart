import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';

/// excel 4.0.6 reads alignment attributes from xf instead of its alignment child
/// (parse.dart:436-445). Restore those attributes from our own generated OOXML.
Sheet decodeSpreadsheetImageWorkbook(List<int> bytes) {
  final sheet = Excel.decodeBytes(bytes).tables.values.single;
  final archive = ZipDecoder().decodeBytes(bytes);
  String xml(String name) => utf8.decode(
      archive.files.firstWhere((f) => f.name == name).content as List<int>);
  String? attr(String tag, String name) =>
      RegExp('$name="([^"]*)"').firstMatch(tag)?.group(1);
  final stylesXml = xml('xl/styles.xml');
  final cellXfs = RegExp(r'<cellXfs\b[^>]*>(.*?)</cellXfs>', dotAll: true)
          .firstMatch(stylesXml)
          ?.group(1) ??
      '';
  final styles = RegExp(r'<xf\b[^>]*(?:/>|>.*?</xf>)', dotAll: true)
      .allMatches(cellXfs)
      .map((m) => m.group(0)!)
      .toList();
  final worksheet = archive.files.firstWhere((f) =>
      f.name.startsWith('xl/worksheets/sheet') && f.name.endsWith('.xml'));
  final cells = RegExp(r'<c\b[^>]*>')
      .allMatches(utf8.decode(worksheet.content as List<int>));
  for (final cell in cells) {
    final tag = cell.group(0)!;
    final reference = attr(tag, 'r');
    final index = int.tryParse(attr(tag, 's') ?? '');
    if (reference == null || index == null || index >= styles.length) continue;
    final alignment =
        RegExp(r'<alignment\b[^>]*/?>').firstMatch(styles[index])?.group(0);
    if (alignment == null) continue;
    final style = sheet.cell(CellIndex.indexByString(reference)).cellStyle;
    if (style == null) continue;
    style.horizontalAlignment = switch (attr(alignment, 'horizontal')) {
      'center' => HorizontalAlign.Center,
      'right' => HorizontalAlign.Right,
      _ => HorizontalAlign.Left,
    };
    style.verticalAlignment = switch (attr(alignment, 'vertical')) {
      'center' => VerticalAlign.Center,
      'top' => VerticalAlign.Top,
      _ => VerticalAlign.Bottom,
    };
  }
  return sheet;
}

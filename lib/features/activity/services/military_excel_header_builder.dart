import 'excel_cell_styler.dart';

/// Builder for XML and HTML table headers in military Excel exports.
class MilitaryExcelHeaderBuilder {
  /// Builds HTML table title and header rows.
  static void buildHtmlHeader(StringBuffer sb, String titleHeader) {
    sb
      ..writeln('  <tr><td colspan="5" class="title">$titleHeader</td></tr>')
      ..writeln(
        '  <tr style="height: 10px;"><td colspan="5" style="border: none;"></td></tr>',
      )
      ..writeln('  <tr>')
      ..writeln('    <th style="width: 50px;">S. NU</th>')
      ..writeln('    <th style="width: 140px;">BİRLİĞİ</th>')
      ..writeln('    <th style="width: 130px;">RÜTBE</th>')
      ..writeln('    <th style="width: 220px;">ADI SOYADI</th>')
      ..writeln('    <th style="width: 160px;">DİĞER</th>')
      ..writeln('  </tr>');
  }

  /// Builds SpreadsheetML XML header rows.
  static void buildXmlHeader(StringBuffer buffer, String titleHeader) {
    buffer
      ..writeln('   <Row ss:Height="26">')
      ..writeln(
        '    <Cell ss:MergeAcross="4" ss:StyleID="MainTitle"><Data ss:Type="String">${ExcelCellStyler.escapeXml(titleHeader)}</Data></Cell>',
      )
      ..writeln('   </Row>')
      ..writeln('   <Row ss:Height="10"/>')
      ..writeln('   <Row ss:Height="22">')
      ..writeln(
        '    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">S. NU</Data></Cell>',
      )
      ..writeln(
        '    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">BİRLİĞİ</Data></Cell>',
      )
      ..writeln(
        '    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">RÜTBE</Data></Cell>',
      )
      ..writeln(
        '    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">ADI SOYADI</Data></Cell>',
      )
      ..writeln(
        '    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">DİĞER</Data></Cell>',
      )
      ..writeln('   </Row>');
  }
}

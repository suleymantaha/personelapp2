import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:share_plus/share_plus.dart';

class ExcelXmlGenerator {
  /// XML special character escaping helper
  static String escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Generates a SpreadsheetML XML document compatible with Microsoft Excel (.xls)
  static String generateXml({
    required List<PersonelTableData> personnel,
    required Map<int, Map<int, String>> matrixData,
    required int year,
    required int month,
  }) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="utf-8"?>')
      ..writeln('<?mso-application progid="Excel.Sheet"?>')
      ..writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"')
      ..writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"')
      ..writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">')
      ..writeln(' <Styles>')
      ..writeln('  <Style ss:ID="Default" ss:Name="Normal">')
      ..writeln('   <Alignment ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Segoe UI" ss:Size="10" ss:Color="#333333"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="Header">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Segoe UI" ss:Size="10" ss:Bold="1" ss:Color="#FFFFFF"/>')
      ..writeln('   <Interior ss:Color="#4A5D36" ss:Pattern="Solid"/>')
      ..writeln('   <Borders>')
      ..writeln('    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#2E3B21"/>')
      ..writeln('    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#2E3B21"/>')
      ..writeln('    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#2E3B21"/>')
      ..writeln('    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#2E3B21"/>')
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="GÖREVLİ">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Interior ss:Color="#C8E6C9" ss:Pattern="Solid"/>')
      ..writeln('   <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E0E0E0"/></Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="İZİNLİ">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Interior ss:Color="#E0E0E0" ss:Pattern="Solid"/>')
      ..writeln('   <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E0E0E0"/></Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="RAPORLU">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Interior ss:Color="#FFCDD2" ss:Pattern="Solid"/>')
      ..writeln('   <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E0E0E0"/></Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="BEKLEYEN">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Interior ss:Color="#FFF9C4" ss:Pattern="Solid"/>')
      ..writeln('   <Borders><Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#E0E0E0"/></Borders>')
      ..writeln('  </Style>')
      ..writeln(' </Styles>')
      ..writeln(' <Worksheet ss:Name="Aylık Faaliyet Matrisi">')
      ..writeln('  <Table>')
      ..writeln('   <Row>')
      ..writeln('    <Cell ss:StyleID="Header"><Data ss:Type="String">S.No</Data></Cell>')
      ..writeln('    <Cell ss:StyleID="Header"><Data ss:Type="String">Rütbesi ve Adı Soyadı</Data></Cell>');

    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var day = 1; day <= daysInMonth; day++) {
      buffer.writeln(
        '    <Cell ss:StyleID="Header"><Data ss:Type="Number">$day</Data></Cell>',
      );
    }
    buffer.writeln('   </Row>');

    // Personnel Data Rows
    for (var i = 0; i < personnel.length; i++) {
      final p = personnel[i];
      final escapedName = escapeXml('${p.rutbe} ${p.adSoyad}');

      buffer
        ..writeln('   <Row>')
        ..writeln('    <Cell><Data ss:Type="Number">${i + 1}</Data></Cell>')
        ..writeln('    <Cell><Data ss:Type="String">$escapedName</Data></Cell>');

      final pStatusMap = matrixData[p.id] ?? {};

      for (var day = 1; day <= daysInMonth; day++) {
        final status = pStatusMap[day] ?? '-';
        final escapedStatus = escapeXml(status);

        var styleId = '';
        if (status.contains('GÖREV') || status.contains('NÖBET')) {
          styleId = ' ss:StyleID="GÖREVLİ"';
        } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
          styleId = ' ss:StyleID="İZİNLİ"';
        } else if (status.contains('RAPOR') || status.contains('SEVK')) {
          styleId = ' ss:StyleID="RAPORLU"';
        } else if (status.contains('beklemede')) {
          styleId = ' ss:StyleID="BEKLEYEN"';
        }

        buffer.writeln(
          '    <Cell$styleId><Data ss:Type="String">$escapedStatus</Data></Cell>',
        );
      }
      buffer.writeln('   </Row>');
    }

    buffer
      ..writeln('  </Table>')
      ..writeln(' </Worksheet>')
      ..writeln('</Workbook>');

    return buffer.toString();
  }

  /// Exports XML content to a temporary .xls file and launches native share intent
  static Future<void> exportAndShareXml({
    required List<PersonelTableData> personnel,
    required Map<int, Map<int, String>> matrixData,
    required int year,
    required int month,
  }) async {
    final xmlContent = generateXml(
      personnel: personnel,
      matrixData: matrixData,
      year: year,
      month: month,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Faaliyet_Matrisi_${year}_$month.xls');
    await file.writeAsString(xmlContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Jandarma Görev Takip - Aylık Faaliyet Matrisi Excel Çıktısı',
      ),
    );
  }
}

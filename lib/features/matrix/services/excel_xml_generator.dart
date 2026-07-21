import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:share_plus/share_plus.dart';

class ExcelXmlGenerator {
  /// Generates a SpreadsheetML XML document compatible with Microsoft Excel (.xls)
  static String generateXml({
    required List<PersonelTableData> personnel,
    required Map<int, Map<int, String>> matrixData, // personelId -> (dayNumber -> status)
    required int year,
    required int month,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('<?xml version="1.0"?>');
    buffer.writeln('<?mso-application progid="Excel.Sheet"?>');
    buffer.writeln('<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"');
    buffer.writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"');
    buffer.writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"');
    buffer.writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">');

    buffer.writeln(' <Styles>');
    buffer.writeln('  <Style ss:ID="Header">');
    buffer.writeln('   <Font ss:Bold="1" ss:Color="#FFFFFF"/>');
    buffer.writeln('   <Interior ss:Color="#4A5D36" ss:Pattern="Solid"/>');
    buffer.writeln('  </Style>');
    buffer.writeln('  <Style ss:ID="GÖREVLİ">');
    buffer.writeln('   <Interior ss:Color="#C8E6C9" ss:Pattern="Solid"/>');
    buffer.writeln('  </Style>');
    buffer.writeln('  <Style ss:ID="NÖBETÇİ">');
    buffer.writeln('   <Interior ss:Color="#A5D6A7" ss:Pattern="Solid"/>');
    buffer.writeln('  </Style>');
    buffer.writeln('  <Style ss:ID="İZİNLİ">');
    buffer.writeln('   <Interior ss:Color="#E0E0E0" ss:Pattern="Solid"/>');
    buffer.writeln('  </Style>');
    buffer.writeln('  <Style ss:ID="RAPORLU">');
    buffer.writeln('   <Interior ss:Color="#FFCDD2" ss:Pattern="Solid"/>');
    buffer.writeln('  </Style>');
    buffer.writeln('  <Style ss:ID="BEKLEYEN">');
    buffer.writeln('   <Interior ss:Color="#FFF9C4" ss:Pattern="Solid"/>');
    buffer.writeln('  </Style>');
    buffer.writeln(' </Styles>');

    buffer.writeln(' <Worksheet ss:Name="Aylık Faaliyet Matrisi">');
    buffer.writeln('  <Table>');

    // Header Row
    buffer.writeln('   <Row>');
    buffer.writeln('    <Cell ss:StyleID="Header"><Data ss:Type="String">S.No</Data></Cell>');
    buffer.writeln('    <Cell ss:StyleID="Header"><Data ss:Type="String">Rütbesi ve Adı Soyadı</Data></Cell>');

    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (int day = 1; day <= daysInMonth; day++) {
      buffer.writeln(
          '    <Cell ss:StyleID="Header"><Data ss:Type="Number">$day</Data></Cell>');
    }
    buffer.writeln('   </Row>');

    // Personnel Data Rows
    for (int i = 0; i < personnel.length; i++) {
      final p = personnel[i];
      buffer.writeln('   <Row>');
      buffer.writeln(
          '    <Cell><Data ss:Type="Number">${i + 1}</Data></Cell>');
      buffer.writeln(
          '    <Cell><Data ss:Type="String">${p.rutbe} ${p.adSoyad}</Data></Cell>');

      final pStatusMap = matrixData[p.id] ?? {};

      for (int day = 1; day <= daysInMonth; day++) {
        final status = pStatusMap[day] ?? '-';
        String styleId = '';
        if (status.contains('GÖREV') || status.contains('NÖBET')) {
          styleId = ' ss:StyleID="GÖREVLİ"';
        } else if (status.contains('İZİN') || status.contains('İSTİRAHAT')) {
          styleId = ' ss:StyleID="İZİNLİ"';
        } else if (status.contains('RAPOR')) {
          styleId = ' ss:StyleID="RAPORLU"';
        } else if (status.contains('beklemede')) {
          styleId = ' ss:StyleID="BEKLEYEN"';
        }

        buffer.writeln(
            '    <Cell$styleId><Data ss:Type="String">$status</Data></Cell>');
      }
      buffer.writeln('   </Row>');
    }

    buffer.writeln('  </Table>');
    buffer.writeln(' </Worksheet>');
    buffer.writeln('</Workbook>');

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

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Jandarma Görev Takip - Aylık Faaliyet Matrisi Excel Çıktısı',
    );
  }
}

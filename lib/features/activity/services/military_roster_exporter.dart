import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MilitaryRosterRow {
  MilitaryRosterRow({
    required this.sNu,
    required this.birligi,
    required this.rutbe,
    required this.adSoyad,
    required this.diger,
  });

  final int sNu;
  final String birligi;
  final String rutbe;
  final String adSoyad;
  final String diger;
}

class MasterActivityData {
  MasterActivityData({
    required this.faaliyetAdi,
    required this.tarih,
    required this.olusturanKullanici,
    required this.rows,
  });

  final String faaliyetAdi;
  final String tarih;
  final String olusturanKullanici;
  final List<MilitaryRosterRow> rows;
}

class MilitaryRosterExporter {
  static String escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Generates SpreadsheetML XML (.xls) matching the official military daily activity duty list format
  static String generateMilitaryXml({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    final titleHeader = escapeXml('$faaliyetAdi İSİM LİSTESİ - $tarih'.toUpperCase());

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
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="11" ss:Color="#000000"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="MainTitle">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="13" ss:Bold="1" ss:Color="#1B365D"/>')
      ..writeln('   <Interior ss:Color="#E8EEF5" ss:Pattern="Solid"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="SubTitle">')
      ..writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#2D5A27"/>')
      ..writeln('   <Interior ss:Color="#F0F4EF" ss:Pattern="Solid"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="TableHeader">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#000000"/>')
      ..writeln('   <Interior ss:Color="#D9D9D9" ss:Pattern="Solid"/>')
      ..writeln('   <Borders>')
      ..writeln('    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>')
      ..writeln('    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>')
      ..writeln('    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>')
      ..writeln('    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>')
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellCenter">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Borders>')
      ..writeln('    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellLeft">')
      ..writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>')
      ..writeln('   <Borders>')
      ..writeln('    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln(' </Styles>')
      ..writeln(' <Worksheet ss:Name="İsim Listesi">')
      ..writeln('  <Table>')
      ..writeln('   <Column ss:Width="45"/>') // S.NU
      ..writeln('   <Column ss:Width="120"/>') // BİRLİĞİ
      ..writeln('   <Column ss:Width="110"/>') // RÜTBE
      ..writeln('   <Column ss:Width="180"/>') // ADI SOYADI
      ..writeln('   <Column ss:Width="160"/>') // DİĞER
      // Title Row
      ..writeln('   <Row ss:Height="26">')
      ..writeln('    <Cell ss:MergeAcross="4" ss:StyleID="MainTitle"><Data ss:Type="String">$titleHeader</Data></Cell>')
      ..writeln('   </Row>')
      // Empty spacing row
      ..writeln('   <Row ss:Height="10"/>')
      // Column Header Row
      ..writeln('   <Row ss:Height="22">')
      ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">S. NU</Data></Cell>')
      ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">BİRLİĞİ</Data></Cell>')
      ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">RÜTBE</Data></Cell>')
      ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">ADI SOYADI</Data></Cell>')
      ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">DİĞER</Data></Cell>')
      ..writeln('   </Row>');

    // Data Rows
    for (final r in rows) {
      buffer
        ..writeln('   <Row ss:Height="20">')
        ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="Number">${r.sNu}</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.birligi)}</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.rutbe)}</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.adSoyad)}</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.diger)}</Data></Cell>')
        ..writeln('   </Row>');
    }

    buffer
      ..writeln('  </Table>')
      ..writeln(' </Worksheet>')
      ..writeln('</Workbook>');

    return buffer.toString();
  }

  /// Generates multi-worksheet Master Excel combining all daily activities
  static String generateMasterDailyXml({
    required String title,
    required List<MasterActivityData> activities,
  }) {
    final mainHeader = escapeXml(title.toUpperCase());

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
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="11" ss:Color="#000000"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="MainTitle">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="14" ss:Bold="1" ss:Color="#1B365D"/>')
      ..writeln('   <Interior ss:Color="#E8EEF5" ss:Pattern="Solid"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="SectionHeader">')
      ..writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="12" ss:Bold="1" ss:Color="#2D5A27"/>')
      ..writeln('   <Interior ss:Color="#E2EFCB" ss:Pattern="Solid"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="TableHeader">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#000000"/>')
      ..writeln('   <Interior ss:Color="#D9D9D9" ss:Pattern="Solid"/>')
      ..writeln('   <Borders>')
      ..writeln('    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>')
      ..writeln('    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>')
      ..writeln('    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>')
      ..writeln('    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>')
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellCenter">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Borders>')
      ..writeln('    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellLeft">')
      ..writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>')
      ..writeln('   <Borders>')
      ..writeln('    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>')
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln(' </Styles>');

    // 1. Consolidated Worksheet (GENEL İCMAL LİSTESİ)
    buffer
      ..writeln(' <Worksheet ss:Name="GENEL İCMAL LİSTESİ">')
      ..writeln('  <Table>')
      ..writeln('   <Column ss:Width="45"/>')
      ..writeln('   <Column ss:Width="120"/>')
      ..writeln('   <Column ss:Width="110"/>')
      ..writeln('   <Column ss:Width="180"/>')
      ..writeln('   <Column ss:Width="160"/>')
      ..writeln('   <Row ss:Height="28">')
      ..writeln('    <Cell ss:MergeAcross="4" ss:StyleID="MainTitle"><Data ss:Type="String">$mainHeader</Data></Cell>')
      ..writeln('   </Row>')
      ..writeln('   <Row ss:Height="12"/>');

    var globalNu = 1;
    for (final act in activities) {
      final actHeader = escapeXml('GÖREV: ${act.faaliyetAdi.toUpperCase()} (Tarih: ${act.tarih} | Oluşturan: ${act.olusturanKullanici})');
      buffer
        ..writeln('   <Row ss:Height="24">')
        ..writeln('    <Cell ss:MergeAcross="4" ss:StyleID="SectionHeader"><Data ss:Type="String">$actHeader</Data></Cell>')
        ..writeln('   </Row>')
        ..writeln('   <Row ss:Height="22">')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">S. NU</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">BİRLİĞİ</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">RÜTBE</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">ADI SOYADI</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">GÖREV / AÇIKLAMA</Data></Cell>')
        ..writeln('   </Row>');

      for (final r in act.rows) {
        buffer
          ..writeln('   <Row ss:Height="20">')
          ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="Number">${globalNu++}</Data></Cell>')
          ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.birligi)}</Data></Cell>')
          ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.rutbe)}</Data></Cell>')
          ..writeln('    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.adSoyad)}</Data></Cell>')
          ..writeln('    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.diger)}</Data></Cell>')
          ..writeln('   </Row>');
      }

      buffer.writeln('   <Row ss:Height="12"/>');
    }

    buffer
      ..writeln('  </Table>')
      ..writeln(' </Worksheet>');


    // 2. Individual Worksheets per Activity
    var sheetIdx = 1;
    for (final act in activities) {
      final rawSheetName = '${sheetIdx++}. ${act.faaliyetAdi}';
      final cleanSheetName = escapeXml(rawSheetName.length > 30 ? rawSheetName.substring(0, 30) : rawSheetName);
      final titleHeader = escapeXml('${act.faaliyetAdi} İSİM LİSTESİ - ${act.tarih}'.toUpperCase());

      buffer
        ..writeln(' <Worksheet ss:Name="$cleanSheetName">')
        ..writeln('  <Table>')
        ..writeln('   <Column ss:Width="45"/>')
        ..writeln('   <Column ss:Width="120"/>')
        ..writeln('   <Column ss:Width="110"/>')
        ..writeln('   <Column ss:Width="180"/>')
        ..writeln('   <Column ss:Width="160"/>')
        ..writeln('   <Row ss:Height="26">')
        ..writeln('    <Cell ss:MergeAcross="4" ss:StyleID="MainTitle"><Data ss:Type="String">$titleHeader</Data></Cell>')
        ..writeln('   </Row>')
        ..writeln('   <Row ss:Height="10"/>')
        ..writeln('   <Row ss:Height="22">')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">S. NU</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">BİRLİĞİ</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">RÜTBE</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">ADI SOYADI</Data></Cell>')
        ..writeln('    <Cell ss:StyleID="TableHeader"><Data ss:Type="String">DİĞER</Data></Cell>')
        ..writeln('   </Row>');

      for (final r in act.rows) {
        buffer
          ..writeln('   <Row ss:Height="20">')
          ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="Number">${r.sNu}</Data></Cell>')
          ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.birligi)}</Data></Cell>')
          ..writeln('    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.rutbe)}</Data></Cell>')
          ..writeln('    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.adSoyad)}</Data></Cell>')
          ..writeln('    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.diger)}</Data></Cell>')
          ..writeln('   </Row>');
      }

      buffer
        ..writeln('  </Table>')
        ..writeln(' </Worksheet>');
    }

    buffer.writeln('</Workbook>');
    return buffer.toString();
  }

  /// Formats the roster into a clean ASCII table suitable for WhatsApp / Telegram
  static String generateMilitaryText({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    final titleHeader = '$faaliyetAdi İSİM LİSTESİ - $tarih'.toUpperCase();
    final sb = StringBuffer()
      ..writeln('==============================================')
      ..writeln(titleHeader)
      ..writeln('==============================================')
      ..writeln(
          'S.NU | BİRLİĞİ          | RÜTBE        | ADI SOYADI            | DİĞER')
      ..writeln(
          '----------------------------------------------------------------------');

    for (final r in rows) {
      final sNuStr = r.sNu.toString().padRight(4);
      final birlikStr = r.birligi.padRight(16);
      final rutbeStr = r.rutbe.padRight(12);
      final adStr = r.adSoyad.padRight(22);
      sb.writeln('$sNuStr| $birlikStr| $rutbeStr| $adStr| ${r.diger}');
    }

    sb.writeln('==============================================');
    return sb.toString();
  }

  /// Exports Excel XML and triggers native OS share
  static Future<void> shareExcelRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final xmlContent = generateMilitaryXml(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );

    final dir = await getTemporaryDirectory();
    final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final file = File('${dir.path}/${sanitizedTitle}_Listesi_$tarih.xls');
    await file.writeAsString(xmlContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$faaliyetAdi - Resmi İsim Listesi Excel Dökümanı',
      ),
    );
  }

  /// Shares Master Daily Excel containing all activities
  static Future<void> shareMasterDailyExcel({
    required String title,
    required String dateStr,
    required List<MasterActivityData> activities,
  }) async {
    final xmlContent = generateMasterDailyXml(
      title: title,
      activities: activities,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Gunluk_Tum_Faaliyetler_$dateStr.xls');
    await file.writeAsString(xmlContent);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$title - Günlük Tüm Faaliyetler Birleşik Excel Dökümanı',
      ),
    );
  }

  /// Shares the formatted text roster directly
  static Future<void> shareTextRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final text = generateMilitaryText(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );
    await SharePlus.instance.share(
      ShareParams(text: text),
    );
  }
}


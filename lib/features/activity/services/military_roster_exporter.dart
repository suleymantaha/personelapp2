import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:share_plus/share_plus.dart';

class MilitaryRosterRow {
  MilitaryRosterRow({
    required this.sNu,
    required this.birligi,
    required this.rutbe,
    required this.adSoyad,
    required this.diger,
    this.groupCode = 'DIGER',
  });

  final int sNu;
  final String birligi;
  final String rutbe;
  final String adSoyad;
  final String diger;
  final String groupCode; // 'DIGER', 'HAZIR_KITA', 'GULUSKUR'
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
        .replaceAll('"', '&quot;');
  }

  static String formatOfficialTitle(String faaliyetAdi, String rawDate) {
    var formattedDate = rawDate.trim();
    if (formattedDate.contains('-')) {
      final parts = formattedDate.split('T')[0].split('-');
      if (parts.length == 3) {
        formattedDate = '${parts[2]}.${parts[1]}.${parts[0]}';
      }
    }

    var nameStr = faaliyetAdi.trim().toUpperCase();

    // Remove any parenthesized date like (2026-07-24) or (24.07.2026)
    nameStr = nameStr
        .replaceAll(RegExp(r'\s*\(\d{2,4}[\.\-]\d{2}[\.\-]\d{2,4}\)\s*'), ' ')
        .trim();

    // Remove 'İSİM LİSTESİ' if present
    nameStr = nameStr
        .replaceAll('İSİM LİSTESİ', '')
        .replaceAll('ISIM LISTESI', '')
        .trim();

    final isCombinedDailyRoster = nameStr.contains('GÜNLÜK TÜM FAALİYET') ||
        nameStr.contains('GUNLUK TUM FAALIYET');
    if (isCombinedDailyRoster) {
      nameStr = 'GÜNLÜK TÜM FAALİYETLER';
    } else if (nameStr.isEmpty ||
        nameStr.contains('GÜNLÜK FAALİYET') ||
        nameStr.contains('GUNLUK FAALIYET')) {
      nameStr = 'HEYBET TEPE PUSU FAALİYETİ';
    }

    // Ensure starts with JÖH TB.K.LIĞI
    if (!nameStr.startsWith('JÖH')) {
      nameStr = 'JÖH TB.K.LIĞI $nameStr';
    }

    // Clean multiple spaces
    nameStr = nameStr.replaceAll(RegExp(r'\s+'), ' ').trim();

    return '$nameStr-$formattedDate';
  }

  /// Generates HTML Excel file (.xls) with UTF-8 BOM for 100% native mobile & desktop opening
  static String generateMilitaryHtmlExcel({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    final titleHeader = escapeXml(formatOfficialTitle(faaliyetAdi, tarih));

    final sb = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln(
        '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40">',
      )
      ..writeln('<head>')
      ..writeln(
        '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">',
      )
      ..writeln('<!--[if gte mso 9]>')
      ..writeln('<xml>')
      ..writeln(' <x:ExcelWorkbook>')
      ..writeln('  <x:ExcelWorksheets>')
      ..writeln('   <x:ExcelWorksheet>')
      ..writeln('    <x:Name>İsim Listesi</x:Name>')
      ..writeln('    <x:WorksheetOptions>')
      ..writeln('     <x:DisplayGridlines/>')
      ..writeln('    </x:WorksheetOptions>')
      ..writeln('   </x:ExcelWorksheet>')
      ..writeln('  </x:ExcelWorksheets>')
      ..writeln(' </x:ExcelWorkbook>')
      ..writeln('</xml>')
      ..writeln('<![endif]-->')
      ..writeln('<style>')
      ..writeln(
        '  table { border-collapse: collapse; font-family: Calibri, sans-serif; font-size: 11pt; width: 100%; }',
      )
      ..writeln(
        '  th { border: 1px solid #000000; background-color: #D9D9D9; font-weight: bold; text-align: center; vertical-align: middle; height: 26px; }',
      )
      ..writeln(
        '  td { border: 1px solid #000000; vertical-align: middle; padding: 5px 8px; }',
      )
      ..writeln('  .center { text-align: center; }')
      ..writeln('  .left { text-align: left; }')
      ..writeln('  .bold { font-weight: bold; }')
      ..writeln(
        '  .title { font-size: 14pt; font-weight: bold; text-align: center; background-color: #E8EEF5; height: 34px; border: 1px solid #000000; }',
      )
      ..writeln(
        '  .summary-hdr { font-weight: bold; background-color: #F2F2F2; border: 1px solid #000000; padding: 6px; }',
      )
      ..writeln('</style>')
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln('<table>')
      // Title Row
      ..writeln(
        '  <tr><td colspan="5" class="title">$titleHeader</td></tr>',
      )
      ..writeln(
        '  <tr style="height: 10px;"><td colspan="5" style="border: none;"></td></tr>',
      )
      // Table Headers
      ..writeln('  <tr>')
      ..writeln('    <th style="width: 50px;">S. NU</th>')
      ..writeln('    <th style="width: 140px;">BİRLİĞİ</th>')
      ..writeln('    <th style="width: 130px;">RÜTBE</th>')
      ..writeln('    <th style="width: 220px;">ADI SOYADI</th>')
      ..writeln('    <th style="width: 160px;">DİĞER</th>')
      ..writeln('  </tr>');

    // Data Rows with Vertical Merging
    var i = 0;
    final n = rows.length;

    while (i < n) {
      final currentBirlik = rows[i].birligi;
      final currentGroup = rows[i].groupCode;
      final isSpecialGroup =
          currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR';

      var mergeCount = 0;
      while (i + mergeCount + 1 < n &&
          rows[i + mergeCount + 1].birligi == currentBirlik &&
          rows[i + mergeCount + 1].groupCode == currentGroup) {
        mergeCount++;
      }

      final spanAttr = (mergeCount > 0) ? ' rowspan="${mergeCount + 1}"' : '';

      for (var j = 0; j <= mergeCount; j++) {
        final r = rows[i + j];
        sb
          ..writeln('  <tr>')
          // Column A: S. NU
          ..writeln('    <td class="center">${r.sNu}</td>');

        // Column B: BİRLİĞİ (Merged vertically)
        if (j == 0) {
          sb.writeln(
            '    <td$spanAttr class="center bold">${escapeXml(r.birligi)}</td>',
          );
        }

        // Column C: RÜTBE
        // Column D: ADI SOYADI
        sb
          ..writeln('    <td class="center">${escapeXml(r.rutbe)}</td>')
          ..writeln('    <td class="left">${escapeXml(r.adSoyad)}</td>');

        // Column E: DİĞER (Merged vertically for Hazır Kıta & Gülüşkür, normal for others)
        if (isSpecialGroup) {
          if (j == 0) {
            sb.writeln(
              '    <td$spanAttr class="center bold">${escapeXml(r.diger)}</td>',
            );
          }
        } else {
          sb.writeln('    <td class="left">${escapeXml(r.diger)}</td>');
        }

        sb.writeln('  </tr>');
      }

      i += mergeCount + 1;
    }

    // Summary Section
    var hazirKitaCount = 0;
    var guluskurCount = 0;
    var digerCount = 0;

    for (final r in rows) {
      if (r.groupCode == 'HAZIR_KITA') {
        hazirKitaCount++;
      } else if (r.groupCode == 'GULUSKUR') {
        guluskurCount++;
      } else {
        digerCount++;
      }
    }

    final ranks = rows.map((r) => r.rutbe).toList();
    final counts = RankSummaryCounts.calculate(ranks);

    sb
      ..writeln(
        '  <tr style="height: 12px;"><td colspan="5" style="border: none;"></td></tr>',
      )
      ..writeln(
        '  <tr><td colspan="5" class="summary-hdr">GÖREV VE MEVCUT ÖZETİ</td></tr>',
      );

    final dutySummaryStr =
        'Hazır Kıta: $hazirKitaCount Personel  •  Gülüşkür: $guluskurCount Personel  •  Diğer: $digerCount Personel';
    sb.writeln(
      '  <tr><td colspan="5" class="left bold">${escapeXml(dutySummaryStr)}</td></tr>',
    );

    final summaryItems = [
      if (counts.subayCount > 0) 'Subay: ${counts.subayCount}',
      if (counts.astsubayCount > 0) 'Astsubay: ${counts.astsubayCount}',
      if (counts.uzmanJandarmaCount > 0)
        'Uzman Jandarma: ${counts.uzmanJandarmaCount}',
      if (counts.uzmanErbasCount > 0) 'Uzman Erbaş: ${counts.uzmanErbasCount}',
      if (counts.erCount > 0) 'Er / Erbaş: ${counts.erCount}',
      'TOPLAM MEVCUT: ${counts.totalCount} Personel',
    ];

    for (final item in summaryItems) {
      sb.writeln(
        '  <tr><td colspan="5" class="left">${escapeXml(item)}</td></tr>',
      );
    }

    sb
      ..writeln('</table>')
      ..writeln('</body>')
      ..writeln('</html>');

    return sb.toString();
  }

  /// Generates SpreadsheetML XML (.xls) matching the official military daily activity duty list format
  static String generateMilitaryXml({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    final titleHeader = escapeXml(formatOfficialTitle(faaliyetAdi, tarih));

    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="utf-8"?>')
      ..writeln('<?mso-application progid="Excel.Sheet"?>')
      ..writeln(
        '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"',
      )
      ..writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"')
      ..writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"')
      ..writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">')
      ..writeln(' <Styles>')
      ..writeln('  <Style ss:ID="Default" ss:Name="Normal">')
      ..writeln('   <Alignment ss:Vertical="Center"/>')
      ..writeln(
        '   <Font ss:FontName="Calibri" ss:Size="11" ss:Color="#000000"/>',
      )
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="MainTitle">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln(
        '   <Font ss:FontName="Calibri" ss:Size="13" ss:Bold="1" ss:Color="#1B365D"/>',
      )
      ..writeln('   <Interior ss:Color="#E8EEF5" ss:Pattern="Solid"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="SubTitle">')
      ..writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>')
      ..writeln(
        '   <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#2D5A27"/>',
      )
      ..writeln('   <Interior ss:Color="#F0F4EF" ss:Pattern="Solid"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="TableHeader">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln(
        '   <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#000000"/>',
      )
      ..writeln('   <Interior ss:Color="#D9D9D9" ss:Pattern="Solid"/>')
      ..writeln('   <Borders>')
      ..writeln(
        '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>',
      )
      ..writeln(
        '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>',
      )
      ..writeln(
        '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>',
      )
      ..writeln(
        '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>',
      )
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellCenter">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Borders>')
      ..writeln(
        '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellCenterBold">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1"/>')
      ..writeln('   <Borders>')
      ..writeln(
        '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellLeft">')
      ..writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>')
      ..writeln('   <Borders>')
      ..writeln(
        '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln(' </Styles>')
      ..writeln(' <Worksheet ss:Name="İsim Listesi">')
      ..writeln('  <Table>')
      ..writeln('   <Column ss:Width="45"/>')
      ..writeln('   <Column ss:Width="120"/>')
      ..writeln('   <Column ss:Width="110"/>')
      ..writeln('   <Column ss:Width="180"/>')
      ..writeln('   <Column ss:Width="160"/>')
      ..writeln('   <Row ss:Height="26">')
      ..writeln(
        '    <Cell ss:MergeAcross="4" ss:StyleID="MainTitle"><Data ss:Type="String">$titleHeader</Data></Cell>',
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

    var i = 0;
    final n = rows.length;

    while (i < n) {
      final currentBirlik = rows[i].birligi;
      final currentGroup = rows[i].groupCode;
      final isSpecialGroup =
          currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR';

      var mergeCount = 0;
      while (i + mergeCount + 1 < n &&
          rows[i + mergeCount + 1].birligi == currentBirlik &&
          rows[i + mergeCount + 1].groupCode == currentGroup) {
        mergeCount++;
      }

      for (var j = 0; j <= mergeCount; j++) {
        final r = rows[i + j];
        buffer
          ..writeln('   <Row ss:Height="20">')
          ..writeln(
            '    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="Number">${r.sNu}</Data></Cell>',
          );

        if (j == 0) {
          final mergeAttr = mergeCount > 0 ? ' ss:MergeDown="$mergeCount"' : '';
          buffer.writeln(
            '    <Cell$mergeAttr ss:StyleID="DataCellCenterBold"><Data ss:Type="String">${escapeXml(r.birligi)}</Data></Cell>',
          );
        }

        buffer
          ..writeln(
            '    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.rutbe)}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.adSoyad)}</Data></Cell>',
          );

        if (isSpecialGroup) {
          if (j == 0) {
            final mergeAttr =
                mergeCount > 0 ? ' ss:MergeDown="$mergeCount"' : '';
            buffer.writeln(
              '    <Cell$mergeAttr ss:StyleID="DataCellCenterBold"><Data ss:Type="String">${escapeXml(r.diger)}</Data></Cell>',
            );
          }
        } else {
          buffer.writeln(
            '    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.diger)}</Data></Cell>',
          );
        }

        buffer.writeln('   </Row>');
      }

      i += mergeCount + 1;
    }

    final ranks = rows.map((r) => r.rutbe).toList();
    final counts = RankSummaryCounts.calculate(ranks);

    buffer
      ..writeln('   <Row ss:Height="12"/>')
      ..writeln('   <Row ss:Height="22">')
      ..writeln(
        '    <Cell ss:MergeAcross="4" ss:StyleID="SubTitle"><Data ss:Type="String">GÖREV VE MEVCUT ÖZETİ</Data></Cell>',
      )
      ..writeln('   </Row>');

    final summaryItems = [
      if (counts.subayCount > 0) 'Subay: ${counts.subayCount}',
      if (counts.astsubayCount > 0) 'Astsubay: ${counts.astsubayCount}',
      if (counts.uzmanJandarmaCount > 0)
        'Uzman Jandarma: ${counts.uzmanJandarmaCount}',
      if (counts.uzmanErbasCount > 0) 'Uzman Erbaş: ${counts.uzmanErbasCount}',
      if (counts.erCount > 0) 'Er / Erbaş: ${counts.erCount}',
      'TOPLAM MEVCUT: ${counts.totalCount}',
    ];

    for (final item in summaryItems) {
      buffer
        ..writeln('   <Row ss:Height="18">')
        ..writeln(
          '    <Cell ss:MergeAcross="4" ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(item)}</Data></Cell>',
        )
        ..writeln('   </Row>');
    }

    buffer
      ..writeln('  </Table>')
      ..writeln(' </Worksheet>')
      ..writeln('</Workbook>');

    return buffer.toString();
  }

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
        'S.NU | BİRLİĞİ          | RÜTBE        | ADI SOYADI            | DİĞER',
      )
      ..writeln(
        '----------------------------------------------------------------------',
      );

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

  /// Generates native binary .xlsx spreadsheet matching the official military daily activity duty list format
  static List<int> generateMilitaryExcelBytes({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'İsim Listesi';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final titleHeader = formatOfficialTitle(faaliyetAdi, tarih);

    final titleStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#1B365D'),
      backgroundColorHex: ExcelColor.fromHexString('#E8EEF5'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellCenterStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellCenterBoldStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellLeftStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final summaryHdrStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      fontColorHex: ExcelColor.fromHexString('#2D5A27'),
      backgroundColorHex: ExcelColor.fromHexString('#F0F4EF'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    // Row 0: Title Header
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue(titleHeader)
      ..cellStyle = titleStyle;

    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0),
    );

    // Row 2: Table Headers
    final headers = ['S. NU', 'BİRLİĞİ', 'RÜTBE', 'ADI SOYADI', 'DİĞER'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 2))
        ..value = TextCellValue(headers[c])
        ..cellStyle = headerStyle;
    }

    var currentRow = 3;
    var i = 0;
    final n = rows.length;

    while (i < n) {
      final currentBirlik = rows[i].birligi;
      final currentGroup = rows[i].groupCode;
      final isSpecialGroup =
          currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR';

      var mergeCount = 0;
      while (i + mergeCount + 1 < n &&
          rows[i + mergeCount + 1].birligi == currentBirlik &&
          rows[i + mergeCount + 1].groupCode == currentGroup) {
        mergeCount++;
      }

      final startRowIndex = currentRow;

      for (var j = 0; j <= mergeCount; j++) {
        final r = rows[i + j];
        final rIndex = startRowIndex + j;

        // Col 0: S. NU
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIndex))
          ..value = IntCellValue(r.sNu)
          ..cellStyle = cellCenterStyle;

        // Col 1: BİRLİĞİ
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIndex))
          ..value = TextCellValue(r.birligi)
          ..cellStyle = cellCenterBoldStyle;

        // Col 2: RÜTBE
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIndex))
          ..value = TextCellValue(r.rutbe)
          ..cellStyle = cellCenterStyle;

        // Col 3: ADI SOYADI
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rIndex))
          ..value = TextCellValue(r.adSoyad)
          ..cellStyle = cellLeftStyle;

        // Col 4: DİĞER
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rIndex))
          ..value = TextCellValue(r.diger)
          ..cellStyle = isSpecialGroup ? cellCenterBoldStyle : cellLeftStyle;
      }

      if (mergeCount > 0) {
        sheet.merge(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: startRowIndex),
          CellIndex.indexByColumnRow(
            columnIndex: 1,
            rowIndex: startRowIndex + mergeCount,
          ),
        );

        if (isSpecialGroup) {
          sheet.merge(
            CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: startRowIndex),
            CellIndex.indexByColumnRow(
              columnIndex: 4,
              rowIndex: startRowIndex + mergeCount,
            ),
          );
        }
      }

      currentRow += mergeCount + 1;
      i += mergeCount + 1;
    }

    // Summary Section
    currentRow += 1;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue('GÖREV VE MEVCUT ÖZETİ')
      ..cellStyle = summaryHdrStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
    );
    currentRow++;

    final ranks = rows.map((r) => r.rutbe).toList();
    final counts = RankSummaryCounts.calculate(ranks);

    final summaryItems = [
      if (counts.subayCount > 0) 'Subay: ${counts.subayCount}',
      if (counts.astsubayCount > 0) 'Astsubay: ${counts.astsubayCount}',
      if (counts.uzmanJandarmaCount > 0)
        'Uzman Jandarma: ${counts.uzmanJandarmaCount}',
      if (counts.uzmanErbasCount > 0) 'Uzman Erbaş: ${counts.uzmanErbasCount}',
      if (counts.erCount > 0) 'Er / Erbaş: ${counts.erCount}',
      'TOPLAM MEVCUT: ${counts.totalCount}',
    ];

    for (final item in summaryItems) {
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      )
        ..value = TextCellValue(item)
        ..cellStyle = cellLeftStyle;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
      );
      currentRow++;
    }

    sheet
      ..setColumnWidth(0, 10)
      ..setColumnWidth(1, 22)
      ..setColumnWidth(2, 18)
      ..setColumnWidth(3, 30)
      ..setColumnWidth(4, 25);

    final encoded = excel.encode();
    return encoded ?? <int>[];
  }

  /// Generates native binary .xlsx spreadsheet for all daily activities combined
  static List<int> generateMasterDailyExcelBytes({
    required String title,
    required List<MasterActivityData> activities,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Tüm Faaliyetler';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final titleStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#1B365D'),
      backgroundColorHex: ExcelColor.fromHexString('#E8EEF5'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final sectionHeaderStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#2D5A27'),
      backgroundColorHex: ExcelColor.fromHexString('#E2EFCB'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellCenterStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellLeftStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
    );

    var currentRow = 0;

    // Main Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow))
      ..value = TextCellValue(title)
      ..cellStyle = titleStyle;
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
    );
    currentRow++;

    final headers = ['S. NU', 'BİRLİĞİ', 'RÜTBE', 'ADI SOYADI', 'DİĞER'];

    for (final act in activities) {
      currentRow++; // Spacing
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      )
        ..value = TextCellValue(
          '${act.faaliyetAdi.toUpperCase()} (${act.tarih})',
        )
        ..cellStyle = sectionHeaderStyle;
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
      );
      currentRow++;

      for (var c = 0; c < headers.length; c++) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow),
        )
          ..value = TextCellValue(headers[c])
          ..cellStyle = headerStyle;
      }
      currentRow++;

      for (final r in act.rows) {
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        )
          ..value = IntCellValue(r.sNu)
          ..cellStyle = cellCenterStyle;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        )
          ..value = TextCellValue(r.birligi)
          ..cellStyle = cellCenterStyle;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
        )
          ..value = TextCellValue(r.rutbe)
          ..cellStyle = cellCenterStyle;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
        )
          ..value = TextCellValue(r.adSoyad)
          ..cellStyle = cellLeftStyle;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
        )
          ..value = TextCellValue(r.diger)
          ..cellStyle = cellLeftStyle;
        currentRow++;
      }
    }

    sheet
      ..setColumnWidth(0, 10)
      ..setColumnWidth(1, 22)
      ..setColumnWidth(2, 18)
      ..setColumnWidth(3, 30)
      ..setColumnWidth(4, 25);

    final encoded = excel.encode();
    return encoded ?? <int>[];
  }

  /// Exports Excel roster with native binary .xlsx and triggers OS share
  static Future<void> shareExcelRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final bytes = generateMilitaryExcelBytes(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );

    final dir = await getTemporaryDirectory();
    final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final exportId = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${dir.path}/${sanitizedTitle}_Listesi_${tarih}_$exportId.xlsx',
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$faaliyetAdi - Resmi İsim Listesi Excel Dökümanı',
      ),
    );
  }

  /// Saves Excel file directly to the device's public Downloads / Storage folder
  static Future<File> saveExcelToDevice({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final bytes = generateMilitaryExcelBytes(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );

    final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final fileName = '${sanitizedTitle}_Listesi_$tarih.xlsx';

    Directory targetDir;
    try {
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!targetDir.existsSync()) {
          targetDir = await getApplicationDocumentsDirectory();
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final userHome =
            Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
        if (userHome != null) {
          targetDir = Directory('$userHome/Downloads');
        } else {
          targetDir = await getApplicationDocumentsDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (!targetDir.existsSync()) {
        await targetDir.create(recursive: true);
      }

      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    } on Exception catch (_) {
      targetDir = await getApplicationDocumentsDirectory();
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return file;
    }
  }

  /// Shares Master Daily Excel containing all activities
  static Future<void> shareMasterDailyExcel({
    required String title,
    required String dateStr,
    required List<MasterActivityData> activities,
  }) async {
    final bytes = generateMasterDailyExcelBytes(
      title: title,
      activities: activities,
    );

    final dir = await getTemporaryDirectory();
    final exportId = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${dir.path}/Gunluk_Tum_Faaliyetler_${dateStr}_$exportId.xlsx',
    );
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$title - Günlük Tüm Faaliyetler Birleşik Excel Dökümanı',
      ),
    );
  }

  /// Master XML generator helper
  static String generateMasterDailyXml({
    required String title,
    required List<MasterActivityData> activities,
  }) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="utf-8"?>')
      ..writeln('<?mso-application progid="Excel.Sheet"?>')
      ..writeln(
        '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"',
      )
      ..writeln(' xmlns:o="urn:schemas-microsoft-com:office:office"')
      ..writeln(' xmlns:x="urn:schemas-microsoft-com:office:excel"')
      ..writeln(' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"')
      ..writeln(' xmlns:html="http://www.w3.org/TR/REC-html40">')
      ..writeln(' <Styles>')
      ..writeln('  <Style ss:ID="Default" ss:Name="Normal">')
      ..writeln('   <Alignment ss:Vertical="Center"/>')
      ..writeln(
        '   <Font ss:FontName="Calibri" ss:Size="11" ss:Color="#000000"/>',
      )
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="MainTitle">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln(
        '   <Font ss:FontName="Calibri" ss:Size="14" ss:Bold="1" ss:Color="#1B365D"/>',
      )
      ..writeln('   <Interior ss:Color="#E8EEF5" ss:Pattern="Solid"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="SectionHeader">')
      ..writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>')
      ..writeln(
        '   <Font ss:FontName="Calibri" ss:Size="12" ss:Bold="1" ss:Color="#2D5A27"/>',
      )
      ..writeln('   <Interior ss:Color="#E2EFCB" ss:Pattern="Solid"/>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="TableHeader">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln(
        '   <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#000000"/>',
      )
      ..writeln('   <Interior ss:Color="#D9D9D9" ss:Pattern="Solid"/>')
      ..writeln('   <Borders>')
      ..writeln(
        '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>',
      )
      ..writeln(
        '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>',
      )
      ..writeln(
        '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>',
      )
      ..writeln(
        '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#000000"/>',
      )
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellCenter">')
      ..writeln('   <Alignment ss:Horizontal="Center" ss:Vertical="Center"/>')
      ..writeln('   <Borders>')
      ..writeln(
        '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln('  <Style ss:ID="DataCellLeft">')
      ..writeln('   <Alignment ss:Horizontal="Left" ss:Vertical="Center"/>')
      ..writeln('   <Borders>')
      ..writeln(
        '    <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Left" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Right" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln(
        '    <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#B0B0B0"/>',
      )
      ..writeln('   </Borders>')
      ..writeln('  </Style>')
      ..writeln(' </Styles>')
      ..writeln(' <Worksheet ss:Name="Tüm Faaliyetler">')
      ..writeln('  <Table>')
      ..writeln('   <Column ss:Width="45"/>')
      ..writeln('   <Column ss:Width="120"/>')
      ..writeln('   <Column ss:Width="110"/>')
      ..writeln('   <Column ss:Width="180"/>')
      ..writeln('   <Column ss:Width="160"/>')
      ..writeln('   <Row ss:Height="28">')
      ..writeln(
        '    <Cell ss:MergeAcross="4" ss:StyleID="MainTitle"><Data ss:Type="String">${escapeXml(title)}</Data></Cell>',
      )
      ..writeln('   </Row>');

    for (final act in activities) {
      buffer
        ..writeln('   <Row ss:Height="12"/>')
        ..writeln('   <Row ss:Height="22">')
        ..writeln(
          '    <Cell ss:MergeAcross="4" ss:StyleID="SectionHeader"><Data ss:Type="String">${escapeXml(act.faaliyetAdi.toUpperCase())} (${act.tarih})</Data></Cell>',
        )
        ..writeln('   </Row>')
        ..writeln('   <Row ss:Height="20">')
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

      for (final r in act.rows) {
        buffer
          ..writeln('   <Row ss:Height="20">')
          ..writeln(
            '    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="Number">${r.sNu}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.birligi)}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${escapeXml(r.rutbe)}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.adSoyad)}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${escapeXml(r.diger)}</Data></Cell>',
          )
          ..writeln('   </Row>');
      }
    }

    buffer
      ..writeln('  </Table>')
      ..writeln(' </Worksheet>')
      ..writeln('</Workbook>');

    return buffer.toString();
  }

  /// Shares formatted text roster
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

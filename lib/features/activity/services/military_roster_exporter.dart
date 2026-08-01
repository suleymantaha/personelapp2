import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/core/utils/official_roster_title.dart';
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
  final String groupCode; // DIGER, NOBET_HEYETI, HAZIR_KITA, GULUSKUR
}

class MasterActivityData {
  MasterActivityData({
    required this.faaliyetAdi,
    required this.tarih,
    required this.olusturanKullanici,
    required this.rows,
    this.olusturmaTarihi = '',
  });

  final String faaliyetAdi;
  final String tarih;
  final String olusturanKullanici;
  final List<MilitaryRosterRow> rows;
  final String olusturmaTarihi;

  String get sectionHeader {
    final parsed = DateTime.tryParse(olusturmaTarihi);
    final time = parsed == null
        ? ''
        : '${parsed.hour.toString().padLeft(2, '0')}:'
            '${parsed.minute.toString().padLeft(2, '0')}';
    final details = [
      tarih,
      if (time.isNotEmpty) time,
      if (olusturanKullanici.trim().isNotEmpty) olusturanKullanici.trim(),
    ].join(' - ');
    return '${faaliyetAdi.toUpperCase()} ($details)';
  }
}

class MilitaryRosterExporter {
  static const _summaryGroups = [
    ('Hazır Kıta', 'HAZIR_KITA'),
    ('Gülüşkür', 'GULUSKUR'),
    ('Diğer Tüm Personel', 'DIGER_TUM_PERSONEL'),
  ];

  static String escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String formatOfficialTitle(String faaliyetAdi, String rawDate) {
    return OfficialRosterTitle.format(faaliyetAdi, rawDate);
  }

  static String specialDutyRankSummary(
    String label,
    String groupCode,
    List<MilitaryRosterRow> rows,
  ) {
    final groupRows = rows.where((row) => row.groupCode == groupCode).toList();
    final counts = RankSummaryCounts.calculate(
      groupRows.map((row) => row.rutbe).toList(),
    );
    return '$label: ${counts.totalCount} Personel '
        '(Subay: ${counts.subayCount} • '
        'Astsubay: ${counts.astsubayCount} • '
        'Uzman Jandarma: ${counts.uzmanJandarmaCount} • '
        'Uzman Erbaş: ${counts.uzmanErbasCount} • '
        'Diğer: ${counts.digerCount})';
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

      var mergeCount = 0;
      while (i + mergeCount + 1 < n &&
          _sameBirlik(rows[i + mergeCount + 1].birligi, currentBirlik) &&
          rows[i + mergeCount + 1].groupCode == currentGroup) {
        mergeCount++;
      }
      final isSpecialGroup =
          (currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR') &&
              List.generate(
                mergeCount + 1,
                (offset) => rows[i + offset].groupCode,
              ).every((groupCode) => groupCode == currentGroup);

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
    var digerCount = 0;

    for (final r in rows) {
      if (r.groupCode != 'HAZIR_KITA' && r.groupCode != 'GULUSKUR') {
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

    final dutySummaryItems = [
      specialDutyRankSummary('Hazır Kıta', 'HAZIR_KITA', rows),
      specialDutyRankSummary('Gülüşkür', 'GULUSKUR', rows),
      'Diğer Görevler: $digerCount Personel',
    ];
    for (final item in dutySummaryItems) {
      sb.writeln(
        '  <tr><td colspan="5" class="left bold">${escapeXml(item)}</td></tr>',
      );
    }

    final summaryItems = [
      specialDutyRankSummary('Hazır Kıta', 'HAZIR_KITA', rows),
      specialDutyRankSummary('Gülüşkür', 'GULUSKUR', rows),
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

      var mergeCount = 0;
      while (i + mergeCount + 1 < n &&
          _sameBirlik(rows[i + mergeCount + 1].birligi, currentBirlik) &&
          rows[i + mergeCount + 1].groupCode == currentGroup) {
        mergeCount++;
      }
      final isSpecialGroup =
          (currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR') &&
              List.generate(
                mergeCount + 1,
                (offset) => rows[i + offset].groupCode,
              ).every((groupCode) => groupCode == currentGroup);

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
      specialDutyRankSummary('Hazır Kıta', 'HAZIR_KITA', rows),
      specialDutyRankSummary('Gülüşkür', 'GULUSKUR', rows),
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
    final titleHeader = formatOfficialTitle(faaliyetAdi, tarih);
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
    final tableBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#000000'),
    );

    final titleStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#1B365D'),
      backgroundColorHex: ExcelColor.fromHexString('#E8EEF5'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final cellCenterStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final cellCenterBoldStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final cellLeftStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final summaryHeaderStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    // Row 0: Title Header
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      .value = TextCellValue(titleHeader);

    _mergeAndSetOuterBorders(
      sheet,
      startCol: 0,
      startRow: 0,
      endCol: 4,
      endRow: 0,
      baseStyle: titleStyle,
      outerBorder: _noneBorder,
    );
    sheet.setRowHeight(0, 30);

    // Row 1: Table Headers
    final headers = ['S. NU', 'BİRLİĞİ', 'RÜTBE', 'ADI SOYADI', 'DİĞER'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
        ..value = TextCellValue(headers[c])
        ..cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 24);

    var currentRow = 2;
    var i = 0;
    final n = rows.length;

    while (i < n) {
      final currentBirlik = rows[i].birligi;
      final currentGroup = rows[i].groupCode;

      var mergeCount = 0;
      while (i + mergeCount + 1 < n &&
          _sameBirlik(rows[i + mergeCount + 1].birligi, currentBirlik) &&
          rows[i + mergeCount + 1].groupCode == currentGroup) {
        mergeCount++;
      }
      final isSpecialGroup =
          (currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR') &&
              List.generate(
                mergeCount + 1,
                (offset) => rows[i + offset].groupCode,
              ).every((groupCode) => groupCode == currentGroup);

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
          ..value = j == 0 ? TextCellValue(r.birligi) : null
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
          ..value = !isSpecialGroup || j == 0 ? TextCellValue(r.diger) : null
          ..cellStyle = isSpecialGroup ? cellCenterBoldStyle : cellLeftStyle;
        sheet.setRowHeight(
          rIndex,
          _excelRowHeightFor(r.adSoyad, r.diger, r.rutbe),
        );
      }

      if (mergeCount > 0) {
        _mergeAndSetOuterBorders(
          sheet,
          startCol: 1,
          startRow: startRowIndex,
          endCol: 1,
          endRow: startRowIndex + mergeCount,
          baseStyle: cellCenterBoldStyle,
        );

        if (isSpecialGroup) {
          _mergeAndSetOuterBorders(
            sheet,
            startCol: 4,
            startRow: startRowIndex,
            endCol: 4,
            endRow: startRowIndex + mergeCount,
            baseStyle: cellCenterBoldStyle,
          );
        }
      }

      currentRow += mergeCount + 1;
      i += mergeCount + 1;
    }

    final lastPersonnelRowNumber = currentRow;

    currentRow += 1;
    _writeThreeBoxSummary(
      sheet: sheet,
      startRow: currentRow,
      rows: rows,
      headerStyle: summaryHeaderStyle,
      contentStyle: cellLeftStyle,
    );

    sheet
      ..setColumnWidth(0, 10)
      ..setColumnWidth(1, 22)
      ..setColumnWidth(2, 18)
      ..setColumnWidth(3, 30)
      ..setColumnWidth(4, 25)
      ..setColumnWidth(5, 7);

    final encoded = excel.encode();
    if (encoded == null) return <int>[];
    return _applyPrintSettings(
      encoded,
      sheetName: sheetName,
      endRow: lastPersonnelRowNumber,
      endColumn: 'E',
      repeatHeaderRange: r'$1:$2',
    );
  }

  static double _excelRowHeightFor(String name, String detail, String rank) {
    final longest = [name.length, detail.length, rank.length]
        .fold<int>(0, (max, length) => length > max ? length : max);
    return longest > 32 ? 32 : 20;
  }

  static final _tableBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: ExcelColor.fromHexString('#000000'),
  );

  static final _noneBorder = Border(
    borderStyle: BorderStyle.None,
  );

  static void _mergeAndSetOuterBorders(
    Sheet sheet, {
    required int startCol,
    required int startRow,
    required int endCol,
    required int endRow,
    required CellStyle baseStyle,
    Border? outerBorder,
  }) {
    final border = outerBorder ?? _tableBorder;
    final isNone = outerBorder == _noneBorder;

    for (var r = startRow; r <= endRow; r++) {
      for (var c = startCol; c <= endCol; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );

        final left = isNone
            ? _noneBorder
            : (c == startCol ? border : _noneBorder);
        final right = isNone
            ? _noneBorder
            : (c == endCol || (r == startRow && c == startCol)
                ? border
                : _noneBorder);
        final top = isNone
            ? _noneBorder
            : (r == startRow ? border : _noneBorder);
        final bottom = isNone
            ? _noneBorder
            : (r == endRow || (r == startRow && c == startCol)
                ? border
                : _noneBorder);

        cell.cellStyle = CellStyle(
          bold: baseStyle.isBold,
          italic: baseStyle.isItalic,
          underline: baseStyle.underline,
          fontSize: baseStyle.fontSize,
          fontFamily: baseStyle.fontFamily,
          fontColorHex: baseStyle.fontColor,
          backgroundColorHex: baseStyle.backgroundColor,
          horizontalAlign: baseStyle.horizontalAlignment,
          verticalAlign: baseStyle.verticalAlignment,
          textWrapping: baseStyle.wrap,
          leftBorder: left,
          rightBorder: right,
          topBorder: top,
          bottomBorder: bottom,
        );
      }
    }

    if (startCol != endCol || startRow != endRow) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: startRow),
        CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: endRow),
      );
    }
  }

  static int _writeThreeBoxSummary({
    required Sheet sheet,
    required int startRow,
    required List<MilitaryRosterRow> rows,
    required CellStyle headerStyle,
    required CellStyle contentStyle,
  }) {
    final summaries = _summaryGroups.map((group) {
      final groupRows = group.$2 == 'DIGER_TUM_PERSONEL'
          ? rows
              .where(
                (row) =>
                    row.groupCode != 'HAZIR_KITA' &&
                    row.groupCode != 'GULUSKUR',
              )
              .toList()
          : rows.where((row) => row.groupCode == group.$2).toList();
      return (
        group.$1,
        RankSummaryCounts.calculate(
          groupRows.map((row) => row.rutbe).toList(),
        )
      );
    }).toList();

    const columnPairs = [(0, 1), (2, 3), (4, 5)];
    for (var index = 0; index < summaries.length; index++) {
      final pair = columnPairs[index];
      _writeMergedSummaryCell(
        sheet,
        row: startRow,
        startColumn: pair.$1,
        endColumn: pair.$2,
        value: summaries[index].$1,
        style: headerStyle,
      );
    }

    final detailRows =
        summaries.map((summary) => _rankSummaryLines(summary.$2)).toList();
    final maxRankLines = detailRows
        .map((lines) => lines.length)
        .fold<int>(0, (maximum, length) => length > maximum ? length : maximum);

    for (var index = 0; index < summaries.length; index++) {
      final pair = columnPairs[index];
      final lines = detailRows[index];
      for (var offset = 0; offset < maxRankLines; offset++) {
        _writeMergedSummaryCell(
          sheet,
          row: startRow + 1 + offset,
          startColumn: pair.$1,
          endColumn: pair.$2,
          value: offset < lines.length ? lines[offset] : '',
          style: contentStyle,
        );
      }
      _writeMergedSummaryCell(
        sheet,
        row: startRow + maxRankLines + 1,
        startColumn: pair.$1,
        endColumn: pair.$2,
        value: 'Toplam ${summaries[index].$2.totalCount}',
        style: contentStyle,
      );
    }
    return startRow + maxRankLines + 1;
  }

  static List<String> _rankSummaryLines(RankSummaryCounts counts) => [
        if (counts.subayCount > 0) 'SB. ${counts.subayCount}',
        if (counts.astsubayCount > 0) 'ASB. ${counts.astsubayCount}',
        if (counts.uzmanJandarmaCount > 0)
          'UZM.J. ${counts.uzmanJandarmaCount}',
        if (counts.uzmanErbasCount > 0) 'J.UZM.ÇVŞ. ${counts.uzmanErbasCount}',
        if (counts.erCount > 0) 'ER/SÖZ.ER ${counts.erCount}',
      ];

  static void _writeMergedSummaryCell(
    Sheet sheet, {
    required int row,
    required int startColumn,
    required int endColumn,
    required String value,
    required CellStyle style,
  }) {
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: startColumn, rowIndex: row),
        )
        .value = TextCellValue(value);

    _mergeAndSetOuterBorders(
      sheet,
      startCol: startColumn,
      startRow: row,
      endCol: endColumn,
      endRow: row,
      baseStyle: style,
    );
  }

  static List<int> _applyPrintSettings(
    List<int> bytes, {
    required String sheetName,
    required int endRow,
    required String endColumn,
    required String repeatHeaderRange,
  }) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final workbookFile = archive.findFile('xl/workbook.xml');
    if (workbookFile == null) return bytes;

    var workbookXml = utf8.decode(workbookFile.content as List<int>);
    workbookXml = workbookXml.replaceAll(
      RegExp(
        r'<definedName\b[^>]*\bname="_xlnm\.Print_Area"[^>]*>.*?</definedName>',
        dotAll: true,
      ),
      '',
    );
    workbookXml = workbookXml.replaceAll(
      RegExp(
        r'<definedName\b[^>]*\bname="_xlnm\.Print_Titles"[^>]*>.*?</definedName>',
        dotAll: true,
      ),
      '',
    );
    final escapedSheetName = sheetName.replaceAll("'", "''");
    final printArea = '<definedName name="_xlnm.Print_Area" localSheetId="0">'
        "'$escapedSheetName'!\$A\$1:\$$endColumn\$$endRow"
        '</definedName>';
    final printTitles =
        '<definedName name="_xlnm.Print_Titles" localSheetId="0">'
        "'$escapedSheetName'!$repeatHeaderRange"
        '</definedName>';
    if (workbookXml.contains('<definedNames/>')) {
      workbookXml = workbookXml.replaceFirst(
        '<definedNames/>',
        '<definedNames>$printArea$printTitles</definedNames>',
      );
    } else if (workbookXml.contains('</definedNames>')) {
      workbookXml = workbookXml.replaceFirst(
        '</definedNames>',
        '$printArea$printTitles</definedNames>',
      );
    } else {
      final definedNames =
          '<definedNames>$printArea$printTitles</definedNames>';
      workbookXml = workbookXml.contains('<calcPr')
          ? workbookXml.replaceFirst('<calcPr', '$definedNames<calcPr')
          : workbookXml.replaceFirst(
              '</workbook>',
              '$definedNames</workbook>',
            );
    }

    final workbookBytes = utf8.encode(workbookXml);
    archive.addFile(
      ArchiveFile(
        'xl/workbook.xml',
        workbookBytes.length,
        workbookBytes,
      ),
    );

    final worksheetFile = archive.files.cast<ArchiveFile?>().firstWhere(
          (file) =>
              file != null &&
              file.name.startsWith('xl/worksheets/sheet') &&
              file.name.endsWith('.xml'),
          orElse: () => null,
        );
    if (worksheetFile != null) {
      var worksheetXml = utf8.decode(worksheetFile.content as List<int>);
      worksheetXml = worksheetXml.replaceFirstMapped(
        RegExp(r'<sheetView\b([^>]*)/>'),
        (match) {
          final attributes = (match.group(1) ?? '').trimRight();
          if (attributes.contains('showGridLines=')) {
            return match.group(0)!.replaceFirst(
                  RegExp(r'showGridLines="[^"]*"'),
                  'showGridLines="0"',
                );
          }
          return '<sheetView$attributes showGridLines="0"/>';
        },
      );
      worksheetXml = worksheetXml.replaceFirst(
        RegExp(r'<pageMargins\b[^>]*/>'),
        '<pageMargins left="0.25" right="0.25" top="0.5" bottom="0.5" '
        'header="0.2" footer="0.2"/>'
        '<pageSetup paperSize="9" orientation="landscape" '
        'fitToWidth="1" fitToHeight="0"/>',
      );
      if (!worksheetXml.contains('<printOptions')) {
        worksheetXml = worksheetXml.replaceFirst(
          '<pageMargins',
          '<printOptions horizontalCentered="1" gridLines="0"/>'
              '<pageMargins',
        );
      }
      if (!worksheetXml.contains('<sheetPr')) {
        worksheetXml = worksheetXml.replaceFirstMapped(
          RegExp(r'<worksheet\b[^>]*>'),
          (match) => '${match.group(0)}<sheetPr><pageSetUpPr fitToPage="1"/>'
              '</sheetPr>',
        );
      }
      final worksheetBytes = utf8.encode(worksheetXml);
      archive.addFile(
        ArchiveFile(
          worksheetFile.name,
          worksheetBytes.length,
          worksheetBytes,
        ),
      );
    }
    return ZipEncoder().encode(archive) ?? bytes;
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
    final tableBorder = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#000000'),
    );

    final titleStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 14,
      fontColorHex: ExcelColor.fromHexString('#1B365D'),
      backgroundColorHex: ExcelColor.fromHexString('#E8EEF5'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
    );

    final sectionHeaderStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString('#2D5A27'),
      backgroundColorHex: ExcelColor.fromHexString('#E2EFCB'),
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final cellCenterStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final cellCenterBoldStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final cellLeftStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    final summaryHeaderStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 11,
      backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: tableBorder,
      rightBorder: tableBorder,
      topBorder: tableBorder,
      bottomBorder: tableBorder,
    );

    // Row 0: Main Title
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      .value = TextCellValue(title);
    _mergeAndSetOuterBorders(
      sheet,
      startCol: 0,
      startRow: 0,
      endCol: 4,
      endRow: 0,
      baseStyle: titleStyle,
      outerBorder: _noneBorder,
    );
    sheet.setRowHeight(0, 30);

    // Row 1: Common Column Headers
    final headers = ['S. NU', 'BİRLİĞİ', 'RÜTBE', 'ADI SOYADI', 'DİĞER'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
        ..value = TextCellValue(headers[c])
        ..cellStyle = headerStyle;
    }
    sheet.setRowHeight(1, 24);

    var currentRow = 2;

    for (final act in activities) {
      // Activity Section Header
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      ).value = TextCellValue(act.sectionHeader);

      _mergeAndSetOuterBorders(
        sheet,
        startCol: 0,
        startRow: currentRow,
        endCol: 4,
        endRow: currentRow,
        baseStyle: sectionHeaderStyle,
      );
      sheet.setRowHeight(currentRow, 28);
      currentRow++;

      var rowIndex = 0;
      while (rowIndex < act.rows.length) {
        final startRowIndex = currentRow;
        final currentBirlik = act.rows[rowIndex].birligi;
        final currentGroup = act.rows[rowIndex].groupCode;
        var groupLength = 1;
        while (rowIndex + groupLength < act.rows.length &&
            _sameBirlik(
              act.rows[rowIndex + groupLength].birligi,
              currentBirlik,
            ) &&
            act.rows[rowIndex + groupLength].groupCode == currentGroup) {
          groupLength++;
        }
        final isSpecialGroup =
            (currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR') &&
                List.generate(
                  groupLength,
                  (offset) => act.rows[rowIndex + offset].groupCode,
                ).every((groupCode) => groupCode == currentGroup);

        for (var offset = 0; offset < groupLength; offset++) {
          final r = act.rows[rowIndex + offset];
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
          )
            ..value = IntCellValue(r.sNu)
            ..cellStyle = cellCenterStyle;
          sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
          )
            ..value = offset == 0 ? TextCellValue(r.birligi) : null
            ..cellStyle = cellCenterBoldStyle;
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
            ..value =
                !isSpecialGroup || offset == 0 ? TextCellValue(r.diger) : null
            ..cellStyle = isSpecialGroup ? cellCenterBoldStyle : cellLeftStyle;
          sheet.setRowHeight(
            currentRow,
            _excelRowHeightFor(r.adSoyad, r.diger, r.rutbe),
          );
          currentRow++;
        }

        if (groupLength > 1) {
          _mergeAndSetOuterBorders(
            sheet,
            startCol: 1,
            startRow: startRowIndex,
            endCol: 1,
            endRow: startRowIndex + groupLength - 1,
            baseStyle: cellCenterBoldStyle,
          );
          if (isSpecialGroup) {
            _mergeAndSetOuterBorders(
              sheet,
              startCol: 4,
              startRow: startRowIndex,
              endCol: 4,
              endRow: startRowIndex + groupLength - 1,
              baseStyle: cellCenterBoldStyle,
            );
          }
        }
        rowIndex += groupLength;
      }
    }

    final lastDataRowNumber = currentRow;

    currentRow++;
    final allRows = activities.expand((activity) => activity.rows).toList();
    _writeThreeBoxSummary(
      sheet: sheet,
      startRow: currentRow,
      rows: allRows,
      headerStyle: summaryHeaderStyle,
      contentStyle: cellLeftStyle,
    );

    sheet
      ..setColumnWidth(0, 10)
      ..setColumnWidth(1, 22)
      ..setColumnWidth(2, 18)
      ..setColumnWidth(3, 30)
      ..setColumnWidth(4, 25)
      ..setColumnWidth(5, 7);

    final encoded = excel.encode();
    if (encoded == null) return <int>[];
    return _applyPrintSettings(
      encoded,
      sheetName: sheetName,
      endRow: lastDataRowNumber,
      endColumn: 'E',
      repeatHeaderRange: r'$1:$2',
    );
  }

  static bool _sameBirlik(String first, String second) {
    String normalize(String value) => value
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalize(first) == normalize(second);
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
          '    <Cell ss:MergeAcross="4" ss:StyleID="SectionHeader"><Data ss:Type="String">${escapeXml(act.sectionHeader)}</Data></Cell>',
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

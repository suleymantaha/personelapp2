import 'package:personelapp2/core/utils/official_roster_title.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

/// Helper module for generating SpreadsheetML XML (.xml/.xls) documents
class ExcelXmlGenerator {
  static String generate({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    final titleHeader =
        MilitaryRosterExporter.escapeXml(OfficialRosterTitle.format(faaliyetAdi, tarih));

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
            '    <Cell$mergeAttr ss:StyleID="DataCellCenterBold"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.birligi)}</Data></Cell>',
          );
        }

        buffer
          ..writeln(
            '    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.rutbe)}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.adSoyad)}</Data></Cell>',
          );

        if (isSpecialGroup) {
          if (j == 0) {
            final mergeAttr =
                mergeCount > 0 ? ' ss:MergeDown="$mergeCount"' : '';
            buffer.writeln(
              '    <Cell$mergeAttr ss:StyleID="DataCellCenterBold"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.diger)}</Data></Cell>',
            );
          }
        } else {
          buffer.writeln(
            '    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.diger)}</Data></Cell>',
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
      MilitaryRosterExporter.specialDutyRankSummary('Hazır Kıta', 'HAZIR_KITA', rows),
      MilitaryRosterExporter.specialDutyRankSummary('Gülüşkür', 'GULUSKUR', rows),
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
          '    <Cell ss:MergeAcross="4" ss:StyleID="DataCellLeft"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(item)}</Data></Cell>',
        )
        ..writeln('   </Row>');
    }

    buffer
      ..writeln('  </Table>')
      ..writeln(' </Worksheet>')
      ..writeln('</Workbook>');

    return buffer.toString();
  }

  static bool _sameBirlik(String first, String second) {
    String normalize(String v) => v
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalize(first) == normalize(second);
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
        '    <Cell ss:MergeAcross="4" ss:StyleID="MainTitle"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(title)}</Data></Cell>',
      )
      ..writeln('   </Row>');

    for (final act in activities) {
      buffer
        ..writeln('   <Row ss:Height="12"/>')
        ..writeln('   <Row ss:Height="22">')
        ..writeln(
          '    <Cell ss:MergeAcross="4" ss:StyleID="SectionHeader"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(act.sectionHeader)}</Data></Cell>',
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
            '    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.birligi)}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellCenter"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.rutbe)}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.adSoyad)}</Data></Cell>',
          )
          ..writeln(
            '    <Cell ss:StyleID="DataCellLeft"><Data ss:Type="String">${MilitaryRosterExporter.escapeXml(r.diger)}</Data></Cell>',
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
}

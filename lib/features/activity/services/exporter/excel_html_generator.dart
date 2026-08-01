import 'package:personelapp2/core/utils/official_roster_title.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

/// Helper module for generating HTML-based Excel (.xls) documents
class ExcelHtmlGenerator {
  static String generate({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    final titleHeader =
        MilitaryRosterExporter.escapeXml(OfficialRosterTitle.format(faaliyetAdi, tarih));

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
            '    <td$spanAttr class="center bold">${MilitaryRosterExporter.escapeXml(r.birligi)}</td>',
          );
        }

        // Column C: RÜTBE
        // Column D: ADI SOYADI
        sb
          ..writeln('    <td class="center">${MilitaryRosterExporter.escapeXml(r.rutbe)}</td>')
          ..writeln('    <td class="left">${MilitaryRosterExporter.escapeXml(r.adSoyad)}</td>');

        // Column E: DİĞER (Merged vertically for Hazır Kıta & Gülüşkür, normal for others)
        if (isSpecialGroup) {
          if (j == 0) {
            sb.writeln(
              '    <td$spanAttr class="center bold">${MilitaryRosterExporter.escapeXml(r.diger)}</td>',
            );
          }
        } else {
          sb.writeln('    <td class="left">${MilitaryRosterExporter.escapeXml(r.diger)}</td>');
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
      MilitaryRosterExporter.specialDutyRankSummary('Hazır Kıta', 'HAZIR_KITA', rows),
      MilitaryRosterExporter.specialDutyRankSummary('Gülüşkür', 'GULUSKUR', rows),
      'Diğer Görevler: $digerCount Personel',
    ];
    for (final item in dutySummaryItems) {
      sb.writeln(
        '  <tr><td colspan="5" class="left bold">${MilitaryRosterExporter.escapeXml(item)}</td></tr>',
      );
    }

    final summaryItems = [
      MilitaryRosterExporter.specialDutyRankSummary('Hazır Kıta', 'HAZIR_KITA', rows),
      MilitaryRosterExporter.specialDutyRankSummary('Gülüşkür', 'GULUSKUR', rows),
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
        '  <tr><td colspan="5" class="left">${MilitaryRosterExporter.escapeXml(item)}</td></tr>',
      );
    }

    sb
      ..writeln('</table>')
      ..writeln('</body>')
      ..writeln('</html>');

    return sb.toString();
  }

  static bool _sameBirlik(String first, String second) {
    String normalize(String v) => v
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalize(first) == normalize(second);
  }
}

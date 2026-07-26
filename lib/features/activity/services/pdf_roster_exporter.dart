import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class PdfRosterExporter {
  /// Formats official title text: e.g. JÖH TB.K.LIĞI HEYBET TEPE PUSU FAALİYETİ İSİM LİSTESİ-24.07.2026
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

    // Default to HEYBET TEPE PUSU FAALİYETİ if starts with GÜNLÜK FAALİYET or empty
    if (nameStr.isEmpty ||
        nameStr.startsWith('GÜNLÜK FAALİYET') ||
        nameStr == 'GÜNLÜK FAALİYET') {
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

  static pw.Widget builderSummaryBox(List<MilitaryRosterRow> rows) {
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

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.8),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GÖREV VE MEVCUT ÖZETİ',
            style: const pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Hazır Kıta: $hazirKitaCount Personel  •  '
            'Gülüşkür: $guluskurCount Personel  •  '
            'Diğer: $digerCount Personel',
            style: const pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Subay: ${counts.subayCount}  •  '
            'Astsubay: ${counts.astsubayCount}  •  '
            'Uzman Jandarma: ${counts.uzmanJandarmaCount}  •  '
            'Uzman Erbaş: ${counts.uzmanErbasCount}  •  '
            'Er/Söz.Er: ${counts.erCount}  •  '
            'TOPLAM MEVCUT: ${counts.totalCount} Personel',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  /// Builds PDF Table matching official military layout with dynamic vertically merged cells for BİRLİĞİ and DİĞER
  static pw.Widget buildPdfTable(List<MilitaryRosterRow> rows) {
    const headerStyle = pw.TextStyle(
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
    );

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            alignment: pw.Alignment.center,
            child: pw.Text('S. NU', style: headerStyle),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            alignment: pw.Alignment.center,
            child: pw.Text('BİRLİĞİ', style: headerStyle),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            alignment: pw.Alignment.center,
            child: pw.Text('RÜTBE', style: headerStyle),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            alignment: pw.Alignment.center,
            child: pw.Text('ADI SOYADI', style: headerStyle),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 2),
            alignment: pw.Alignment.center,
            child: pw.Text('DİĞER', style: headerStyle),
          ),
        ],
      ),
    ];

    final n = rows.length;
    if (n == 0) {
      return pw.Table(children: tableRows);
    }

    final birlikStart = List<int>.filled(n, 0);
    final birlikEnd = List<int>.filled(n, 0);
    final specialStart = List<int>.filled(n, -1);
    final specialEnd = List<int>.filled(n, -1);

    // 1. Calculate dynamic Birlik merged blocks
    var idx = 0;
    while (idx < n) {
      final bName = rows[idx].birligi;
      final gCode = rows[idx].groupCode;
      var endIdx = idx;
      while (endIdx + 1 < n &&
          rows[endIdx + 1].birligi == bName &&
          rows[endIdx + 1].groupCode == gCode) {
        endIdx++;
      }
      for (var k = idx; k <= endIdx; k++) {
        birlikStart[k] = idx;
        birlikEnd[k] = endIdx;
      }
      idx = endIdx + 1;
    }

    // 2. Calculate dynamic Special duty merged blocks (HAZIR KITA & GÜLÜŞKÜR)
    idx = 0;
    while (idx < n) {
      final gCode = rows[idx].groupCode;
      final isSpecial = gCode == 'HAZIR_KITA' || gCode == 'GULUSKUR';
      if (isSpecial) {
        final bName = rows[idx].birligi;
        var endIdx = idx;
        while (endIdx + 1 < n &&
            rows[endIdx + 1].groupCode == gCode &&
            rows[endIdx + 1].birligi == bName) {
          endIdx++;
        }
        for (var k = idx; k <= endIdx; k++) {
          specialStart[k] = idx;
          specialEnd[k] = endIdx;
        }
        idx = endIdx + 1;
      } else {
        idx++;
      }
    }

    const cellBorder = pw.Border(
      bottom: pw.BorderSide(width: 0.6, color: PdfColors.grey800),
    );

    for (var i = 0; i < n; i++) {
      final r = rows[i];
      final isEven = i.isEven;
      final rowBgColor = isEven ? PdfColors.white : PdfColors.grey50;

      // Birlik merge boundaries
      final bSt = birlikStart[i];
      final bEn = birlikEnd[i];
      final isBLast = i == bEn;

      final birlikBorder = isBLast
          ? const pw.Border(
              bottom: pw.BorderSide(width: 0.6, color: PdfColors.grey800),
            )
          : const pw.Border();

      // Determine text placement inside Birlik cell
      var birlikCellText = '';
      final bMid = bSt + (bEn - bSt) ~/ 2;
      if (i == bMid) {
        birlikCellText = r.birligi;
      }
      const birlikAlignment = pw.Alignment.center;

      // Special duty merge boundaries
      final spSt = specialStart[i];
      final spEn = specialEnd[i];
      final isSpecialGroup = spSt != -1;
      final isSpLast = isSpecialGroup && i == spEn;

      final specialBorder = isSpecialGroup
          ? (isSpLast
                ? const pw.Border(
                    bottom: pw.BorderSide(width: 0.6, color: PdfColors.grey800),
                  )
                : const pw.Border())
          : cellBorder;

      var specialCellText = '';
      var specialAlignment = pw.Alignment.center;

      if (isSpecialGroup) {
        final spMid = spSt + (spEn - spSt) ~/ 2;
        if (i == spMid) {
          specialCellText = r.diger;
        }
        specialAlignment = pw.Alignment.center;
      } else {
        specialCellText = r.diger.trim().isEmpty ? '-' : r.diger;
        specialAlignment = r.diger.trim().isEmpty
            ? pw.Alignment.center
            : pw.Alignment.centerLeft;
      }

      tableRows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(color: rowBgColor),
          children: [
            // S. NU
            pw.Container(
              decoration: const pw.BoxDecoration(border: cellBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '${r.sNu > 0 ? r.sNu : i + 1}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            // BİRLİĞİ (Dynamically Merged Cell)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: birlikBorder,
                color: PdfColors.white,
              ),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 3,
              ),
              alignment: birlikAlignment,
              child: pw.Text(
                birlikCellText,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            // RÜTBE
            pw.Container(
              decoration: const pw.BoxDecoration(border: cellBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.rutbe,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            // ADI SOYADI
            pw.Container(
              decoration: const pw.BoxDecoration(border: cellBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 4,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                r.adSoyad,
                style: const pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            // DİĞER (Dynamically Merged Cell for Special Duties)
            pw.Container(
              decoration: pw.BoxDecoration(
                border: specialBorder,
                color: isSpecialGroup ? PdfColors.white : null,
              ),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              alignment: specialAlignment,
              child: pw.Text(
                specialCellText,
                textAlign: (isSpecialGroup || r.diger.trim().isEmpty)
                    ? pw.TextAlign.center
                    : pw.TextAlign.left,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: isSpecialGroup
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: const pw.TableBorder(
        left: pw.BorderSide(width: 0.6, color: PdfColors.grey800),
        right: pw.BorderSide(width: 0.6, color: PdfColors.grey800),
        top: pw.BorderSide(width: 0.6, color: PdfColors.grey800),
        bottom: pw.BorderSide(width: 0.6, color: PdfColors.grey800),
        verticalInside: pw.BorderSide(width: 0.6, color: PdfColors.grey800),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(0.8), // S. NU
        1: pw.FlexColumnWidth(2.5), // BİRLİĞİ
        2: pw.FlexColumnWidth(2.2), // RÜTBE
        3: pw.FlexColumnWidth(4), // ADI SOYADI
        4: pw.FlexColumnWidth(2.5), // DİĞER
      },
      children: tableRows,
    );
  }

  /// Generates a PDF document for official Jandarma daily activity roster
  static Future<pw.Document> generateRosterPdf({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    pw.Font? font;
    pw.Font? boldFont;
    try {
      font = await PdfGoogleFonts.robotoRegular();
      boldFont = await PdfGoogleFonts.robotoBold();
    } on Exception catch (_) {
      // Fallback if offline
    }

    final pdf = pw.Document(
      theme: font != null && boldFont != null
          ? pw.ThemeData.withFont(
              base: font,
              bold: boldFont,
            )
          : null,
    );

    final filteredRows = rows
        .where(
          (r) => DutyOrLeaveType.isOperationalDuty(r.diger) || r.diger.isEmpty,
        )
        .toList();

    final titleText = formatOfficialTitle(faaliyetAdi, tarih);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (context) {
          return pw.Column(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(),
                ),
                child: pw.Center(
                  child: pw.Text(
                    titleText,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
            ],
          );
        },
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Düzenleyen: Jandarma Görev Takip',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Sayfa ${context.pageNumber} / ${context.pagesCount} • Tarih: $tarih',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
        build: (context) {
          return [
            buildPdfTable(filteredRows),
            pw.SizedBox(height: 12),
            builderSummaryBox(filteredRows),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Exports PDF file and triggers OS share dialog
  static Future<void> sharePdfRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) async {
    final pdf = await generateRosterPdf(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
    );

    final dir = await getTemporaryDirectory();
    final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final file = File('${dir.path}/${sanitizedTitle}_Listesi_$tarih.pdf');
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$faaliyetAdi - Resmi İsim Listesi PDF Dökümanı',
      ),
    );
  }
}

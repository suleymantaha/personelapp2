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

  /// Builds PDF Table with merged vertical cells and centered text for BİRLİĞİ and DİĞER (HAZIR KITA & GÜLÜŞKÜR)
  static pw.Widget buildPdfTable(List<MilitaryRosterRow> rows) {
    final tableRows = <pw.TableRow>[];

    // Header Row
    tableRows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'S. NU',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'BİRLİĞİ',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'RÜTBE',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'ADI SOYADI',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            alignment: pw.Alignment.center,
            child: pw.Text(
              'DİĞER',
              style: const pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    final n = rows.length;
    if (n == 0) {
      return pw.Table(children: tableRows);
    }

    final birlikStart = List<int>.filled(n, 0);
    final birlikEnd = List<int>.filled(n, 0);
    final specialStart = List<int>.filled(n, -1);
    final specialEnd = List<int>.filled(n, -1);

    // 1. Calculate Birlik merged blocks
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

    // 2. Calculate Special duty merged blocks (HAZIR KITA & GÜLÜŞKÜR)
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

    for (var i = 0; i < n; i++) {
      final r = rows[i];
      final bSt = birlikStart[i];
      final bEn = birlikEnd[i];
      final isBFirst = i == bSt;
      final isBLast = i == bEn;
      final bMid = bSt + (bEn - bSt) ~/ 2;
      final showBirlikText = i == bMid;

      final spSt = specialStart[i];
      final spEn = specialEnd[i];
      final isSpecial = spSt != -1;
      final isSpFirst = isSpecial && i == spSt;
      final isSpLast = isSpecial && i == spEn;
      final spMid = isSpecial ? spSt + (spEn - spSt) ~/ 2 : -1;
      final showSpecialText = isSpecial && i == spMid;

      final birlikBorder = pw.Border(
        top: isBFirst ? const pw.BorderSide(width: 0.8) : pw.BorderSide.none,
        bottom: isBLast ? const pw.BorderSide(width: 0.8) : pw.BorderSide.none,
        left: const pw.BorderSide(width: 0.8),
        right: const pw.BorderSide(width: 0.8),
      );

      final specialBorder = isSpecial
          ? pw.Border(
              top: isSpFirst
                  ? const pw.BorderSide(width: 0.8)
                  : pw.BorderSide.none,
              bottom: isSpLast
                  ? const pw.BorderSide(width: 0.8)
                  : pw.BorderSide.none,
              left: const pw.BorderSide(width: 0.8),
              right: const pw.BorderSide(width: 0.8),
            )
          : pw.Border.all(width: 0.8);

      final standardBorder = pw.Border.all(width: 0.8);

      tableRows.add(
        pw.TableRow(
          children: [
            // S. NU
            pw.Container(
              decoration: pw.BoxDecoration(border: standardBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '${i + 1}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
            // BİRLİĞİ (Merged Cell Visuals - Vertically Centered Text)
            pw.Container(
              decoration: pw.BoxDecoration(border: birlikBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                showBirlikText ? r.birligi : '',
                style: const pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            // RÜTBE
            pw.Container(
              decoration: pw.BoxDecoration(border: standardBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(r.rutbe, style: const pw.TextStyle(fontSize: 9)),
            ),
            // ADI SOYADI
            pw.Container(
              decoration: pw.BoxDecoration(border: standardBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 4,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(r.adSoyad, style: const pw.TextStyle(fontSize: 9)),
            ),
            // DİĞER (Merged Cell Visuals for HAZIR KITA & GÜLÜŞKÜR - Vertically Centered Text)
            pw.Container(
              decoration: pw.BoxDecoration(border: specialBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 2,
              ),
              alignment: isSpecial
                  ? pw.Alignment.center
                  : pw.Alignment.centerLeft,
              child: pw.Text(
                isSpecial ? (showSpecialText ? r.diger : '') : r.diger,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: isSpecial
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
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2.2),
        3: const pw.FlexColumnWidth(3.8),
        4: const pw.FlexColumnWidth(2.5),
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
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  border: pw.Border.all(),
                ),
                child: pw.Center(
                  child: pw.Text(
                    titleText,
                    style: const pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 12),

              // Custom Roster Table with Merged Cells
              buildPdfTable(filteredRows),
              pw.SizedBox(height: 12),

              // Summary Box (GÖREV VE MEVCUT ÖZETİ)
              builderSummaryBox(filteredRows),
              pw.SizedBox(height: 16),

              // Footer Stamp / Signature Space
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Düzenleyen: Jandarma Görev Takip',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Tarih: $tarih',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          );
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

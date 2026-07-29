import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/core/utils/official_roster_title.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

enum PdfRosterStyle {
  /// Stil 1: Birlik ve özel görev hücrelerini kesintisiz blok olarak gösterir.
  verticalBlock,

  /// Stil 2: Her satırı tam çizgili klasik tablo biçiminde gösterir.
  smartPageChunk,

  /// Stil 3: Her tim/grubun ilk satırını gri bantla vurgular.
  headerBand,
}

class PdfRosterExporter {
  static const _rowsPerPdfTable = 22;

  static String _normalizeGroupLabel(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll('İ', 'I')
      .replaceAll(RegExp(r'\s+'), ' ');

  static bool _sameGroupLabel(String first, String second) =>
      _normalizeGroupLabel(first) == _normalizeGroupLabel(second);

  /// Formats the single official title used by PDF and Excel exports.
  static String formatOfficialTitle(String faaliyetAdi, String rawDate) {
    return OfficialRosterTitle.format(faaliyetAdi, rawDate);
  }

  static pw.Widget builderSummaryBox(List<MilitaryRosterRow> rows) {
    final groups = [
      (
        'Hazır Kıta',
        rows.where((row) => row.groupCode == 'HAZIR_KITA').toList(),
      ),
      (
        'Gülüşkür',
        rows.where((row) => row.groupCode == 'GULUSKUR').toList(),
      ),
      (
        'Diğer Tüm Personel',
        rows
            .where(
              (row) =>
                  row.groupCode != 'HAZIR_KITA' && row.groupCode != 'GULUSKUR',
            )
            .toList(),
      ),
    ];

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          if (index > 0) pw.SizedBox(width: 6),
          pw.Expanded(
            child: _buildSummaryColumn(
              groups[index].$1,
              RankSummaryCounts.calculate(
                groups[index].$2.map((row) => row.rutbe).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildSummaryColumn(
    String title,
    RankSummaryCounts counts,
  ) {
    final lines = [
      if (counts.subayCount > 0) 'SB. ${counts.subayCount}',
      if (counts.astsubayCount > 0) 'ASB. ${counts.astsubayCount}',
      if (counts.uzmanJandarmaCount > 0) 'UZM.J. ${counts.uzmanJandarmaCount}',
      if (counts.uzmanErbasCount > 0) 'J.UZM.ÇVŞ. ${counts.uzmanErbasCount}',
      if (counts.erCount > 0) 'ER/SÖZ.ER ${counts.erCount}',
    ];
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(5),
            color: PdfColors.grey300,
            child: pw.Text(
              title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  pw.Text(line, style: const pw.TextStyle(fontSize: 8.5)),
                if (lines.isEmpty)
                  pw.Text('-', style: const pw.TextStyle(fontSize: 8.5)),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Toplam ${counts.totalCount}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds PDF Table based on selected PdfRosterStyle
  static pw.Widget buildPdfTable(
    List<MilitaryRosterRow> rows, {
    PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  }) {
    final headerStyle = pw.TextStyle(
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
    );

    final tableRows = <pw.TableRow>[
      pw.TableRow(
        repeat: true,
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
          _sameGroupLabel(rows[endIdx + 1].birligi, bName) &&
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
            _sameGroupLabel(rows[endIdx + 1].birligi, bName)) {
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
      final isGroupStart = i == 0 ||
          rows[i - 1].groupCode != r.groupCode ||
          !_sameGroupLabel(rows[i - 1].birligi, r.birligi);
      final rowBgColor = style == PdfRosterStyle.headerBand && isGroupStart
          ? PdfColors.grey200
          : PdfColors.white;

      // Birlik merge boundaries
      final bSt = birlikStart[i];
      final bEn = birlikEnd[i];
      final isBLast = i == bEn;

      final birlikBorder = isBLast ? cellBorder : const pw.Border();

      // Each page is built from a bounded row chunk. Recreate the merged-cell
      // appearance inside that chunk so a group split across pages starts a
      // fresh, correctly labelled merged block on the next page.
      final birlikMiddle = bSt + (bEn - bSt) ~/ 2;
      final birlikCellText = i == birlikMiddle ? r.birligi : '';
      const birlikAlignment = pw.Alignment.center;

      // Special duty merge boundaries
      final spSt = specialStart[i];
      final spEn = specialEnd[i];
      final isSpSpecialGroup = spSt != -1;
      final isSpLast = isSpSpecialGroup && i == spEn;

      final specialBorder =
          isSpSpecialGroup && !isSpLast ? const pw.Border() : cellBorder;

      var specialCellText = r.diger.trim().isEmpty ? '-' : r.diger;
      var specialAlignment = pw.Alignment.center;

      if (isSpSpecialGroup) {
        final specialMiddle = spSt + (spEn - spSt) ~/ 2;
        specialCellText = i == specialMiddle ? r.diger : '';
        specialAlignment = pw.Alignment.center;
      } else {
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
              constraints: const pw.BoxConstraints(minHeight: 18),
              decoration: const pw.BoxDecoration(border: cellBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 2,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                '${r.sNu > 0 ? r.sNu : i + 1}',
                style: const pw.TextStyle(fontSize: 8.5),
              ),
            ),
            // BİRLİĞİ (Dynamically Merged Cell)
            pw.Container(
              constraints: const pw.BoxConstraints(minHeight: 18),
              decoration: pw.BoxDecoration(
                border: birlikBorder,
                color: rowBgColor,
              ),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 3,
              ),
              alignment: birlikAlignment,
              child: pw.Text(
                birlikCellText,
                maxLines: 2,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: style == PdfRosterStyle.smartPageChunk
                      ? pw.FontWeight.normal
                      : pw.FontWeight.bold,
                ),
              ),
            ),
            // RÜTBE
            pw.Container(
              constraints: const pw.BoxConstraints(minHeight: 18),
              decoration: const pw.BoxDecoration(border: cellBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 2,
              ),
              alignment: pw.Alignment.center,
              child: pw.Text(
                r.rutbe,
                maxLines: 2,
                style: const pw.TextStyle(fontSize: 8.5),
              ),
            ),
            // ADI SOYADI
            pw.Container(
              constraints: const pw.BoxConstraints(minHeight: 18),
              decoration: const pw.BoxDecoration(border: cellBorder),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 4,
              ),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                r.adSoyad,
                maxLines: 2,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            // DİĞER (Dynamically Merged Cell for Special Duties)
            pw.Container(
              constraints: const pw.BoxConstraints(minHeight: 18),
              decoration: pw.BoxDecoration(
                border: specialBorder,
                color: rowBgColor,
              ),
              padding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 2,
              ),
              alignment: specialAlignment,
              child: pw.Text(
                specialCellText,
                maxLines: 2,
                textAlign: (isSpSpecialGroup || r.diger.trim().isEmpty)
                    ? pw.TextAlign.center
                    : pw.TextAlign.left,
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: isSpSpecialGroup
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

  static List<pw.Widget> _buildPaginatedTables(
    List<MilitaryRosterRow> rows, {
    required PdfRosterStyle style,
    required String titleText,
  }) {
    if (rows.isEmpty) {
      return [
        _buildPageTitle(titleText),
        pw.SizedBox(height: 10),
        buildPdfTable(rows, style: style),
      ];
    }
    final tables = <pw.Widget>[];
    for (var start = 0; start < rows.length; start += _rowsPerPdfTable) {
      if (tables.isNotEmpty) tables.add(pw.NewPage());
      tables
        ..add(_buildPageTitle(titleText))
        ..add(pw.SizedBox(height: 10));
      tables.add(
        buildPdfTable(
          rows.sublist(
            start,
            start + _rowsPerPdfTable < rows.length
                ? start + _rowsPerPdfTable
                : rows.length,
          ),
          style: style,
        ),
      );
    }
    return tables;
  }

  static pw.Widget _buildPageTitle(String titleText) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(),
      ),
      child: pw.Center(
        child: pw.Text(
          titleText,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Generates a PDF document for official Jandarma daily activity roster
  static Future<pw.Document> generateRosterPdf({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  }) async {
    pw.Font? font;
    pw.Font? boldFont;
    try {
      // Load bundled Roboto TTF — supports Turkish characters offline
      final regularData = await rootBundle.load(
        'assets/fonts/Roboto-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      font = pw.Font.ttf(regularData);
      boldFont = pw.Font.ttf(boldData);
    } on Exception catch (_) {
      // Network fallback
      try {
        font = await PdfGoogleFonts.robotoRegular();
        boldFont = await PdfGoogleFonts.robotoBold();
      } on Exception catch (_) {
        // Use built-in font as last resort
      }
    }

    final pdf = pw.Document(
      theme: font != null && boldFont != null
          ? pw.ThemeData.withFont(
              base: font,
              bold: boldFont,
            )
          : null,
    );

    final titleText = formatOfficialTitle(faaliyetAdi, tarih);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Düzenleyen: Jandarma Görev Takip',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                'Sayfa ${context.pageNumber} / ${context.pagesCount} • Tarih: $tarih',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          );
        },
        build: (context) {
          return [
            ..._buildPaginatedTables(
              rows,
              style: style,
              titleText: titleText,
            ),
            if (rows.length > _rowsPerPdfTable) pw.NewPage(),
            if (rows.length > _rowsPerPdfTable)
              _buildPageTitle('$titleText - GÖREV VE MEVCUT ÖZETİ'),
            pw.SizedBox(height: 12),
            builderSummaryBox(rows),
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
    PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  }) async {
    final pdf = await generateRosterPdf(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
      style: style,
    );

    final dir = await getTemporaryDirectory();
    final sanitizedTitle = faaliyetAdi.replaceAll(RegExp(r'[^\w\.-]'), '_');
    final exportId = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${dir.path}/${sanitizedTitle}_Listesi_${tarih}_$exportId.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: '$faaliyetAdi - Resmi İsim Listesi PDF Dökümanı',
      ),
    );
  }

  static Future<void> printPdfRoster({
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  }) async {
    final pdf = await generateRosterPdf(
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
      style: style,
    );
    final bytes = await pdf.save();
    await Printing.layoutPdf(
      name: '$faaliyetAdi - $tarih',
      onLayout: (_) async => bytes,
    );
  }

  /// Displays a modal bottom sheet to select from 3 PDF styles and exports/shares the PDF
  static Future<void> showStylePickerAndSharePdf(
    BuildContext context, {
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
    bool printDirectly = false,
  }) async {
    final selectedStyle = await showModalBottomSheet<PdfRosterStyle>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'PDF Şablon Görünüm Stili Seçiniz',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Çıktı almak istediğiniz resmi PDF düzenini seçin:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigoAccent,
                    child: Icon(
                      Icons.dashboard_customize,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Stil 1: Dikey Blok Mimarisi (VIP Format)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Birlik ve özel görev alanlarını kesintisiz blok görünümünde gösterir.',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () => Navigator.pop(ctx, PdfRosterStyle.verticalBlock),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(
                      Icons.table_rows,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Stil 2: Akıllı Sayfa Kırılımı Formatı',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Klasik 5 sütunlu tablo. Her satır tam çizgili ve sayfa geçişlerine dayanıklıdır.',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () =>
                      Navigator.pop(ctx, PdfRosterStyle.smartPageChunk),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.view_day, color: Colors.white, size: 20),
                  ),
                  title: const Text(
                    'Stil 3: Askeri Şerit Başlık Formatı',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Her Birlik/Tim grubunun ilk satırını gri bantla vurgular.',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () => Navigator.pop(ctx, PdfRosterStyle.headerBand),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedStyle != null && context.mounted) {
      if (printDirectly) {
        await printPdfRoster(
          faaliyetAdi: faaliyetAdi,
          tarih: tarih,
          rows: rows,
          style: selectedStyle,
        );
      } else {
        await sharePdfRoster(
          faaliyetAdi: faaliyetAdi,
          tarih: tarih,
          rows: rows,
          style: selectedStyle,
        );
      }
    }
  }

  static Future<void> showStylePickerAndPrintPdf(
    BuildContext context, {
    required String faaliyetAdi,
    required String tarih,
    required List<MilitaryRosterRow> rows,
  }) {
    return showStylePickerAndSharePdf(
      context,
      faaliyetAdi: faaliyetAdi,
      tarih: tarih,
      rows: rows,
      printDirectly: true,
    );
  }
}

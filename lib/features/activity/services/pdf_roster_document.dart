part of 'pdf_roster_exporter.dart';

Future<pw.Document> pdfGenerateRoster({
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

  final titleText = pdfFormatOfficialTitle(faaliyetAdi, tarih);

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
          pdfBuilderSummaryBox(rows),
        ];
      },
    ),
  );

  return pdf;
}

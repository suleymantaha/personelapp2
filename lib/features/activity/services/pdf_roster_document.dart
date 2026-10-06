part of 'pdf_roster_exporter.dart';

Future<pw.Document> pdfGenerateRoster({
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
  PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  bool includeSignatures = false,
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
        ? pw.ThemeData.withFont(base: font, bold: boldFont)
        : null,
  );

  final titleText = pdfFormatOfficialTitle(faaliyetAdi, tarih);

  if (includeSignatures) {
    final tailCount = rows.length < 2 ? rows.length : 2;
    final preceding = rows.sublist(0, rows.length - tailCount);
    final tail = rows.sublist(rows.length - tailCount);
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        header: (_) => pw.Column(
          children: [
            _buildPageTitle(titleText, compact: true),
            pw.SizedBox(height: 4),
            pdfBuildTable(
              const [],
              style: style,
              compact: true,
              mergeCells: false,
            ),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Sayfa ${context.pageNumber} / ${context.pagesCount} • Tarih: $tarih',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
        build: (_) => [
          if (preceding.isNotEmpty)
            pdfBuildTable(
              preceding,
              style: style,
              compact: true,
              mergeCells: false,
              showHeader: false,
            ),
          // A non-spanning container keeps the signatures with the final names.
          pw.Container(
            child: pw.Column(
              children: [
                if (tail.isNotEmpty)
                  pdfBuildTable(
                    tail,
                    style: style,
                    compact: true,
                    mergeCells: false,
                    showHeader: false,
                  ),
                _buildRosterSignatures(),
              ],
            ),
          ),
        ],
      ),
    );
    return pdf;
  }

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
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
            pw.Text(
              'Sayfa ${context.pageNumber} / ${context.pagesCount} • Tarih: $tarih',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            ),
          ],
        );
      },
      build: (context) {
        return [
          ..._buildPaginatedTables(rows, style: style, titleText: titleText),
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

pw.Widget _buildRosterSignatures() => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 10),
  child: pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final signer in heybetRosterSigners)
        pw.SizedBox(
          width: 175,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                signer.title,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 22),
              pw.Text(
                signer.name,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(signer.rank, style: const pw.TextStyle(fontSize: 9)),
              pw.Text(signer.role, style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
    ],
  ),
);

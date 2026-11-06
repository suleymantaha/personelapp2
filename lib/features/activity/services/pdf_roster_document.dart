part of 'pdf_roster_exporter.dart';

Future<pw.Document> pdfGenerateRoster({
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
  PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  bool includeSignatures = false,
  List<RosterSigner> signers = heybetRosterSigners,
  String? timeRange,
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

  final titleText = pdfFormatOfficialTitle(
    faaliyetAdi,
    tarih,
    timeRange: timeRange,
  );

  _addRosterPages(
    pdf,
    rows,
    style: style,
    title: titleText,
    date: tarih,
    signers: includeSignatures ? signers : null,
  );
  return pdf;
}

pw.Widget pdfBuilderSummaryBox(List<MilitaryRosterRow> rows) {
  final groups = [
    ('Hazır Kıta', rows.where((row) => row.groupCode == 'HAZIR_KITA').toList()),
    ('Gülüşkür', rows.where((row) => row.groupCode == 'GULUSKUR').toList()),
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

pw.Widget _buildSummaryColumn(String title, RankSummaryCounts counts) {
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
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
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

pw.Widget _buildRosterSignatures(List<RosterSigner> signers) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final signer in signers)
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

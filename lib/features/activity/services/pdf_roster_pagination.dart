part of 'pdf_roster_exporter.dart';

const _rosterPageMargin = pw.EdgeInsets.symmetric(horizontal: 21, vertical: 24);
const _rosterMinimumTailRows = 5;

void _addRosterPages(
  pw.Document pdf,
  List<MilitaryRosterRow> rows, {
  required PdfRosterStyle style,
  required String title,
  required String date,
  required List<RosterSigner>? signers,
}) {
  const format = PdfPageFormat.a4;
  final pageWidth = format.width - _rosterPageMargin.horizontal;
  final measureContext = pw.Context(document: pdf.document)
      .inheritFrom(pdf.theme ?? pw.ThemeData.base());
  final measureConstraints = pw.BoxConstraints.tightFor(width: pageWidth);
  double heightOf(pw.Widget widget) {
    widget.layout(measureContext, measureConstraints);
    return widget.box!.height;
  }

  pw.Widget heading() => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: _buildPageTitle(title),
      );
  pw.Widget footer(int number, int total) => _buildRosterFooter(
        'Sayfa $number / $total • Tarih: $date',
        signed: signers != null,
      );
  pw.Widget closing() => signers == null
      ? _buildRosterSummary(rows)
      : _buildRosterSignatures(signers);
  pw.Table table(int start, int end) => pdfBuildTable(
        rows.sublist(start, end),
        style: style,
        compact: true,
        mergeCells: signers == null,
        rowOffset: start,
      );

  final heightBudget = format.height -
      _rosterPageMargin.vertical -
      heightOf(heading()) -
      heightOf(footer(rows.length + 1, rows.length + 1)) -
      0.01;
  final closingHeight = heightOf(closing());

  void addPage(pw.Table? pageTable, {required bool last}) {
    pdf.addPage(pw.Page(
      pageFormat: format,
      margin: _rosterPageMargin,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              heading(),
              if (pageTable != null) pageTable,
              if (last) closing(),
            ],
          ),
          footer(context.pageNumber, context.pagesCount),
        ],
      ),
    ));
  }

  if (rows.isEmpty) {
    addPage(table(0, 0), last: true);
    return;
  }

  // Prefer to keep signatures with two personnel entries, or the summary
  // with at least the final entry. Exceptionally tall entries can reduce that
  // count when they cannot physically share an A4 page with the closing block.
  var closingRows = signers == null || rows.length == 1 ? 1 : 2;
  while (closingRows > 0 &&
      heightOf(table(rows.length - closingRows, rows.length)) + closingHeight >
          heightBudget) {
    closingRows--;
  }

  final maxRows = (heightBudget / _compactRosterRowHeight).floor();
  for (var start = 0; start < rows.length;) {
    final remaining = rows.length - start;
    if (remaining <= maxRows) {
      final finalTable = table(start, rows.length);
      if (heightOf(finalTable) + closingHeight <= heightBudget) {
        addPage(finalTable, last: true);
        return;
      }
    }

    final stop = rows.length - closingRows;
    final limit = start + maxRows < stop ? start + maxRows : stop;
    var end = start;
    pw.Table? pageTable;
    // Adding a row can move a centered group label to a taller row and make
    // the table shorter. Try the largest possible chunks first.
    for (var candidateEnd = limit; candidateEnd > start; candidateEnd--) {
      final candidate = table(start, candidateEnd);
      if (heightOf(candidate) <= heightBudget) {
        end = candidateEnd;
        pageTable = candidate;
        break;
      }
    }
    if (pageTable == null) {
      throw StateError('Kadro tablosundaki bir satır A4 sayfasına sığmıyor.');
    }

    // Avoid a nearly empty final page when the table and closing block need
    // one more page. Only rebalance when both resulting pages actually fit.
    if (closingRows > 0 && rows.length - end < _rosterMinimumTailRows) {
      for (var split = start + remaining ~/ 2; split < end; split++) {
        final balancedTail = table(split, rows.length);
        if (heightOf(balancedTail) + closingHeight > heightBudget) continue;
        final balancedPage = table(start, split);
        if (heightOf(balancedPage) <= heightBudget) {
          addPage(balancedPage, last: false);
          addPage(balancedTail, last: true);
          return;
        }
      }
    }
    addPage(pageTable, last: false);
    start = end;
  }
  addPage(null, last: true);
}

pw.Widget _buildPageTitle(String title) => pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(width: 0.6),
      ),
      child: pw.Text(
        title,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );

pw.Widget _buildRosterFooter(String pageLabel, {required bool signed}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            signed ? '' : 'Düzenleyen: Jandarma Görev Takip',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
          pw.Text(
            pageLabel,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );

pw.Widget _buildRosterSummary(List<MilitaryRosterRow> rows) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'GÖREV VE MEVCUT ÖZETİ',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pdfBuilderSummaryBox(rows),
        ],
      ),
    );

part of 'pdf_roster_exporter.dart';

const _compactRosterRowHeight = 13.0;
const _rosterGridLine = pw.BorderSide(width: 0.45, color: PdfColors.grey800);

String _normalizeGroupLabel(String value) => value
    .trim()
    .toUpperCase()
    .replaceAll('İ', 'I')
    .replaceAll(RegExp(r'\s+'), ' ');

bool _sameRosterUnit(MilitaryRosterRow first, MilitaryRosterRow second) =>
    first.groupCode == second.groupCode &&
    _normalizeGroupLabel(first.birligi) == _normalizeGroupLabel(second.birligi);

String pdfFormatOfficialTitle(
  String faaliyetAdi,
  String rawDate, {
  String? timeRange,
}) =>
    OfficialRosterTitle.format(faaliyetAdi, rawDate, timeRange: timeRange);

pw.Table pdfBuildTable(
  List<MilitaryRosterRow> rows, {
  PdfRosterStyle style = PdfRosterStyle.verticalBlock,
  bool compact = false,
  bool mergeCells = true,
  int rowOffset = 0,
}) {
  final mergeGroups = mergeCells && style == PdfRosterStyle.verticalBlock;
  final unitBlocks = _rosterBlocks(rows, _sameRosterUnit);
  final dutyBlocks = _rosterBlocks(
    rows,
    (first, second) =>
        first.groupCode == second.groupCode && first.diger == second.diger,
  );
  return pw.Table(
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.full,
    border: const pw.TableBorder(
      left: _rosterGridLine,
      right: _rosterGridLine,
      top: _rosterGridLine,
      bottom: _rosterGridLine,
      verticalInside: _rosterGridLine,
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(7),
      1: pw.FlexColumnWidth(20),
      2: pw.FlexColumnWidth(15),
      3: pw.FlexColumnWidth(37),
      4: pw.FlexColumnWidth(21),
    },
    children: [
      pw.TableRow(
        repeat: true,
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          for (final label in [
            'S. NU',
            'BİRLİĞİ',
            'RÜTBE',
            'ADI SOYADI',
            'DİĞER'
          ])
            _rosterCell(label, compact: compact, header: true, bold: true),
        ],
      ),
      for (var i = 0; i < rows.length; i++)
        _buildRosterRow(
          rows[i],
          index: i,
          rowOffset: rowOffset,
          style: style,
          compact: compact,
          unitBlock: unitBlocks[i],
          mergedUnit: mergeGroups ? unitBlocks[i] : null,
          mergedDuty:
              mergeGroups && _isSpecialDuty(rows[i]) ? dutyBlocks[i] : null,
        ),
    ],
  );
}

bool _isSpecialDuty(MilitaryRosterRow row) =>
    row.groupCode == 'HAZIR_KITA' || row.groupCode == 'GULUSKUR';

typedef _RosterBlock = ({int first, int last});

List<_RosterBlock> _rosterBlocks(
  List<MilitaryRosterRow> rows,
  bool Function(MilitaryRosterRow, MilitaryRosterRow) sameGroup,
) {
  final blocks = <_RosterBlock>[];
  for (var first = 0; first < rows.length;) {
    var last = first;
    while (last + 1 < rows.length && sameGroup(rows[first], rows[last + 1])) {
      last++;
    }
    final block = (first: first, last: last);
    for (var index = first; index <= last; index++) {
      blocks.add(block);
    }
    first = last + 1;
  }
  return blocks;
}

pw.TableRow _buildRosterRow(
  MilitaryRosterRow row, {
  required int index,
  required int rowOffset,
  required PdfRosterStyle style,
  required bool compact,
  required _RosterBlock unitBlock,
  required _RosterBlock? mergedUnit,
  required _RosterBlock? mergedDuty,
}) {
  final band = style == PdfRosterStyle.headerBand && index == unitBlock.first;
  final detail = row.diger.trim().isEmpty && !compact ? '-' : row.diger;
  return pw.TableRow(
    decoration:
        pw.BoxDecoration(color: band ? PdfColors.grey200 : PdfColors.white),
    children: [
      _rosterCell(
        '${row.sNu > 0 ? row.sNu : rowOffset + index + 1}',
        compact: compact,
      ),
      _rosterCell(
        _blockLabel(row.birligi, index, mergedUnit),
        compact: compact,
        bold: style != PdfRosterStyle.smartPageChunk,
        border: _blockBorder(index, mergedUnit),
      ),
      _rosterCell(row.rutbe, compact: compact),
      _rosterCell(row.adSoyad, compact: compact, bold: true, left: true),
      _rosterCell(
        _blockLabel(detail, index, mergedDuty),
        compact: compact,
        left: !_isSpecialDuty(row) && row.diger.trim().isNotEmpty,
        bold: _isSpecialDuty(row),
        border: _blockBorder(index, mergedDuty),
      ),
    ],
  );
}

String _blockLabel(String text, int index, _RosterBlock? block) =>
    block == null || index == (block.first + block.last) ~/ 2 ? text : '';

pw.Border _blockBorder(int index, _RosterBlock? block) => pw.Border(
      bottom: block == null || index == block.last
          ? _rosterGridLine
          : pw.BorderSide.none,
    );

pw.Container _rosterCell(
  String text, {
  required bool compact,
  bool header = false,
  bool bold = false,
  bool left = false,
  pw.Border border = const pw.Border(bottom: _rosterGridLine),
}) =>
    pw.Container(
      constraints: pw.BoxConstraints(
        minHeight: header ? 16 : (compact ? _compactRosterRowHeight : 18),
      ),
      decoration: pw.BoxDecoration(border: border),
      padding: pw.EdgeInsets.symmetric(
        vertical: header ? 3 : (compact ? 0.5 : 2),
        horizontal: 3,
      ),
      alignment: left ? pw.Alignment.centerLeft : pw.Alignment.center,
      child: pw.Text(
        text,
        maxLines: compact ? null : 2,
        textAlign: left ? pw.TextAlign.left : pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: header ? 9.5 : (compact ? 9 : 8.5),
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );

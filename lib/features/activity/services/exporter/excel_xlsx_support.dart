part of 'excel_xlsx_generator.dart';

const _summaryGroups = [
  ('Hazır Kıta', 'HAZIR_KITA'),
  ('Gülüşkür', 'GULUSKUR'),
  ('Diğer Tüm Personel', 'DIGER_TUM_PERSONEL'),
];

final _tableBorder = Border(
  borderStyle: BorderStyle.Thin,
  borderColorHex: ExcelColor.fromHexString('#000000'),
);

final _noneBorder = Border(
  borderStyle: BorderStyle.None,
);

double _excelRowHeightFor(String name, String detail, String rank) {
  final longest = [name.length, detail.length, rank.length]
      .fold<int>(0, (max, length) => length > max ? length : max);
  return longest > 32 ? 32 : 20;
}

void _mergeAndSetOuterBorders(
  Sheet sheet, {
  required int startCol,
  required int startRow,
  required int endCol,
  required int endRow,
  required CellStyle baseStyle,
  Border? outerBorder,
}) {
  final border = outerBorder ?? _tableBorder;
  final isNone = outerBorder == _noneBorder;

  if (startCol != endCol || startRow != endRow) {
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: startRow),
      CellIndex.indexByColumnRow(columnIndex: endCol, rowIndex: endRow),
    );
  }

  final cellBorder = isNone ? _noneBorder : border;

  for (var r = startRow; r <= endRow; r++) {
    for (var c = startCol; c <= endCol; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
      );

      cell.cellStyle = CellStyle(
        bold: baseStyle.isBold,
        italic: baseStyle.isItalic,
        underline: baseStyle.underline,
        fontSize: baseStyle.fontSize,
        fontFamily: baseStyle.fontFamily,
        fontColorHex: baseStyle.fontColor,
        backgroundColorHex: baseStyle.backgroundColor,
        horizontalAlign: baseStyle.horizontalAlignment,
        verticalAlign: baseStyle.verticalAlignment,
        textWrapping: baseStyle.wrap,
        leftBorder: cellBorder,
        rightBorder: cellBorder,
        topBorder: cellBorder,
        bottomBorder: cellBorder,
      );
    }
  }
}

int _writeThreeBoxSummary({
  required Sheet sheet,
  required int startRow,
  required List<MilitaryRosterRow> rows,
  required CellStyle headerStyle,
  required CellStyle contentStyle,
}) {
  final summaries = _summaryGroups.map((group) {
    final groupRows = group.$2 == 'DIGER_TUM_PERSONEL'
        ? rows
            .where(
              (row) =>
                  row.groupCode != 'HAZIR_KITA' && row.groupCode != 'GULUSKUR',
            )
            .toList()
        : rows.where((row) => row.groupCode == group.$2).toList();
    return (
      group.$1,
      RankSummaryCounts.calculate(
        groupRows.map((row) => row.rutbe).toList(),
      )
    );
  }).toList();

  const columnPairs = [(0, 1), (2, 3), (4, 5)];
  for (var index = 0; index < summaries.length; index++) {
    final pair = columnPairs[index];
    _writeMergedSummaryCell(
      sheet,
      row: startRow,
      startColumn: pair.$1,
      endColumn: pair.$2,
      value: summaries[index].$1,
      style: headerStyle,
    );
  }

  final detailRows =
      summaries.map((summary) => _rankSummaryLines(summary.$2)).toList();
  final maxRankLines = detailRows
      .map((lines) => lines.length)
      .fold<int>(0, (maximum, length) => length > maximum ? length : maximum);

  for (var index = 0; index < summaries.length; index++) {
    final pair = columnPairs[index];
    final lines = detailRows[index];
    for (var offset = 0; offset < maxRankLines; offset++) {
      _writeMergedSummaryCell(
        sheet,
        row: startRow + 1 + offset,
        startColumn: pair.$1,
        endColumn: pair.$2,
        value: offset < lines.length ? lines[offset] : '',
        style: contentStyle,
      );
    }
    _writeMergedSummaryCell(
      sheet,
      row: startRow + maxRankLines + 1,
      startColumn: pair.$1,
      endColumn: pair.$2,
      value: 'Toplam ${summaries[index].$2.totalCount}',
      style: contentStyle,
    );
  }
  return startRow + maxRankLines + 1;
}

List<String> _rankSummaryLines(RankSummaryCounts counts) => [
      if (counts.subayCount > 0) 'SB. ${counts.subayCount}',
      if (counts.astsubayCount > 0) 'ASB. ${counts.astsubayCount}',
      if (counts.uzmanJandarmaCount > 0) 'UZM.J. ${counts.uzmanJandarmaCount}',
      if (counts.uzmanErbasCount > 0) 'J.UZM.ÇVŞ. ${counts.uzmanErbasCount}',
      if (counts.erCount > 0) 'ER/SÖZ.ER ${counts.erCount}',
    ];

void _writeMergedSummaryCell(
  Sheet sheet, {
  required int row,
  required int startColumn,
  required int endColumn,
  required String value,
  required CellStyle style,
}) {
  sheet
      .cell(
        CellIndex.indexByColumnRow(columnIndex: startColumn, rowIndex: row),
      )
      .value = TextCellValue(value);

  _mergeAndSetOuterBorders(
    sheet,
    startCol: startColumn,
    startRow: row,
    endCol: endColumn,
    endRow: row,
    baseStyle: style,
  );
}

List<int> _applyPrintSettings(
  List<int> bytes, {
  required String sheetName,
  required int endRow,
  required String endColumn,
  required String repeatHeaderRange,
}) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final workbookFile = archive.findFile('xl/workbook.xml');
  if (workbookFile == null) return bytes;

  var workbookXml = utf8.decode(workbookFile.content as List<int>);
  workbookXml = workbookXml.replaceAll(
    RegExp(
      r'<definedName\b[^>]*\bname="_xlnm\.Print_Area"[^>]*>.*?</definedName>',
      dotAll: true,
    ),
    '',
  );
  workbookXml = workbookXml.replaceAll(
    RegExp(
      r'<definedName\b[^>]*\bname="_xlnm\.Print_Titles"[^>]*>.*?</definedName>',
      dotAll: true,
    ),
    '',
  );
  final escapedSheetName = sheetName.replaceAll("'", "''");
  final printArea = '<definedName name="_xlnm.Print_Area" localSheetId="0">'
      "'$escapedSheetName'!\$A\$1:\$$endColumn\$$endRow"
      '</definedName>';
  final printTitles = '<definedName name="_xlnm.Print_Titles" localSheetId="0">'
      "'$escapedSheetName'!$repeatHeaderRange"
      '</definedName>';
  if (workbookXml.contains('<definedNames/>')) {
    workbookXml = workbookXml.replaceFirst(
      '<definedNames/>',
      '<definedNames>$printArea$printTitles</definedNames>',
    );
  } else if (workbookXml.contains('</definedNames>')) {
    workbookXml = workbookXml.replaceFirst(
      '</definedNames>',
      '$printArea$printTitles</definedNames>',
    );
  } else {
    final definedNames = '<definedNames>$printArea$printTitles</definedNames>';
    workbookXml = workbookXml.contains('<calcPr')
        ? workbookXml.replaceFirst('<calcPr', '$definedNames<calcPr')
        : workbookXml.replaceFirst(
            '</workbook>',
            '$definedNames</workbook>',
          );
  }

  final workbookBytes = utf8.encode(workbookXml);
  archive.addFile(
    ArchiveFile(
      'xl/workbook.xml',
      workbookBytes.length,
      workbookBytes,
    ),
  );

  final worksheetFile = archive.files.cast<ArchiveFile?>().firstWhere(
        (file) =>
            file != null &&
            file.name.startsWith('xl/worksheets/sheet') &&
            file.name.endsWith('.xml'),
        orElse: () => null,
      );
  if (worksheetFile != null) {
    var worksheetXml = utf8.decode(worksheetFile.content as List<int>);
    worksheetXml = worksheetXml.replaceFirstMapped(
      RegExp(r'<sheetView\b([^>]*)/>'),
      (match) {
        final attributes = (match.group(1) ?? '').trimRight();
        if (attributes.contains('showGridLines=')) {
          return match.group(0)!.replaceFirst(
                RegExp(r'showGridLines="[^"]*"'),
                'showGridLines="0"',
              );
        }
        return '<sheetView$attributes showGridLines="0"/>';
      },
    );
    worksheetXml = worksheetXml.replaceFirst(
      RegExp(r'<pageMargins\b[^>]*/>'),
      '<pageMargins left="0.25" right="0.25" top="0.5" bottom="0.5" '
      'header="0.2" footer="0.2"/>'
      '<pageSetup paperSize="9" orientation="portrait" '
      'fitToWidth="1" fitToHeight="0"/>',
    );
    if (!worksheetXml.contains('<printOptions')) {
      worksheetXml = worksheetXml.replaceFirst(
        '<pageMargins',
        '<printOptions horizontalCentered="1" gridLines="0"/>'
            '<pageMargins',
      );
    }
    if (!worksheetXml.contains('<sheetPr')) {
      worksheetXml = worksheetXml.replaceFirstMapped(
        RegExp(r'<worksheet\b[^>]*>'),
        (match) => '${match.group(0)}<sheetPr><pageSetUpPr fitToPage="1"/>'
            '</sheetPr>',
      );
    }
    final worksheetBytes = utf8.encode(worksheetXml);
    archive.addFile(
      ArchiveFile(
        worksheetFile.name,
        worksheetBytes.length,
        worksheetBytes,
      ),
    );
  }
  return ZipEncoder().encode(archive) ?? bytes;
}

bool _sameBirlik(String first, String second) {
  String normalize(String value) => value
      .trim()
      .toUpperCase()
      .replaceAll('İ', 'I')
      .replaceAll(RegExp(r'\s+'), ' ');
  return normalize(first) == normalize(second);
}

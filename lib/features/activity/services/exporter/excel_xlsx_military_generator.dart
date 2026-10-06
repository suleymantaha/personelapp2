part of 'excel_xlsx_generator.dart';

List<int> _generateMilitaryExcelBytes({
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
  bool mergeCells = true,
  bool includeSignatures = false,
  String? timeRange,
}) {
  final excel = Excel.createExcel();
  const sheetName = 'İsim Listesi';
  final sheet = excel[sheetName];
  excel.setDefaultSheet(sheetName);
  if (excel.tables.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  final titleHeader = OfficialRosterTitle.format(
    faaliyetAdi,
    tarih,
    timeRange: timeRange,
  );

  final titleStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Calibri),
    fontSize: 14,
    fontColorHex: ExcelColor.fromHexString('#1B365D'),
    backgroundColorHex: ExcelColor.fromHexString('#E8EEF5'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
  );

  final headerStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Calibri),
    fontSize: includeSignatures ? 10 : 11,
    backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _tableBorder,
    rightBorder: _tableBorder,
    topBorder: _tableBorder,
    bottomBorder: _tableBorder,
  );

  final cellCenterStyle = CellStyle(
    fontFamily: getFontFamily(FontFamily.Calibri),
    fontSize: includeSignatures ? 10 : 11,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _tableBorder,
    rightBorder: _tableBorder,
    topBorder: _tableBorder,
    bottomBorder: _tableBorder,
  );

  final cellCenterBoldStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Calibri),
    fontSize: includeSignatures ? 10 : 11,
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _tableBorder,
    rightBorder: _tableBorder,
    topBorder: _tableBorder,
    bottomBorder: _tableBorder,
  );

  final cellLeftStyle = CellStyle(
    fontFamily: getFontFamily(FontFamily.Calibri),
    fontSize: includeSignatures ? 10 : 11,
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _tableBorder,
    rightBorder: _tableBorder,
    topBorder: _tableBorder,
    bottomBorder: _tableBorder,
  );

  final summaryHeaderStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Calibri),
    fontSize: includeSignatures ? 10 : 11,
    backgroundColorHex: ExcelColor.fromHexString('#D9D9D9'),
    horizontalAlign: HorizontalAlign.Center,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _tableBorder,
    rightBorder: _tableBorder,
    topBorder: _tableBorder,
    bottomBorder: _tableBorder,
  );

  // Row 0: Title Header
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
      TextCellValue(titleHeader);

  _mergeAndSetOuterBorders(
    sheet,
    startCol: 0,
    startRow: 0,
    endCol: 4,
    endRow: 0,
    baseStyle: titleStyle,
    outerBorder: _noneBorder,
  );
  sheet.setRowHeight(0, 30);

  // Row 1: Table Headers
  final headers = ['S. NU', 'BİRLİĞİ', 'RÜTBE', 'ADI SOYADI', 'DİĞER'];
  for (var c = 0; c < headers.length; c++) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
      ..value = TextCellValue(headers[c])
      ..cellStyle = headerStyle;
  }
  sheet.setRowHeight(1, 24);

  final signedRowHeights = rows.map(_signedRosterRowHeight).toList();
  var currentRow = 2;
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

    final startRowIndex = currentRow;

    for (var j = 0; j <= mergeCount; j++) {
      final r = rows[i + j];
      final rIndex = startRowIndex + j;

      // Col 0: S. NU
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rIndex))
        ..value = IntCellValue(r.sNu)
        ..cellStyle = cellCenterStyle;

      // Col 1: BİRLİĞİ
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rIndex))
        ..value = j == 0 ? TextCellValue(r.birligi) : null
        ..cellStyle = cellCenterBoldStyle;

      // Col 2: RÜTBE
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rIndex))
        ..value = TextCellValue(r.rutbe)
        ..cellStyle = cellCenterStyle;

      // Col 3: ADI SOYADI
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rIndex))
        ..value = TextCellValue(r.adSoyad)
        ..cellStyle = cellLeftStyle;

      // Col 4: DİĞER
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rIndex))
        ..value = !isSpecialGroup || j == 0 ? TextCellValue(r.diger) : null
        ..cellStyle = isSpecialGroup ? cellCenterBoldStyle : cellLeftStyle;
      sheet.setRowHeight(
        rIndex,
        includeSignatures
            ? signedRowHeights[i + j]
            : _excelRowHeightFor(r.adSoyad, r.diger, r.rutbe),
      );
    }

    if (mergeCount > 0) {
      _mergeAndSetOuterBorders(
        sheet,
        startCol: 1,
        startRow: startRowIndex,
        endCol: 1,
        endRow: startRowIndex + mergeCount,
        baseStyle: cellCenterBoldStyle,
      );

      if (isSpecialGroup) {
        _mergeAndSetOuterBorders(
          sheet,
          startCol: 4,
          startRow: startRowIndex,
          endCol: 4,
          endRow: startRowIndex + mergeCount,
          baseStyle: cellCenterBoldStyle,
        );
      }
    }

    currentRow += mergeCount + 1;
    i += mergeCount + 1;
  }

  var lastPrintRowNumber = currentRow;
  int? signatureStartRow;
  if (includeSignatures) {
    sheet.setRowHeight(currentRow, 14);
    currentRow += 1;
    signatureStartRow = currentRow;
    lastPrintRowNumber = _writeRosterSignatures(sheet, currentRow) + 1;
    currentRow = lastPrintRowNumber;
  }

  currentRow += 1;
  _writeThreeBoxSummary(
    sheet: sheet,
    startRow: currentRow,
    rows: rows,
    headerStyle: summaryHeaderStyle,
    contentStyle: cellLeftStyle,
  );

  sheet
    ..setColumnWidth(0, 10)
    ..setColumnWidth(1, 22)
    ..setColumnWidth(2, 18)
    ..setColumnWidth(3, 30)
    ..setColumnWidth(4, 25)
    ..setColumnWidth(5, 7);

  if (!mergeCells) {
    // Keep the title merged; all personnel and summary cells remain independent.
    // Restore values and full borders after removing the data merged ranges.
    for (final range in sheet.spannedItems.toList()) {
      final startRow = int.parse(RegExp(r'\d+').firstMatch(range)!.group(0)!);
      final isSignature =
          signatureStartRow != null &&
          startRow >= signatureStartRow + 1 &&
          startRow <= signatureStartRow + 5;
      if (range != 'A1:E1' && !isSignature) {
        sheet.unMerge(range);
      }
    }
    for (var index = 0; index < rows.length; index++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: index + 2))
          .value = TextCellValue(
        rows[index].birligi,
      );
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: index + 2))
          .value = TextCellValue(
        rows[index].diger,
      );
      final styles = [
        cellCenterStyle,
        cellCenterBoldStyle,
        cellCenterStyle,
        cellLeftStyle,
        cellLeftStyle,
      ];
      for (var column = 0; column < styles.length; column++) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: index + 2,
                  ),
                )
                .cellStyle =
            styles[column];
      }
    }
  }

  final encoded = excel.encode();
  if (encoded == null) return <int>[];
  return _applyPrintSettings(
    encoded,
    sheetName: sheetName,
    endRow: lastPrintRowNumber,
    endColumn: 'E',
    repeatHeaderRange: r'$1:$2',
    printScale: includeSignatures ? 90 : null,
    pageBreakRows: includeSignatures
        ? _signedRosterPageBreaks(signedRowHeights)
        : const [],
  );
}

// Reserve printable A4 height at 90% scale, after repeated title/header rows.
// The final two personnel rows, gap and all five signature rows form one block.
List<int> _signedRosterPageBreaks(List<double> heights) {
  const pageBodyHeight = 780.0;
  final breaks = <int>[];
  var used = 0.0;
  final tailStart = heights.length > 2 ? heights.length - 2 : 0;
  for (var i = 0; i < tailStart; i++) {
    if (used > 0 && used + heights[i] > pageBodyHeight) {
      breaks.add(i + 2);
      used = 0;
    }
    used += heights[i];
  }
  final tailHeight = heights.skip(tailStart).fold(114.0, (a, b) => a + b);
  if (used > 0 && used + tailHeight > pageBodyHeight) {
    breaks.add(tailStart + 2);
  }
  return breaks;
}

double _signedRosterRowHeight(MilitaryRosterRow row) {
  // Calibri 10pt estimates include word wrapping, explicit newlines and wide
  // glyphs. Grow rows without a line cap rather than shrinking the type.
  double glyphWidth(String c) {
    if ('ilI.,:;!| '.contains(c)) return 2.6;
    if ('MW@%ĞÖÜ'.contains(c)) return 9;
    if (c.toUpperCase() == c && c.toLowerCase() != c) return 6.8;
    return 5.2;
  }

  int lines(String text, double width) {
    var count = 0;
    for (final paragraph in text.split('\n')) {
      var used = 0.0;
      count++;
      for (final word in paragraph.split(' ')) {
        final wordWidth = word.split('').fold(0.0, (a, c) => a + glyphWidth(c));
        if (used > 0 && used + 2.6 + wordWidth > width) {
          count++;
          used = 0;
        }
        if (wordWidth > width) {
          count += (wordWidth / width).ceil() - 1;
          used = wordWidth % width;
        } else {
          used += (used == 0 ? 0 : 2.6) + wordWidth;
        }
      }
    }
    return count;
  }

  final counts = [
    lines(row.birligi, 114),
    lines(row.rutbe, 90),
    lines(row.adSoyad, 153),
    lines(row.diger, 126),
  ];
  final maxLines = counts.reduce((a, b) => a > b ? a : b);
  return maxLines * 12.0 + 2;
}

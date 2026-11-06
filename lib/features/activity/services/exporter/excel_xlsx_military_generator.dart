part of 'excel_xlsx_generator.dart';

List<int> _generateMilitaryExcelBytes({
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
  bool mergeCells = true,
  bool includeSignatures = false,
  List<RosterSigner> signers = heybetRosterSigners,
  String? timeRange,
  required bool paginateForPrint,
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
  final titleHeight = _rosterTitleRowHeight(titleHeader);
  sheet.setRowHeight(0, titleHeight);

  // Row 1: Table Headers
  final headers = ['S. NU', 'BİRLİĞİ', 'RÜTBE', 'ADI SOYADI', 'DİĞER'];
  for (var c = 0; c < headers.length; c++) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
      ..value = TextCellValue(headers[c])
      ..cellStyle = headerStyle;
  }
  sheet.setRowHeight(1, _rosterHeaderHeight);

  final compactRows = includeSignatures ||
      (paginateForPrint && _needsCompactRosterRows(rows, titleHeight));
  var currentRow = 2;
  final dataStartRow = currentRow;
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
        currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR';
    final isSpecialStart =
        isSpecialGroup && (i == 0 || rows[i - 1].groupCode != currentGroup);

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
        ..value = !isSpecialGroup || (isSpecialStart && j == 0)
            ? TextCellValue(r.diger)
            : null
        ..cellStyle = isSpecialGroup ? cellCenterBoldStyle : cellLeftStyle;
      sheet.setRowHeight(
        rIndex,
        !paginateForPrint && !includeSignatures
            ? _excelRowHeightFor(r)
            : _rosterRowHeight(
                r,
                compact: compactRows,
                signed: includeSignatures,
                legacy: !paginateForPrint,
              ),
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
    }

    currentRow += mergeCount + 1;
    i += mergeCount + 1;
  }

  var spIdx = 0;
  while (spIdx < n) {
    final gCode = rows[spIdx].groupCode;
    if (gCode == 'HAZIR_KITA' || gCode == 'GULUSKUR') {
      var spEnd = spIdx;
      while (spEnd + 1 < n && rows[spEnd + 1].groupCode == gCode) {
        spEnd++;
      }
      if (spEnd > spIdx) {
        _mergeAndSetOuterBorders(
          sheet,
          startCol: 4,
          startRow: dataStartRow + spIdx,
          endCol: 4,
          endRow: dataStartRow + spEnd,
          baseStyle: cellCenterBoldStyle,
        );
      }
      spIdx = spEnd + 1;
    } else {
      spIdx++;
    }
  }

  var lastPrintRowNumber = currentRow;
  int? signatureStartRow;
  if (includeSignatures) {
    sheet.setRowHeight(currentRow, 14);
    currentRow += 1;
    signatureStartRow = currentRow;
    lastPrintRowNumber = _writeRosterSignatures(
          sheet,
          currentRow,
          signers,
          growRows: paginateForPrint,
        ) +
        1;
    currentRow = lastPrintRowNumber;
  }
  final print = _planRosterPrint(
    sheet,
    endRow: lastPrintRowNumber,
    fixedScale: paginateForPrint && compactRows,
    // Keep the last two personnel rows with the signature block.
    lastBreakRow:
        includeSignatures ? dataStartRow + math.max(0, rows.length - 2) : null,
  );

  currentRow += 1;
  final summaryStartRow = currentRow;
  _writeThreeBoxSummary(
    sheet: sheet,
    startRow: currentRow,
    rows: rows,
    headerStyle: summaryHeaderStyle,
    contentStyle: cellLeftStyle,
  );

  if (!mergeCells) {
    // Disable vertical personnel grouping and restore each row's values/borders.
    // The final layout restores structural horizontal field/summary spans.
    for (final range in sheet.spannedItems.toList()) {
      final startRow = int.parse(RegExp(r'\d+').firstMatch(range)!.group(0)!);
      final isSignature = signatureStartRow != null &&
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
            .cellStyle = styles[column];
      }
    }
  }

  final encoded = _encodeRosterLayout(sheet, summaryStartRow, print.breaks);
  if (encoded == null) return <int>[];
  return _applyPrintSettings(
    encoded,
    sheetName: sheetName,
    endRow: lastPrintRowNumber,
    endColumn: 'G',
    repeatHeaderRange: r'$1:$2',
    printScale: print.scale,
    pageBreakRows: print.breaks,
  );
}

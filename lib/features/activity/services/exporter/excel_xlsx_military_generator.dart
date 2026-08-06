part of 'excel_xlsx_generator.dart';

List<int> _generateMilitaryExcelBytes({
  required String faaliyetAdi,
  required String tarih,
  required List<MilitaryRosterRow> rows,
}) {
  final excel = Excel.createExcel();
  const sheetName = 'İsim Listesi';
  final sheet = excel[sheetName];
  excel.setDefaultSheet(sheetName);
  if (excel.tables.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

  final titleHeader = OfficialRosterTitle.format(faaliyetAdi, tarih);

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
    fontSize: 11,
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
    fontSize: 11,
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
    fontSize: 11,
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
    fontSize: 11,
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
    fontSize: 11,
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
        _excelRowHeightFor(r.adSoyad, r.diger, r.rutbe),
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

  final lastPersonnelRowNumber = currentRow;

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

  final encoded = excel.encode();
  if (encoded == null) return <int>[];
  return _applyPrintSettings(
    encoded,
    sheetName: sheetName,
    endRow: lastPersonnelRowNumber,
    endColumn: 'E',
    repeatHeaderRange: r'$1:$2',
  );
}

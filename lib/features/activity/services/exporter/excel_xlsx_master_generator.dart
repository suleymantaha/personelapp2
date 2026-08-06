part of 'excel_xlsx_generator.dart';

List<int> _generateMasterDailyExcelBytes({
  required String title,
  required List<MasterActivityData> activities,
}) {
  final excel = Excel.createExcel();
  const sheetName = 'Tüm Faaliyetler';
  final sheet = excel[sheetName];
  excel.setDefaultSheet(sheetName);
  if (excel.tables.containsKey('Sheet1')) {
    excel.delete('Sheet1');
  }

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

  final sectionHeaderStyle = CellStyle(
    bold: true,
    fontFamily: getFontFamily(FontFamily.Calibri),
    fontSize: 12,
    fontColorHex: ExcelColor.fromHexString('#2D5A27'),
    backgroundColorHex: ExcelColor.fromHexString('#E2EFCB'),
    horizontalAlign: HorizontalAlign.Left,
    verticalAlign: VerticalAlign.Center,
    textWrapping: TextWrapping.WrapText,
    leftBorder: _tableBorder,
    rightBorder: _tableBorder,
    topBorder: _tableBorder,
    bottomBorder: _tableBorder,
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

  // Row 0: Main Title
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
      TextCellValue(title);
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

  // Row 1: Common Column Headers
  final headers = ['S. NU', 'BİRLİĞİ', 'RÜTBE', 'ADI SOYADI', 'DİĞER'];
  for (var c = 0; c < headers.length; c++) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 1))
      ..value = TextCellValue(headers[c])
      ..cellStyle = headerStyle;
  }
  sheet.setRowHeight(1, 24);

  var currentRow = 2;

  for (final act in activities) {
    // Activity Section Header
    sheet
        .cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        )
        .value = TextCellValue(act.sectionHeader);

    _mergeAndSetOuterBorders(
      sheet,
      startCol: 0,
      startRow: currentRow,
      endCol: 4,
      endRow: currentRow,
      baseStyle: sectionHeaderStyle,
    );
    sheet.setRowHeight(currentRow, 28);
    currentRow++;

    var rowIndex = 0;
    while (rowIndex < act.rows.length) {
      final startRowIndex = currentRow;
      final currentBirlik = act.rows[rowIndex].birligi;
      final currentGroup = act.rows[rowIndex].groupCode;
      var groupLength = 1;
      while (rowIndex + groupLength < act.rows.length &&
          _sameBirlik(
            act.rows[rowIndex + groupLength].birligi,
            currentBirlik,
          ) &&
          act.rows[rowIndex + groupLength].groupCode == currentGroup) {
        groupLength++;
      }
      final isSpecialGroup =
          (currentGroup == 'HAZIR_KITA' || currentGroup == 'GULUSKUR') &&
              List.generate(
                groupLength,
                (offset) => act.rows[rowIndex + offset].groupCode,
              ).every((groupCode) => groupCode == currentGroup);

      for (var offset = 0; offset < groupLength; offset++) {
        final r = act.rows[rowIndex + offset];
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        )
          ..value = IntCellValue(r.sNu)
          ..cellStyle = cellCenterStyle;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: currentRow),
        )
          ..value = offset == 0 ? TextCellValue(r.birligi) : null
          ..cellStyle = cellCenterBoldStyle;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow),
        )
          ..value = TextCellValue(r.rutbe)
          ..cellStyle = cellCenterStyle;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
        )
          ..value = TextCellValue(r.adSoyad)
          ..cellStyle = cellLeftStyle;
        sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
        )
          ..value =
              !isSpecialGroup || offset == 0 ? TextCellValue(r.diger) : null
          ..cellStyle = isSpecialGroup ? cellCenterBoldStyle : cellLeftStyle;
        sheet.setRowHeight(
          currentRow,
          _excelRowHeightFor(r.adSoyad, r.diger, r.rutbe),
        );
        currentRow++;
      }

      if (groupLength > 1) {
        _mergeAndSetOuterBorders(
          sheet,
          startCol: 1,
          startRow: startRowIndex,
          endCol: 1,
          endRow: startRowIndex + groupLength - 1,
          baseStyle: cellCenterBoldStyle,
        );
        if (isSpecialGroup) {
          _mergeAndSetOuterBorders(
            sheet,
            startCol: 4,
            startRow: startRowIndex,
            endCol: 4,
            endRow: startRowIndex + groupLength - 1,
            baseStyle: cellCenterBoldStyle,
          );
        }
      }
      rowIndex += groupLength;
    }
  }

  final lastDataRowNumber = currentRow;

  currentRow++;
  final allRows = activities.expand((activity) => activity.rows).toList();
  _writeThreeBoxSummary(
    sheet: sheet,
    startRow: currentRow,
    rows: allRows,
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
    endRow: lastDataRowNumber,
    endColumn: 'E',
    repeatHeaderRange: r'$1:$2',
  );
}

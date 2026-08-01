import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:personelapp2/core/utils/official_roster_title.dart';
import 'package:personelapp2/core/utils/rank_helper.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

/// Helper module for generating native binary .xlsx spreadsheets with OpenXML page setup
class ExcelXlsxGenerator {
  static const _summaryGroups = [
    ('Hazır Kıta', 'HAZIR_KITA'),
    ('Gülüşkür', 'GULUSKUR'),
    ('Diğer Tüm Personel', 'DIGER_TUM_PERSONEL'),
  ];

  static final _tableBorder = Border(
    borderStyle: BorderStyle.Thin,
    borderColorHex: ExcelColor.fromHexString('#000000'),
  );

  static final _noneBorder = Border(
    borderStyle: BorderStyle.None,
  );

  /// Generates native binary .xlsx spreadsheet matching the official military daily activity duty list format
  static List<int> generateMilitaryExcelBytes({
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
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      .value = TextCellValue(titleHeader);

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

  /// Generates native binary .xlsx spreadsheet for all daily activities combined
  static List<int> generateMasterDailyExcelBytes({
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
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      .value = TextCellValue(title);
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
      sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      ).value = TextCellValue(act.sectionHeader);

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

  static double _excelRowHeightFor(String name, String detail, String rank) {
    final longest = [name.length, detail.length, rank.length]
        .fold<int>(0, (max, length) => length > max ? length : max);
    return longest > 32 ? 32 : 20;
  }

  static void _mergeAndSetOuterBorders(
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

  static int _writeThreeBoxSummary({
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
                    row.groupCode != 'HAZIR_KITA' &&
                    row.groupCode != 'GULUSKUR',
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

  static List<String> _rankSummaryLines(RankSummaryCounts counts) => [
        if (counts.subayCount > 0) 'SB. ${counts.subayCount}',
        if (counts.astsubayCount > 0) 'ASB. ${counts.astsubayCount}',
        if (counts.uzmanJandarmaCount > 0)
          'UZM.J. ${counts.uzmanJandarmaCount}',
        if (counts.uzmanErbasCount > 0) 'J.UZM.ÇVŞ. ${counts.uzmanErbasCount}',
        if (counts.erCount > 0) 'ER/SÖZ.ER ${counts.erCount}',
      ];

  static void _writeMergedSummaryCell(
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

  static List<int> _applyPrintSettings(
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
    final printTitles =
        '<definedName name="_xlnm.Print_Titles" localSheetId="0">'
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
      final definedNames =
          '<definedNames>$printArea$printTitles</definedNames>';
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

  static bool _sameBirlik(String first, String second) {
    String normalize(String value) => value
        .trim()
        .toUpperCase()
        .replaceAll('İ', 'I')
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalize(first) == normalize(second);
  }
}

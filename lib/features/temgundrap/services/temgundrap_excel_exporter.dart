import 'dart:ui';
import 'package:excel/excel.dart';
import 'package:personelapp2/features/activity/services/roster_share_file.dart';
import 'package:personelapp2/core/utils/export_file_name_helper.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_formatters.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_pdf_exporter.dart';
import 'package:personelapp2/l10n/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class TemgundrapExcelExporter {
  const TemgundrapExcelExporter._();

  static List<int> build(TemgundrapDocument document, [AppLocalizations? l10n]) {
    final localizations = l10n ?? lookupAppLocalizations(const Locale('tr'));
    final excel = Excel.createExcel();
    const sheetName = 'TEMGÜNDRAP';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.tables.containsKey('Sheet1')) excel.delete('Sheet1');

    final thin = Border(
      borderStyle: BorderStyle.Thin,
      borderColorHex: ExcelColor.fromHexString('#000000'),
    );
    CellStyle style({bool bold = false, int size = 10}) => CellStyle(
      bold: bold,
      fontFamily: getFontFamily(FontFamily.Arial),
      fontSize: size,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
      textWrapping: TextWrapping.WrapText,
      leftBorder: thin,
      rightBorder: thin,
      topBorder: thin,
      bottomBorder: thin,
    );
    final titleStyle = style(bold: true, size: 11);
    final headerStyle = style(bold: true, size: 10);
    final dataStyle = style(size: 10);

    void set(int column, int row, String value, CellStyle cellStyle) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        ..value = TextCellValue(value)
        ..cellStyle = cellStyle;
    }

    void merge(int c1, int r1, int c2, int r2, {CellStyle? mergedStyle}) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: c1, rowIndex: r1),
        CellIndex.indexByColumnRow(columnIndex: c2, rowIndex: r2),
      );
      for (var row = r1; row <= r2; row++) {
        for (var column = c1; column <= c2; column++) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
              )
              .cellStyle = mergedStyle ?? (row == 0 ? titleStyle : headerStyle);
        }
      }
    }

    // Keep the official document heading identical in both export formats.
    set(0, 0, TemgundrapPdfExporter.documentTitle(document, localizations), titleStyle);
    merge(0, 0, 10, 0);
    final mainHeaders = <int, String>{
      0: localizations.temgundrapExportColSequence,
      1: localizations.temgundrapExportColIssuingUnit,
      2: localizations.temgundrapExportColOperationArea,
      7: localizations.temgundrapExportColStartTime,
      8: localizations.temgundrapExportColEndTime,
      9: localizations.temgundrapExportColPurpose,
      10: localizations.temgundrapExportColDescription,
    };
    for (final entry in mainHeaders.entries) {
      set(entry.key, 1, entry.value, headerStyle);
      merge(entry.key, 1, entry.key, 2);
    }
    set(3, 1, localizations.temgundrapExportColForceHeader, headerStyle);
    merge(3, 1, 6, 1);
    final subHeaders = [
      localizations.temgundrapExportColForce,
      localizations.temgundrapExportColCommander,
      localizations.temgundrapExportColPresent,
      '',
    ];
    for (var index = 0; index < subHeaders.length; index++) {
      set(3 + index, 2, subHeaders[index], headerStyle);
    }

    for (final entry in document.operations.asMap().entries) {
      final row = 3 + entry.key;
      final operation = entry.value;
      final strengthLabels = [
        ...operation.strength.byLabel.keys,
        localizations.temgundrapExportTotal,
      ].join('\n');
      final strengthValues = [
        ...operation.strength.byLabel.values,
        operation.totalStrength,
      ].join('\n');
      final values = [
        '${entry.key + 1}',
        operation.issuingUnit,
        operation.operationArea,
        operation.forceDescription,
        operation.commander.displayText,
        strengthLabels,
        strengthValues,
        TemgundrapFormatters.militaryDateTime(operation.startAt),
        TemgundrapFormatters.militaryDateTime(operation.endAt),
        operation.purpose,
        operation.description,
      ];
      for (var column = 0; column < values.length; column++) {
        set(column, row, values[column], dataStyle);
      }
      sheet.setRowHeight(row, 88);
    }

    final lastOpRow = 3 + document.operations.length;
    var sigRow = lastOpRow + 2;

    if (document.approverName.isNotEmpty ||
        document.approverRank.isNotEmpty ||
        document.approverDuty.isNotEmpty) {
      final sigStyleBold = CellStyle(
        bold: true,
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      final sigStyleNormal = CellStyle(
        bold: false,
        fontFamily: getFontFamily(FontFamily.Arial),
        fontSize: 10,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      void setSigLine(String text, CellStyle cellStyle) {
        set(8, sigRow, text, cellStyle);
        merge(8, sigRow, 10, sigRow, mergedStyle: cellStyle);
        sheet.setRowHeight(sigRow, 20);
        sigRow++;
      }

      setSigLine(localizations.temgundrapSigned, sigStyleBold);
      if (document.approverName.isNotEmpty) {
        setSigLine(document.approverName, sigStyleNormal);
      }
      if (document.approverRank.isNotEmpty) {
        setSigLine(document.approverRank, sigStyleNormal);
      }
      if (document.approverDuty.isNotEmpty) {
        setSigLine(document.approverDuty, sigStyleNormal);
      }
    }

    const widths = [
      6.5,
      22.0,
      26.0,
      17.0,
      30.0,
      14.0,
      4.5,
      22.0,
      22.0,
      28.0,
      24.0,
    ];
    for (var column = 0; column < widths.length; column++) {
      sheet.setColumnWidth(column, widths[column]);
    }
    sheet
      ..setRowHeight(0, 34)
      ..setRowHeight(1, 24)
      ..setRowHeight(2, 24);
    return excel.encode() ?? <int>[];
  }

  static Future<void> share(
    TemgundrapDocument document, [
    AppLocalizations? l10n,
  ]) async {
    final localizations = l10n ?? lookupAppLocalizations(const Locale('tr'));
    final dateStr =
        '${document.date.year}-${document.date.month.toString().padLeft(2, '0')}-${document.date.day.toString().padLeft(2, '0')}';
    final fileName = formatExportFileName(
      title: 'TEMGÜNDRAP_${document.unitTitle}',
      date: dateStr,
      extension: 'xlsx',
    );
    final file = await createRosterShareFile(fileName, build(document, localizations));
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: localizations.temgundrapExportShareTextExcel,
      ),
    );
  }
}

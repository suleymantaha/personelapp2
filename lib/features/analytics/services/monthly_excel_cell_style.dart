import 'package:excel/excel.dart';

/// Keep counts numeric; Excel renders grouping using the reader's locale.
CellStyle monthlyExcelCellStyle(int row, Object value) => CellStyle(
      numberFormat:
          NumFormat.custom(formatCode: value is double ? '0.00' : '#,##0'),
      rightBorder: row == 0
          ? Border(
              borderStyle: BorderStyle.Thin,
              borderColorHex: ExcelColor.fromHexString('#A7B8CE'))
          : null,
      bold: row == 0,
      fontColorHex: row == 0 ? ExcelColor.white : ExcelColor.black,
      backgroundColorHex: ExcelColor.fromHexString(
          row == 0 ? '#17365D' : (row.isEven ? '#EDF3F8' : '#FFFFFF')),
      textWrapping: TextWrapping.WrapText,
      verticalAlign: VerticalAlign.Center,
    );

import 'dart:math' as math;
import 'package:excel/excel.dart';
import 'package:flutter/painting.dart' as f;

class SpreadsheetImageCell {
  SpreadsheetImageCell(this.text, this.style, this.rect, this.borders);
  final String text;
  final CellStyle? style;
  final f.Rect rect;
  final List<Border?> borders; // left, top, right, bottom
}

/// Layout is derived from the exported workbook, including its summary columns.
class SpreadsheetImageLayout {
  SpreadsheetImageLayout(this.cells, this.width, this.height);
  final List<SpreadsheetImageCell> cells;
  final double width;
  final double height;
  static const margin = 16.0;

  factory SpreadsheetImageLayout.fromSheet(Sheet sheet) {
    // excel 4.x leaves these null when OOXML omits sheetFormatPr defaults.
    sheet.setDefaultColumnWidth(sheet.defaultColumnWidth ?? 8.43);
    sheet.setDefaultRowHeight(sheet.defaultRowHeight ?? 15);
    final data = sheet.rows;
    final spans = <(int, int), (int, int)>{};
    final covered = <(int, int)>{};
    for (final range in sheet.spannedItems) {
      final ends = range.split(':').map(CellIndex.indexByString).toList();
      final a = ends.first, b = ends.last;
      spans[(a.rowIndex, a.columnIndex)] = (b.rowIndex, b.columnIndex);
      for (var r = a.rowIndex; r <= b.rowIndex; r++) {
        for (var c = a.columnIndex; c <= b.columnIndex; c++) {
          if (r != a.rowIndex || c != a.columnIndex) covered.add((r, c));
        }
      }
    }
    final widths = List.generate(sheet.maxColumns,
        (c) => math.max(12.0, sheet.getColumnWidth(c) * 7 + 5));
    final heights = List.generate(
        sheet.maxRows, (r) => math.max(4.0, sheet.getRowHeight(r) * 4 / 3));
    final entries = <(int, int, int, int, Data)>[];
    for (var r = 0; r < data.length; r++) {
      for (var c = 0; c < data[r].length; c++) {
        final cell = data[r][c];
        if (cell == null || covered.contains((r, c))) continue;
        final end = spans[(r, c)] ?? (r, c);
        entries.add((r, c, end.$1, end.$2, cell));
      }
    }
    // Measure every cell with real glyphs rather than truncating long names.
    for (final e in entries) {
      final width = widths.sublist(e.$2, e.$4 + 1).reduce((a, b) => a + b);
      final painter = spreadsheetText(
          e.$5.value?.toString() ?? '', e.$5.cellStyle, width - 8);
      final available = heights.sublist(e.$1, e.$3 + 1).reduce((a, b) => a + b);
      if (painter.height + 8 > available) {
        heights[e.$3] += painter.height + 8 - available;
      }
      painter.dispose();
    }
    List<double> offsets(List<double> sizes) {
      final result = <double>[margin];
      for (final size in sizes) {
        result.add(result.last + size);
      }
      return result;
    }

    final x = offsets(widths), y = offsets(heights);
    final cells = entries.map((e) {
      CellStyle? styleAt(int r, int c) => data[r][c]?.cellStyle;
      final style = e.$5.cellStyle;
      return SpreadsheetImageCell(e.$5.value?.toString() ?? '', style,
          f.Rect.fromLTRB(x[e.$2], y[e.$1], x[e.$4 + 1], y[e.$3 + 1]), [
        style?.leftBorder,
        style?.topBorder,
        styleAt(e.$1, e.$4)?.rightBorder,
        styleAt(e.$3, e.$2)?.bottomBorder,
      ]);
    }).toList();
    return SpreadsheetImageLayout(cells, x.last + margin, y.last + margin);
  }
}

f.Color spreadsheetColor(ExcelColor? color, f.Color fallback) {
  final hex = color?.colorHex;
  if (hex == null || color == ExcelColor.none) return fallback;
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  return value == null ? fallback : f.Color(value | 0xff000000);
}

f.TextPainter spreadsheetText(String text, CellStyle? style, double width) =>
    f.TextPainter(
      text: f.TextSpan(
          text: text,
          style: f.TextStyle(
            fontFamily: 'RosterImage',
            fontSize: (style?.fontSize ?? 11) * 4 / 3,
            fontWeight:
                style?.isBold == true ? f.FontWeight.bold : f.FontWeight.normal,
            fontStyle: style?.isItalic == true
                ? f.FontStyle.italic
                : f.FontStyle.normal,
            color:
                spreadsheetColor(style?.fontColor, const f.Color(0xff000000)),
          )),
      textDirection: f.TextDirection.ltr,
      textAlign: switch (style?.horizontalAlignment) {
        HorizontalAlign.Center => f.TextAlign.center,
        HorizontalAlign.Right => f.TextAlign.right,
        _ => f.TextAlign.left,
      },
    )..layout(minWidth: width, maxWidth: width);

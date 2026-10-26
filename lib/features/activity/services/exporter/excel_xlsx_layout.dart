part of 'excel_xlsx_generator.dart';

/// Share the five personnel fields and three summary boxes on one column grid.
/// Split only the rank/name fields at the one-third boundaries. Account for
/// Excel's 5px column padding, so splitting does not widen the original table.
/// Horizontal field merges are structural, even when vertical merges are off.
List<int>? _encodeRosterLayout(Sheet source, int summaryStartRow) {
  source.setDefaultRowHeight(source.defaultRowHeight ?? 15);
  const fieldStarts = [0, 1, 2, 4, 6];
  const fieldEnds = [0, 1, 3, 5, 6];
  const summaryStarts = [0, 3, 5];
  const summaryEnds = [2, 4, 6];
  const tableWidth = 760.0; // sum(width * 7 + 5) for 10, 22, 18, 30, 25.
  const edges = [
    0.0,
    75.0,
    234.0,
    tableWidth / 3,
    365.0,
    tableWidth * 2 / 3,
    580.0,
    tableWidth
  ];
  final output = Excel.createExcel();
  final sheet = output[source.sheetName];
  output.setDefaultSheet(source.sheetName);
  if (source.sheetName != 'Sheet1') output.delete('Sheet1');
  for (var c = 0; c < edges.length - 1; c++) {
    sheet.setColumnWidth(c, (edges[c + 1] - edges[c] - 5) / 7);
  }

  final spans = <(int, int), CellIndex>{};
  final covered = <(int, int)>{};
  for (final range in source.spannedItems) {
    final ends = range.split(':').map(CellIndex.indexByString).toList();
    final start = ends.first, end = ends.last;
    if (start.rowIndex >= summaryStartRow) continue;
    spans[(start.rowIndex, start.columnIndex)] = end;
    for (var r = start.rowIndex; r <= end.rowIndex; r++) {
      for (var c = start.columnIndex; c <= end.columnIndex; c++) {
        if (r != start.rowIndex || c != start.columnIndex) covered.add((r, c));
      }
    }
  }

  void copyCell(Data cell, int r, int start, int end, int lastRow) {
    if (start != end || r != lastRow) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: start, rowIndex: r),
        CellIndex.indexByColumnRow(columnIndex: end, rowIndex: lastRow),
      );
    }
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: start, rowIndex: r))
        .value = cell.value;
    for (var row = r; row <= lastRow; row++) {
      for (var c = start; c <= end; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
            .cellStyle = cell.cellStyle;
      }
    }
  }

  final data = source.rows;
  for (var r = 0; r < data.length; r++) {
    sheet.setRowHeight(r, source.getRowHeight(r));
    for (var c = 0; c < data[r].length; c++) {
      final cell = data[r][c];
      if (cell == null || covered.contains((r, c))) continue;
      if (r >= summaryStartRow) {
        // Summary anchors are logical A, C, E in the generation sheet.
        if (c != 0 && c != 2 && c != 4) continue;
        final index = c ~/ 2;
        copyCell(cell, r, summaryStarts[index], summaryEnds[index], r);
      } else if (c < fieldStarts.length) {
        final end = spans[(r, c)];
        copyCell(cell, r, fieldStarts[c], fieldEnds[end?.columnIndex ?? c],
            end?.rowIndex ?? r);
      }
    }
  }
  return output.encode();
}

part of 'excel_xlsx_generator.dart';

// A4 portrait has about 770 pt after the sheet's half-inch margins.
// Leave room for rounding and printer margins. At 90% the table also fits
// inside the printable width. At 84%, 10 pt personnel type still prints at 8.4 pt.
const _printableHeight = 760.0;
const _normalPrintScale = 90;
const _minimumPrintScale = 84;
const _rosterHeaderHeight = 24.0;

typedef _RosterPrint = ({int? scale, List<int> breaks});

bool _needsCompactRosterRows(
  List<MilitaryRosterRow> rows,
  double titleHeight, {
  double sectionHeight = 0,
}) {
  var height = titleHeight + _rosterHeaderHeight + sectionHeight;
  final onePage = _printableHeight * 100 / _normalPrintScale;
  for (final row in rows) {
    height += _rosterRowHeight(row, compact: false);
    if (height > onePage) return true;
  }
  return height > onePage;
}

_RosterPrint _planRosterPrint(
  Sheet sheet, {
  required int endRow,
  required bool fixedScale,
  int? lastBreakRow,
  Set<int> keepWithPrevious = const {},
}) {
  if (!fixedScale) return (scale: null, breaks: const []);
  final headerHeight = sheet.getRowHeight(0) + sheet.getRowHeight(1);
  final heights = List.filled(endRow + 1, 0.0);
  for (var row = 2; row < endRow; row++) {
    heights[row + 1] = heights[row] + sheet.getRowHeight(row);
  }
  final totalHeight = heights.last;
  double capacity(int scale) => _printableHeight * 100 / scale - headerHeight;
  if (totalHeight <= capacity(_normalPrintScale)) {
    return (scale: _normalPrintScale, breaks: const []);
  }

  final candidates = [
    for (var row = 3; row <= (lastBreakRow ?? endRow - 1); row++)
      if (!keepWithPrevious.contains(row)) row,
  ];
  // Avoid breaking unit and duty merges where a reasonably balanced boundary
  // is available. Horizontal spans cannot constrain a row break.
  final insideMerge = <int>{};
  for (final range in sheet.spannedItems) {
    final ends = range.split(':');
    final start = CellIndex.indexByString(ends.first).rowIndex;
    final end = CellIndex.indexByString(ends.last).rowIndex;
    for (var row = start + 1; row <= end; row++) {
      insideMerge.add(row);
    }
  }

  _RosterPrint? bestTwoPages;
  for (var scale = _normalPrintScale; scale >= _minimumPrintScale; scale--) {
    final available = capacity(scale);
    if (totalHeight > 2 * available) continue;
    int? balanced;
    int? boundary;
    var bestImbalance = double.infinity;
    var boundaryImbalance = double.infinity;
    for (final row in candidates) {
      final firstPage = heights[row];
      final lastPage = totalHeight - firstPage;
      if (math.max(firstPage, lastPage) > available) continue;
      final imbalance = (firstPage - lastPage).abs();
      if (imbalance < bestImbalance) {
        bestImbalance = imbalance;
        balanced = row;
      }
      if (!insideMerge.contains(row) && imbalance < boundaryImbalance) {
        boundaryImbalance = imbalance;
        boundary = row;
      }
    }
    if (boundary != null && boundaryImbalance <= bestImbalance + 100) {
      return (scale: scale, breaks: [boundary]);
    }
    if (balanced != null) bestTwoPages ??= (scale: scale, breaks: [balanced]);
  }
  if (bestTwoPages != null) return bestTwoPages;

  // When two pages are infeasible, keep full type size and fill more pages.
  return (
    scale: _normalPrintScale,
    breaks: _fillRosterPages(
      [2, ...candidates, endRow],
      heights,
      insideMerge,
      capacity(_normalPrintScale),
    ),
  );
}

List<int> _fillRosterPages(
  List<int> cuts,
  List<double> heights,
  Set<int> insideMerge,
  double available,
) {
  // Find the farthest fitting cut and the minimum number of remaining pages
  // from each candidate. Favor a nearby unit boundary if page count is equal.
  final last = cuts.length - 1;
  final furthest = List.filled(cuts.length, last);
  final remainingPages = List.filled(cuts.length, 0);
  var end = last;
  for (var start = last - 1; start >= 0; start--) {
    while (end > start + 1 &&
        heights[cuts[end]] - heights[cuts[start]] > available) {
      end--;
    }
    furthest[start] = end;
    remainingPages[start] = remainingPages[end] + 1;
  }

  final breaks = <int>[];
  var start = 0;
  while (furthest[start] < last) {
    final limit = furthest[start];
    var cut = limit;
    for (var candidate = limit; candidate > start; candidate--) {
      if (heights[cuts[limit]] - heights[cuts[candidate]] > 42) break;
      if (remainingPages[candidate] == remainingPages[limit] &&
          !insideMerge.contains(cuts[candidate])) {
        cut = candidate;
        break;
      }
    }
    breaks.add(cuts[cut]);
    start = cut;
  }
  return breaks;
}

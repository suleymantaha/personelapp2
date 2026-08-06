import 'package:flutter/material.dart';
import 'package:personelapp2/core/theme/spacing.dart';

class DashboardGridLayout {
  const DashboardGridLayout._(this.columnCount, this.cardAspectRatio);

  final int columnCount;
  final double cardAspectRatio;

  factory DashboardGridLayout.calculate(BoxConstraints constraints, int count) {
    final columns = _columnCount(constraints, count);
    final rows = (count / columns).ceil();
    final width =
        (constraints.maxWidth - AppSpacing.cardGap * (columns - 1)) / columns;
    final height =
        (constraints.maxHeight - AppSpacing.cardGap * (rows - 1)) / rows;
    return DashboardGridLayout._(columns, width / height);
  }

  static int _columnCount(BoxConstraints constraints, int count) {
    const minWidth = 120.0;
    const minHeight = 105.0;
    var bestColumns = 1;
    var bestScore = double.infinity;
    for (var columns = 1; columns <= count; columns++) {
      final rows = (count / columns).ceil();
      final width =
          (constraints.maxWidth - AppSpacing.cardGap * (columns - 1)) / columns;
      final height =
          (constraints.maxHeight - AppSpacing.cardGap * (rows - 1)) / rows;
      if (width < minWidth || height < minHeight) continue;
      final emptyCells = rows * columns - count;
      final score =
          ((width / height) - 1.1).abs() + emptyCells / (rows * columns) * 2;
      if (score < bestScore) {
        bestScore = score;
        bestColumns = columns;
      }
    }
    if (bestScore.isFinite) return bestColumns;
    return (constraints.maxWidth / minWidth).floor().clamp(1, count);
  }
}

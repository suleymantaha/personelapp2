import 'package:flutter/material.dart';

/// Fits every authorized dashboard action into the available viewport.
/// Portrait phones use two columns; wide and landscape screens use four.
class DashboardGridLayout {
  const DashboardGridLayout._({
    required this.columnCount,
    required this.mainAxisExtent,
    required this.gap,
    required this.padding,
  });

  final int columnCount;
  final double mainAxisExtent;
  final double gap;
  final EdgeInsets padding;

  factory DashboardGridLayout.calculate(
    BoxConstraints constraints, {
    int itemCount = 8,
    bool hasWarningBanner = false,
  }) {
    final width = constraints.maxWidth;
    final height = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : 700.0;
    final columns = width >= 760 || (width >= 600 && width > height)
        ? 4
        : 2;
    final rows = (itemCount / columns).ceil().clamp(1, 10);
    final gap = height < 560 ? 6.0 : 10.0;
    final verticalPadding = height < 560 ? 7.0 : 12.0;
    final horizontalPadding = width < 360 ? 8.0 : 14.0;
    final bannerHeight = hasWarningBanner ? (height < 560 ? 52.0 : 72.0) : 0.0;
    final available = height -
        verticalPadding * 2 -
        bannerHeight -
        gap * (rows - 1);
    final extent = (available / rows).clamp(0.0, 210.0);

    return DashboardGridLayout._(
      columnCount: columns,
      mainAxisExtent: extent,
      gap: gap,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
    );
  }
}

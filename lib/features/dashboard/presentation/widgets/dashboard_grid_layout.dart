import 'package:flutter/material.dart';

class DashboardGridLayout {
  const DashboardGridLayout._({
    required this.columnCount,
    required this.mainAxisExtent,
    required this.archiveHeight,
    required this.gap,
    required this.padding,
  });

  final int columnCount;
  final double mainAxisExtent;
  final double archiveHeight;
  final double gap;
  final EdgeInsets padding;

  factory DashboardGridLayout.calculate(
    BoxConstraints constraints, {
    int itemCount = 6,
    bool hasArchive = true,
    bool hasWarningBanner = false,
  }) {
    final columns = constraints.maxWidth >= 720 ? 3 : 2;
    final gridRows = (itemCount / columns).ceil().clamp(1, 10);

    final double availableHeight =
        constraints.hasBoundedHeight && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 700.0;

    final double gap = availableHeight < 620
        ? 8.0
        : (availableHeight < 720 ? 10.0 : 12.0);

    final double vertPadding = availableHeight < 620 ? 8.0 : 12.0;

    final double titleHeight = availableHeight < 620 ? 22.0 : 26.0;
    final double bannerHeight = hasWarningBanner
        ? (availableHeight < 620 ? 56.0 : 64.0) + gap
        : 0.0;
    final double archiveHeight =
        hasArchive ? (availableHeight < 620 ? 54.0 : 64.0) : 0.0;

    final double fixedHeight = bannerHeight +
        titleHeight +
        (gap * 0.8) +
        (hasArchive ? (gap + archiveHeight) : 0.0) +
        (vertPadding * 2) +
        ((gridRows - 1) * gap);

    final double remainingGridHeight = availableHeight - fixedHeight;
    final double calculatedExtent = remainingGridHeight / gridRows;

    final double minExtent = availableHeight < 600 ? 116.0 : 120.0;
    final double maxExtent = columns == 3 ? 176.0 : 184.0;

    final double finalExtent = calculatedExtent.clamp(minExtent, maxExtent);

    return DashboardGridLayout._(
      columnCount: columns,
      mainAxisExtent: finalExtent,
      archiveHeight: archiveHeight,
      gap: gap,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: vertPadding),
    );
  }
}


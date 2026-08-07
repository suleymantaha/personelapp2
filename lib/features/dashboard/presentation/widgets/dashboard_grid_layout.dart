import 'package:flutter/material.dart';

class DashboardGridLayout {
  const DashboardGridLayout._({
    required this.columnCount,
    required this.mainAxisExtent,
  });

  final int columnCount;
  final double mainAxisExtent;

  factory DashboardGridLayout.calculate(BoxConstraints constraints) {
    final columns = constraints.maxWidth >= 720 ? 3 : 2;
    return DashboardGridLayout._(
      columnCount: columns,
      mainAxisExtent: columns == 3 ? 168 : 184,
    );
  }
}

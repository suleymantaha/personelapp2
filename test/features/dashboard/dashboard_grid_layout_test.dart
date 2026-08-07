import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_grid_layout.dart';

void main() {
  group('DashboardGridLayout', () {
    test('uses two columns on phone widths', () {
      for (final width in <double>[320, 360, 390, 600, 719]) {
        final layout = DashboardGridLayout.calculate(
          BoxConstraints.tightFor(width: width, height: 844),
        );

        expect(layout.columnCount, 2, reason: 'width=$width');
        expect(layout.mainAxisExtent, greaterThanOrEqualTo(168));
      }
    });

    test('uses three columns on wide content', () {
      final layout = DashboardGridLayout.calculate(
        const BoxConstraints.tightFor(width: 860, height: 800),
      );

      expect(layout.columnCount, 3);
      expect(layout.mainAxisExtent, greaterThanOrEqualTo(168));
    });

    test('ignores available height so page can scroll', () {
      final short = DashboardGridLayout.calculate(
        const BoxConstraints.tightFor(width: 390, height: 320),
      );
      final tall = DashboardGridLayout.calculate(
        const BoxConstraints.tightFor(width: 390, height: 1200),
      );

      expect(short.columnCount, tall.columnCount);
      expect(short.mainAxisExtent, tall.mainAxisExtent);
    });
  });
}

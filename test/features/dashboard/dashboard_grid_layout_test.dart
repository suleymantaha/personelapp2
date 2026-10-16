import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/dashboard/presentation/widgets/dashboard_grid_layout.dart';

void main() {
  group('DashboardGridLayout', () {
    test('portrait phone holds all eight tiles in four rows', () {
      for (final size in [
        const Size(320, 512),
        const Size(390, 740),
        const Size(600, 900),
      ]) {
        final layout = DashboardGridLayout.calculate(
          BoxConstraints.tight(size), itemCount: 8);
        expect(layout.columnCount, 2);
        final total = layout.mainAxisExtent * 4 +
            layout.gap * 3 + layout.padding.vertical;
        expect(total, lessThanOrEqualTo(size.height + 0.01));
        expect(layout.mainAxisExtent, greaterThan(80));
      }
    });

    test('landscape and desktop use four columns and two rows', () {
      for (final size in [
        const Size(844, 334),
        const Size(1280, 800),
      ]) {
        final layout = DashboardGridLayout.calculate(
            BoxConstraints.tight(size), itemCount: 8);
        expect(layout.columnCount, 4);
        final total = layout.mainAxisExtent * 2 +
            layout.gap + layout.padding.vertical;
        expect(total, lessThanOrEqualTo(size.height + 0.01));
      }
    });

    test('pending warning reserves space without pushing tiles off screen', () {
      final layout = DashboardGridLayout.calculate(
          const BoxConstraints.tightFor(width: 390, height: 560),
          itemCount: 8, hasWarningBanner: true);
      final total = layout.mainAxisExtent * 4 +
          layout.gap * 3 + layout.padding.vertical + 72;
      expect(total, lessThanOrEqualTo(560.01));
    });

    test('fewer visible actions still fit without forced scrolling', () {
      final layout = DashboardGridLayout.calculate(
          const BoxConstraints.tightFor(width: 390, height: 520),
          itemCount: 6);
      expect(layout.columnCount, 2);
      expect(layout.mainAxisExtent * 3 +
          layout.gap * 2 + layout.padding.vertical, lessThanOrEqualTo(520.01));
    });
  });
}

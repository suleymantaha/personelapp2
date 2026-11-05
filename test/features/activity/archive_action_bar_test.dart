import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/presentation/widgets/archive_action_bar.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('archive actions fit width $width and text scale $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final calls = <String>[];
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(
                size: Size(width, 800), textScaler: TextScaler.linear(scale)),
            child: ArchiveActionBar(
              onSelect: () => calls.add('select'),
              onCombine: () => calls.add('combine'),
              onReorder: () => calls.add('reorder'),
            ),
          ),
        )));
        final keys = [
          'archive-select-visible',
          'archive-prepare-cards',
          'archive-reorder-visible'
        ];
        final centers =
            keys.map((key) => tester.getCenter(find.byKey(Key(key)))).toList();
        expect(centers[0].dy, centers[1].dy);
        expect(centers[1].dy, centers[2].dy);
        for (final key in keys) {
          final button = find.byKey(Key(key));
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(tester.getBottomRight(button).dx, lessThanOrEqualTo(width));
          await tester.tap(button);
        }
        expect(calls, ['select', 'combine', 'reorder']);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

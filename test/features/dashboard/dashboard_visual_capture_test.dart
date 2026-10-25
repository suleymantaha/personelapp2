import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dashboard_test_host.dart';

void main() {
  testWidgets('capture the rendered Flutter mobile and desktop workspace',
      (tester) async {
    final loader = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    for (final entry in {
      'mobile': const Size(390, 844),
      'desktop': const Size(1440, 1024),
    }.entries) {
      for (final mode in [ThemeMode.light, ThemeMode.dark]) {
        await pumpDashboard(tester, size: entry.value, mode: mode);
        expect(tester.takeException(), isNull);
        final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('dashboard-capture')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file =
              File('build/design-preview/${entry.key}-${mode.name}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
  }, skip: !const bool.fromEnvironment('CAPTURE_DASHBOARD'));
}

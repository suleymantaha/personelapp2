import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'spreadsheet_image_layout.dart';
import 'spreadsheet_image_workbook.dart';

class SpreadsheetImageTooLarge implements Exception {
  const SpreadsheetImageTooLarge();
}

class SpreadsheetImageRenderer {
  static Future<void>? _fonts;
  static Future<void> _loadFonts() async {
    final loader = FontLoader('RosterImage')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    await loader.load();
  }

  static Future<Uint8List> render(List<int> workbook) async {
    await (_fonts ??= _loadFonts());
    final sheet = decodeSpreadsheetImageWorkbook(workbook);
    final layout = SpreadsheetImageLayout.fromSheet(sheet);
    // Bound native raster allocation; never silently crop or split the roster.
    final scale = math.min(
        2.0,
        math.min(32760 / layout.height,
            math.sqrt(32000000 / (layout.width * layout.height))));
    if (scale < 1 || layout.width * scale > 32760) {
      throw const SpreadsheetImageTooLarge();
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(scale);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, layout.width, layout.height),
        ui.Paint()..color = const ui.Color(0xffffffff));
    for (final cell in layout.cells) {
      _paintCell(canvas, cell);
    }
    final picture = recorder.endRecording();
    try {
      final image = await picture.toImage(
          (layout.width * scale).ceil(), (layout.height * scale).ceil());
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('PNG encoding failed');
        return bytes.buffer
            .asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
      } finally {
        image.dispose();
      }
    } finally {
      picture.dispose();
    }
  }

  static void _paintCell(ui.Canvas canvas, SpreadsheetImageCell cell) {
    canvas.drawRect(
        cell.rect,
        ui.Paint()
          ..color = spreadsheetColor(
              cell.style?.backgroundColor, const ui.Color(0xffffffff)));
    final r = cell.rect;
    final corners = [
      r.bottomLeft,
      r.topLeft,
      r.topRight,
      r.bottomRight,
      r.bottomLeft
    ];
    for (var i = 0; i < 4; i++) {
      final border = cell.borders[i];
      if (border?.borderStyle == null ||
          border!.borderStyle == BorderStyle.None) {
        continue;
      }
      canvas.drawLine(
          corners[i],
          corners[i + 1],
          ui.Paint()
            ..color = spreadsheetColor(
                border.borderColorHex == null
                    ? null
                    : ExcelColor.fromHexString(border.borderColorHex!),
                const ui.Color(0xff000000))
            ..strokeWidth = 0.8);
    }
    final painter = spreadsheetText(cell.text, cell.style, r.width - 8);
    final y = switch (cell.style?.verticalAlignment) {
      VerticalAlign.Top => r.top + 4,
      VerticalAlign.Bottom => r.bottom - painter.height - 4,
      _ => r.top + (r.height - painter.height) / 2,
    };
    painter.paint(canvas, ui.Offset(r.left + 4, y));
    painter.dispose();
  }
}

import 'dart:io';
import 'dart:ui' as ui;

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_layout.dart';
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_renderer.dart';
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_workbook.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/pdf_roster_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final rows = List.generate(
      120,
      (i) => MilitaryRosterRow(
            sNu: i + 1,
            birligi: 'ÖRNEK TİM ${i ~/ 5}',
            rutbe: [
              'J.Yzb.',
              'J.Asb.Çvş.',
              'Uzm.J.',
              'J.Uzm.Çvş.',
              'J.Er'
            ][i % 5],
            adSoyad: 'ÖRNEK UZUN ADLI PERSONEL ${i + 1}',
            diger: i == 119
                ? 'SON PERSONEL\nÇok satırlı görev açıklaması'
                : 'Görev',
            groupCode: ['HAZIR_KITA', 'GULUSKUR', 'DIGER'][i % 3],
          ));

  void verify(List<int> bytes) {
    final layout =
        SpreadsheetImageLayout.fromSheet(decodeSpreadsheetImageWorkbook(bytes));
    final boxes = ['Hazır Kıta', 'Gülüşkür', 'Diğer Tüm Personel']
        .map((label) => layout.cells.singleWhere((c) => c.text == label))
        .toList();
    final title = layout.cells.first;
    expect(boxes.first.rect.left, closeTo(title.rect.left, .01));
    expect(boxes.last.rect.right, closeTo(title.rect.right, .01));
    for (final box in boxes) {
      expect(box.rect.width, closeTo(title.rect.width / 3, .1));
      expect(
          box.borders.every((b) => b?.borderStyle == BorderStyle.Thin), isTrue);
    }
    final headers = ['S. NU', 'BİRLİĞİ', 'RÜTBE', 'ADI SOYADI', 'DİĞER']
        .map((label) => layout.cells.singleWhere((c) => c.text == label))
        .toList();
    for (var i = 0; i < headers.length; i++) {
      expect(headers[i].rect.width, closeTo([75, 159, 131, 215, 180][i], .1));
    }
    expect(layout.cells.where((c) => c.text == 'Toplam 40'), hasLength(3));
    expect(layout.cells.any((c) => c.text.startsWith('SON PERSONEL')), isTrue);
    for (final cell in layout.cells) {
      final painter =
          spreadsheetText(cell.text, cell.style, cell.rect.width - 8);
      expect(painter.height + 7.99, lessThanOrEqualTo(cell.rect.height));
      painter.dispose();
    }
  }

  for (final merged in [true, false]) {
    for (final signed in [true, false]) {
      test('equal summary geometry merged=$merged signed=$signed', () {
        verify(MilitaryRosterExporter.generateMilitaryExcelBytes(
            faaliyetAdi: 'SENTETİK LİSTE',
            tarih: '2026-10-26',
            rows: rows,
            mergeCells: merged,
            includeSignatures: signed));
      });
    }
  }
  test('master summary shares personnel and title bounds', () {
    verify(MilitaryRosterExporter.generateMasterDailyExcelBytes(
        title: 'SENTETİK GÜNLÜK LİSTE',
        activities: [
          MasterActivityData(
              faaliyetAdi: 'Görev',
              tarih: '2026-10-26',
              olusturanKullanici: 'Test',
              rows: rows)
        ]));
  });

  test('PDF summary boxes have equal laid-out widths and table bounds',
      () async {
    final font =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold =
        pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    for (final count in [0, 3, 120]) {
      final summary =
          PdfRosterExporter.builderSummaryBox(rows.take(count).toList())
              as pw.Row;
      final table = PdfRosterExporter.buildPdfTable(rows.take(3).toList());
      final pdf =
          pw.Document(theme: pw.ThemeData.withFont(base: font, bold: bold));
      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (_) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [table, summary])));
      await pdf.save();
      final boxes =
          summary.children.whereType<pw.Expanded>().map((e) => e.box!).toList();
      expect(boxes, hasLength(3));
      for (final box in boxes) {
        expect(box.width, closeTo((summary.box!.width - 12) / 3, .001));
      }
      expect(boxes.first.left, closeTo(0, .001));
      expect(boxes.last.right, closeTo(table.box!.width, .001));
    }
  });

  test('write synthetic XLSX PNG and PDF inspection artifacts', () async {
    final folder = Directory('build/summary-width-validation');
    await folder.create(recursive: true);
    for (final merged in [true, false]) {
      final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
          faaliyetAdi: 'SENTETİK LİSTE',
          tarih: '2026-10-26',
          rows: rows,
          mergeCells: merged,
          includeSignatures: true);
      await File('${folder.path}/roster-$merged.xlsx').writeAsBytes(bytes);
      final png = await SpreadsheetImageRenderer.render(bytes);
      await File('${folder.path}/roster-$merged.png').writeAsBytes(png);
      final layout = SpreadsheetImageLayout.fromSheet(
          decodeSpreadsheetImageWorkbook(bytes));
      final headers = ['Hazır Kıta', 'Gülüşkür', 'Diğer Tüm Personel']
          .map((text) => layout.cells.singleWhere((cell) => cell.text == text))
          .toList();
      final codec = await ui.instantiateImageCodec(png);
      final image = (await codec.getNextFrame()).image;
      final pixels = (await image.toByteData())!;
      final scale = image.width / layout.width;
      final y = ((headers.first.rect.top + 3) * scale).round();
      // Probe away from the text: these are painted border pixels, not just
      // matching column-width metadata. All labels/counts were measured above.
      final edges = [
        headers.first.rect.left,
        ...headers.map((c) => c.rect.right)
      ];
      final painted = edges.map((edge) {
        final expected = (edge * scale).round();
        final candidates = [expected - 1, expected, expected + 1];
        return candidates.firstWhere(
            (x) => pixels.getUint8((y * image.width + x) * 4) < 100);
      }).toList();
      final widths = List.generate(3, (i) => painted[i + 1] - painted[i]);
      expect(
          widths.reduce((a, b) => a > b ? a : b) -
              widths.reduce((a, b) => a < b ? a : b),
          lessThanOrEqualTo(1));
      expect(image.height, greaterThan(image.width * 2));
      image.dispose();
      codec.dispose();
    }
    final pdf = await PdfRosterExporter.generateRosterPdf(
        faaliyetAdi: 'SENTETİK LİSTE', tarih: '2026-10-26', rows: rows);
    await File('${folder.path}/roster.pdf').writeAsBytes(await pdf.save());
  });
}

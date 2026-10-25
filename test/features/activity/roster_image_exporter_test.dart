import 'dart:io';
import 'dart:ui' as ui;

import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_layout.dart';
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_workbook.dart';
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_renderer.dart';
import 'package:personelapp2/features/activity/services/roster_image_exporter.dart';
import 'package:personelapp2/features/activity/services/roster_signature.dart';
import 'package:personelapp2/features/activity/services/roster_share_mime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  List<MilitaryRosterRow> rows(int count) => List.generate(
      count,
      (i) => MilitaryRosterRow(
          sNu: i + 1,
          birligi: 'ÖRNEK BİRLİK',
          rutbe: 'J.Asb.Çvş.',
          adSoyad: 'ÖRNEK PERSONEL ${i + 1}',
          diger: i == count - 1 ? 'SON SATIR' : '',
          groupCode: 'DIGER'));

  test('uses actual Excel spans, title colors, all rows and summaries', () {
    final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
        faaliyetAdi: 'GÜNLÜK LİSTE', tarih: '2026-10-25', rows: rows(120));
    final sheet = decodeSpreadsheetImageWorkbook(bytes);
    final layout = SpreadsheetImageLayout.fromSheet(sheet);
    expect(layout.cells.any((c) => c.text == 'SON SATIR'), isTrue);
    expect(layout.cells.any((c) => c.text == 'Toplam 120'), isTrue);
    final title = layout.cells
        .firstWhere((c) => c.text.contains('PERSONEL İSİM LİSTESİ'));
    expect(title.style?.horizontalAlignment, HorizontalAlign.Center);
    expect(title.style?.backgroundColor.colorHex, endsWith('E8EEF5'));
    expect(title.rect.width, greaterThan(600));
    expect(layout.height, greaterThan(2000));
    expect(layout.cells.where((c) => c.text == 'ÖRNEK BİRLİK'), hasLength(1));
    for (final cell in layout.cells) {
      final painter =
          spreadsheetText(cell.text, cell.style, cell.rect.width - 8);
      expect(painter.height, lessThanOrEqualTo(cell.rect.height - 7.99));
      painter.dispose();
    }
  });

  test('grows rows for long Turkish names and multiline text', () {
    final sheet = Excel.createExcel()['Test'];
    sheet.setColumnWidth(0, 15);
    sheet.setRowHeight(0, 14);
    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue(List.filled(15, 'ĞÜŞİÖÇ uzun açıklama').join('\n'));
    final layout = SpreadsheetImageLayout.fromSheet(sheet);
    expect(layout.cells.single.rect.height, greaterThan(200));
  });

  test('renders complete long PNG with signatures and correct background',
      () async {
    final png = await RosterImageExporter.generate(
        faaliyetAdi: 'GÜNLÜK LİSTE',
        tarih: '2026-10-25',
        rows: rows(120),
        mergeCells: false,
        includeSignatures: true,
        signers: const [
          RosterSigner(
              'TANZİM EDEN', 'Örnek Kişi', 'Örnek Rütbe', 'Örnek Görev'),
          RosterSigner(
              'TASDİK EDEN', 'Test Kişisi', 'Test Rütbesi', 'Test Görevi')
        ]);
    expect(png.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final codec = await ui.instantiateImageCodec(png);
    final frame = await codec.getNextFrame();
    expect(frame.image.height, greaterThan(frame.image.width * 2));
    final pixels = await frame.image.toByteData();
    expect(pixels!.getUint8(0), 255);
    frame.image.dispose();
    codec.dispose();
    // Synthetic visual artifact for inspection, no actual personnel records.
    await Directory('build/roster-image-validation').create(recursive: true);
    await File('build/roster-image-validation/daily-list.png')
        .writeAsBytes(png);
  });

  test(
      'Android save uses document picker, PNG MIME and unique names; cancellation propagates',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('nizam/backup_files');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <Map<dynamic, dynamic>>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'saveBackup');
      calls.add(call.arguments as Map<dynamic, dynamic>);
      return calls.length < 3;
    });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(channel, null);
    });
    for (var i = 0; i < 3; i++) {
      expect(
          await RosterImageExporter.save(
              faaliyetAdi: 'Test', tarih: '2026-10-25', rows: rows(2)),
          i < 2);
    }
    expect(calls.map((c) => c['name']).toSet(), hasLength(3));
    for (final c in calls) {
      expect(c['mimeType'], 'image/png');
      expect(c['name'], endsWith('.png'));
      expect((c['bytes'] as List).take(4), [137, 80, 78, 71]);
    }
    expect(rosterMimeType('Test.PNG'), 'image/png');
    expect(rosterMimeType('Test.pdf'), 'application/pdf');
  });

  test('oversized workbook is rejected instead of cropping the list', () async {
    final sheet = Excel.createExcel();
    sheet['Sheet1'].setRowHeight(0, 30000);
    sheet['Sheet1'].cell(CellIndex.indexByString('A1')).value =
        TextCellValue('Full list');
    await expectLater(SpreadsheetImageRenderer.render(sheet.encode()!),
        throwsA(isA<SpreadsheetImageTooLarge>()));
  });
}

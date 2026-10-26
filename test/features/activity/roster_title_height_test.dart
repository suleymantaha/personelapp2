import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_layout.dart';
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_renderer.dart';
import 'package:personelapp2/features/activity/services/exporter/spreadsheet_image_workbook.dart';
import 'package:personelapp2/features/activity/services/military_roster_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> verifyTitle(List<int> bytes,
      {required double minimumHeight}) async {
    await SpreadsheetImageRenderer.render(bytes); // Loads the export font.
    final sheet = decodeSpreadsheetImageWorkbook(bytes);
    final title = SpreadsheetImageLayout.fromSheet(sheet).cells.first;
    final excelHeight = sheet.getRowHeight(0);
    expect(excelHeight, greaterThanOrEqualTo(minimumHeight));
    expect(title.rect.height, closeTo(excelHeight * 4 / 3, .01));
    expect(title.style?.fontSize, 14);
    expect(title.style?.wrap, TextWrapping.WrapText);
    final painter =
        spreadsheetText(title.text, title.style, title.rect.width - 8);
    expect(painter.height + 16, lessThanOrEqualTo(title.rect.height));
    painter.dispose();
  }

  for (final merged in [true, false]) {
    for (final signed in [true, false]) {
      test('official title fits merged=$merged signed=$signed', () async {
        final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
          faaliyetAdi: 'Heybet',
          tarih: '2026-10-26',
          timeRange: '06.00-08.00',
          rows: const [],
          mergeCells: merged,
          includeSignatures: signed,
        );
        await verifyTitle(bytes, minimumHeight: 48);
        final title = Excel.decodeBytes(bytes)['İsim Listesi']
            .cell(CellIndex.indexByString('A1'))
            .value
            .toString();
        expect(title, contains('(06.00-08.00 SAATLERİ ARASI)'));
      });
    }
  }

  test('master three line title has room in Excel', () async {
    final bytes = MilitaryRosterExporter.generateMasterDailyExcelBytes(
      title: 'SENTETİK GÜNLÜK FAALİYET LİSTESİ\n'
          '26.10.2026 TARİHLİ BÜTÜN GÖREVLER\n'
          'PERSONEL İSİM LİSTESİ',
      activities: const [],
    );
    await verifyTitle(bytes, minimumHeight: 60);
  });

  for (final title in [
    List.filled(43, 'W').join(),
    List.filled(45, '漢字').join(),
    List.filled(30, '😀').join(),
  ]) {
    test('wide master title fits its encoded row: ${title.runes.first}',
        () async {
      final bytes = MilitaryRosterExporter.generateMasterDailyExcelBytes(
        title: title,
        activities: const [],
      );
      await verifyTitle(bytes, minimumHeight: 32);
    });
  }

  test('writes synthetic 120 row title inspection artifacts', () async {
    final folder = Directory('build/header-duplex-validation');
    await folder.create(recursive: true);
    final rows = List.generate(
      120,
      (i) => MilitaryRosterRow(
        sNu: i + 1,
        birligi: 'SENTETİK TİM',
        rutbe: 'J.Uzm.Çvş.',
        adSoyad: 'ÖRNEK PERSONEL ${i + 1}',
        diger: 'Görev',
      ),
    );
    for (final merged in [true, false]) {
      final bytes = MilitaryRosterExporter.generateMilitaryExcelBytes(
        faaliyetAdi: 'Heybet',
        tarih: '2026-10-26',
        timeRange: '06.00-08.00',
        rows: rows,
        mergeCells: merged,
        includeSignatures: true,
      );
      final name = merged ? 'merged' : 'unmerged';
      await File('${folder.path}/title-120-$name.xlsx').writeAsBytes(bytes);
      await File('${folder.path}/title-120-$name.png')
          .writeAsBytes(await SpreadsheetImageRenderer.render(bytes));
    }
  });
}

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:share_plus/share_plus.dart';

class ExcelXmlGenerator {
  /// XML special character escaping helper (for backward compatibility if needed)
  static String escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Generates a native binary .xlsx document for the monthly activity matrix
  static List<int> generateExcelBytes({
    required List<PersonelTableData> personnel,
    required Map<int, Map<int, String>> matrixData,
    required int year,
    required int month,
  }) {
    final excel = Excel.createExcel();
    const sheetName = 'Aylık Faaliyet Matrisi';
    final sheet = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#4A5D36'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellNormalStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellGorevliStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#C8E6C9'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellIzinliStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellRaporluStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#FFCDD2'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    final cellBekleyenStyle = CellStyle(
      fontFamily: getFontFamily(FontFamily.Calibri),
      fontSize: 10,
      backgroundColorHex: ExcelColor.fromHexString('#FFF9C4'),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('S.No')
      ..cellStyle = headerStyle;

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
      ..value = TextCellValue('Rütbesi ve Adı Soyadı')
      ..cellStyle = headerStyle;

    final daysInMonth = DateTime(year, month + 1, 0).day;
    for (var day = 1; day <= daysInMonth; day++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: day + 1, rowIndex: 0))
        ..value = IntCellValue(day)
        ..cellStyle = headerStyle;
    }

    // Personnel Data Rows
    for (var i = 0; i < personnel.length; i++) {
      final p = personnel[i];
      final rowIndex = i + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        ..value = IntCellValue(i + 1)
        ..cellStyle = cellNormalStyle;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = TextCellValue('${p.rutbe} ${p.adSoyad}')
        ..cellStyle = cellNormalStyle;

      final pStatusMap = matrixData[p.id] ?? {};

      for (var day = 1; day <= daysInMonth; day++) {
        final status = pStatusMap[day] ?? '-';

        var cellText = '-';
        var styleToUse = cellNormalStyle;

        if (status.contains('GÖREV') ||
            status.contains('NÖBET') ||
            status.contains('HAZIR KITA') ||
            status.contains('GÜLÜŞKÜR') ||
            status.contains('HEYBET')) {
          cellText = 'X';
          styleToUse = cellGorevliStyle;
        } else if (status.contains('İZİN')) {
          cellText = 'İZ';
          styleToUse = cellIzinliStyle;
        } else if (status.contains('İSTİRAHAT')) {
          cellText = 'İST';
          styleToUse = cellIzinliStyle;
        } else if (status.contains('RAPOR')) {
          cellText = 'RAP';
          styleToUse = cellRaporluStyle;
        } else if (status.contains('SEVK')) {
          cellText = 'SVK';
          styleToUse = cellRaporluStyle;
        } else if (status.contains('beklemede')) {
          cellText = 'B';
          styleToUse = cellBekleyenStyle;
        }

        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: day + 1, rowIndex: rowIndex))
          ..value = TextCellValue(cellText)
          ..cellStyle = styleToUse;
      }
    }

    sheet
      ..setColumnWidth(0, 8)
      ..setColumnWidth(1, 28);
    for (var day = 1; day <= daysInMonth; day++) {
      sheet.setColumnWidth(day + 1, 5);
    }

    final encoded = excel.encode();
    return encoded ?? <int>[];
  }

  /// Cleans up old exported XML/XLSX files in temporary directory to prevent cache bloat
  static Future<void> cleanOldExports() async {
    try {
      final dir = await getTemporaryDirectory();
      if (dir.existsSync()) {
        final files = dir.listSync();
        final now = DateTime.now();
        for (final entity in files) {
          if (entity is File &&
              (entity.path.endsWith('.xlsx') || entity.path.endsWith('.xml'))) {
            final stat = entity.statSync();
            if (now.difference(stat.modified).inDays >= 1) {
              await entity.delete();
            }
          }
        }
      }
    } on Exception catch (_) {}
  }

  /// Exports binary .xlsx content to a temporary file and launches native share intent
  static Future<void> exportAndShareXml({
    required List<PersonelTableData> personnel,
    required Map<int, Map<int, String>> matrixData,
    required int year,
    required int month,
  }) async {
    await cleanOldExports();

    final bytes = generateExcelBytes(
      personnel: personnel,
      matrixData: matrixData,
      year: year,
      month: month,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Faaliyet_Matrisi_${year}_$month.xlsx');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Jandarma Görev Takip - Aylık Faaliyet Matrisi Excel Çıktısı',
      ),
    );
  }
}

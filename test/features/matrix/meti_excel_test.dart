import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

void main() {
  test('matrix Excel keeps single-day METİ label instead of dropping the duty',
      () {
    const person = PersonelTableData(
        id: 1,
        adSoyad: 'Sentetik Personel',
        rutbe: 'Er',
        birlik: 'Test',
        kayitTarihi: '2026-01-01',
        aktif: true,
        isDemo: false);
    final bytes = ExcelXmlGenerator.generateExcelBytes(personnel: [
      person
    ], matrixData: {
      1: {
        12: const MatrixDayCell(
            displayCode: 'METİ', entries: [], hasConflict: false)
      }
    }, year: 2026, month: 10);
    final sheet = Excel.decodeBytes(bytes).tables.values.single;
    expect(sheet.rows[1][14]!.value.toString(), 'METİ');
    expect(sheet.rows[1][15]!.value.toString(), '-');
  });
}

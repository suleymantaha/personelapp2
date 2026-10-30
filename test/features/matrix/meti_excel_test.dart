import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/matrix/domain/matrix_day_cell.dart';
import 'package:personelapp2/features/matrix/services/excel_xml_generator.dart';

void main() {
  test('matrix Excel displays single-day METİ assignment as X', () {
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
        12: MatrixDayCell.fromEntries(const [
          MatrixDayEntry(
            activityId: 1,
            activityName: 'Test',
            duty: 'METİ',
            assignmentStatus: 'onaylandi',
            sourceDate: '2026-10-12',
            isContinuationDay: false,
          ),
        ])
      }
    }, year: 2026, month: 10);
    final sheet = Excel.decodeBytes(bytes).tables.values.single;
    expect(sheet.rows[1][14]!.value.toString(), 'X');
    expect(sheet.rows[1][15]!.value.toString(), '-');
  });
}

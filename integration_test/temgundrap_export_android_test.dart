import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_excel_exporter.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_pdf_exporter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android isolates produce PDF and readable Excel repeatedly', (
    tester,
  ) async {
    final document = TemgundrapDocument(
      id: 'synthetic-export',
      date: DateTime(2026, 10, 10),
      unitTitle: 'TEST BİRLİĞİ',
      approverName: '',
      approverRank: '',
      approverDuty: '',
      isDraft: true,
      updatedAt: DateTime(2026, 10, 10),
      operations: List.generate(
        15,
        (index) => TemgundrapOperation(
          id: 'synthetic-$index',
          issuingUnit: 'TEST BİRLİĞİ',
          operationArea: 'TEST ALANI $index',
          commander: const CommanderSnapshot(
            personnelId: 1,
            name: 'Test Personeli',
            rank: 'Test',
            phone: '',
          ),
          strength: const TemgundrapStrength(officer: 1, nco: 2),
          vehicles: const [],
          startAt: DateTime(2026, 10, 10, 8),
          endAt: DateTime(2026, 10, 10, 18),
          purpose: 'TEST',
          description: 'Türkçe çıktı: ğ ü ş ı ö ç',
        ),
      ),
    );
    for (var attempt = 0; attempt < 2; attempt++) {
      final pdf = await TemgundrapPdfExporter.buildBytes(document);
      expect(String.fromCharCodes(pdf.take(4)), '%PDF');
      final bytes = await TemgundrapExcelExporter.buildBytes(document);
      final workbook = Excel.decodeBytes(bytes);
      final sheet = workbook.tables.values.single;
      expect(sheet.maxRows, greaterThanOrEqualTo(18));
      expect(
        sheet.rows.expand((row) => row).any(
              (cell) => cell?.value.toString() == 'TEST ALANI 14',
            ),
        isTrue,
      );
    }
    expect(tester.takeException(), isNull);
  });
}

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_excel_exporter.dart';

void main() {
  test('Excel resmi iki seviyeli TEMGÜNDRAP başlığını ve veriyi üretir', () {
    final document = TemgundrapDocument(
      id: 'excel-1',
      date: DateTime(2026, 8, 6),
      unitTitle: 'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
      approverName: '',
      approverRank: '',
      approverDuty: '',
      operations: [
        TemgundrapOperation(
          id: 'op-1',
          issuingUnit: 'ELAZIĞ İL J.K.LIĞI\nJ.KOMD.ÖZ.K.LIĞI',
          operationArea: 'ELAZIĞ İL J.K.LIĞI',
          commander: const CommanderSnapshot(
            personnelId: 1,
            name: 'S. TAHA BİRİNCİ',
            rank: 'J.UZM.ÇVŞ.',
            phone: '533 158 35 97',
          ),
          strength: const TemgundrapStrength(specialistSergeant: 1),
          vehicles: const [
            TemgundrapVehicleAssignment(model: 'TRANSİT', plate: '23 JAA 240'),
          ],
          startAt: DateTime(2026, 8, 6, 9),
          endAt: DateTime(2026, 8, 6, 10),
          purpose: 'GÖREVLENDİRME',
          description: 'ELLE GİRİLECEK',
        ),
      ],
      isDraft: false,
      updatedAt: DateTime(2026, 8, 6),
    );
    final workbook = Excel.decodeBytes(TemgundrapExcelExporter.build(document));
    final sheet = workbook['TEMGÜNDRAP'];
    String value(String address) =>
        sheet.cell(CellIndex.indexByString(address)).value?.toString() ?? '';
    expect(value('A1'), document.unitTitle);
    expect(value('D2'), 'OPERASYON KUVVETİ');
    expect(value('E3'), 'OPERASYON KOMUTANI');
    expect(value('D4'), contains('(1) TRANSİT'));
    expect(value('K4'), 'ELLE GİRİLECEK');
  });
}

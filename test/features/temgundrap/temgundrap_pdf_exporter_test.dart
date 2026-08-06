import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/temgundrap/domain/temgundrap_models.dart';
import 'package:personelapp2/features/temgundrap/services/temgundrap_pdf_exporter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A4 yatay TEMGÜNDRAP PDF belgesi üretir', () async {
    final document = TemgundrapDocument(
      id: '1',
      date: DateTime(2026, 8, 7),
      unitTitle: 'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
      approverName: '',
      approverRank: '',
      approverDuty: '',
      isDraft: true,
      updatedAt: DateTime(2026),
      operations: [
        TemgundrapOperation(
          id: 'op',
          issuingUnit: 'ELAZIĞ İL J.K.LIĞI',
          operationArea: 'PALU İLÇE J.K.LIĞI',
          commander: const CommanderSnapshot(
            personnelId: 1,
            name: 'Mehmet CEYLAN',
            rank: 'J.Ütğm.',
            phone: '545 864 19 02',
          ),
          strength: const TemgundrapStrength(officer: 1),
          vehicles: const [],
          startAt: DateTime(2026, 8, 6, 9),
          endAt: DateTime(2026, 8, 6, 10),
          purpose: 'GÖREVLENDİRME',
          description: '',
        ),
      ],
    );
    final bytes = await (await TemgundrapPdfExporter.build(document)).save();
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

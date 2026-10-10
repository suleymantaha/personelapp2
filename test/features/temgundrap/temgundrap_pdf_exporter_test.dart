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

  test('PDF başlığını birlik ve Türkçe tarih ile oluşturur', () {
    final document = TemgundrapDocument(
      id: 'title',
      date: DateTime(2026, 8, 6),
      unitTitle: 'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
      approverName: '',
      approverRank: '',
      approverDuty: '',
      operations: const [],
      isDraft: true,
      updatedAt: DateTime(2026, 8, 6),
    );
    expect(
      TemgundrapPdfExporter.documentTitle(document),
      'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI 06 AĞUSTOS 2026 TARİHİNDE '
      'PLANLANAN OPERASYON TAKİP ÇİZELGESİ',
    );
  });

  test('onaylayan bilgisi verilince imza bloğu ile PDF üretir', () async {
    final document = TemgundrapDocument(
      id: '2',
      date: DateTime(2026, 8, 8),
      unitTitle: 'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
      approverName: 'İhsan DAĞLI',
      approverRank: 'J.Ütğm.',
      approverDuty: 'Tb. K. V.',
      isDraft: false,
      updatedAt: DateTime(2026, 8, 8),
      operations: const [],
    );
    final bytes = await (await TemgundrapPdfExporter.build(document)).save();
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('Çok sayıda operasyon (sayfayı aşan) olduğunda PDF hatasız ve kararlı üretilir', () async {
    final ops = List.generate(
      15,
      (i) => TemgundrapOperation(
        id: 'op-$i',
        issuingUnit: 'ELAZIĞ İL J.K.LIĞI\nJ.KOMD.ÖZ.K.LIĞI',
        operationArea: 'PALU VE KOVANCILAR İLÇE J.K.LIĞI SORUMLULUK ALANI',
        commander: CommanderSnapshot(
          personnelId: i + 1,
          name: 'Personel $i',
          rank: 'J.Uzm.Çvş.',
          phone: '0533 000 00 $i',
        ),
        strength: const TemgundrapStrength(officer: 1, nco: 2, specialistSergeant: 4),
        vehicles: const [
          TemgundrapVehicleAssignment(model: 'KİRPİ', plate: '23 JAA 101'),
        ],
        startAt: DateTime(2026, 8, 8, 8),
        endAt: DateTime(2026, 8, 8, 18),
        purpose: 'ÖNLEYİCİ KOLLUK HİZMETİ VE EMNİYET ASAYİŞ DEVRİYESİ',
        description: 'Bölge emniyeti sağlandı. Herhangi bir olumsuzluk yaşanmadı.',
      ),
    );

    final document = TemgundrapDocument(
      id: 'multi-ops',
      date: DateTime(2026, 8, 8),
      unitTitle: 'KOVANCILAR J.KOMD.ÖZ.HRK.TB.K.LIĞI',
      approverName: 'İhsan DAĞLI',
      approverRank: 'J.Ütğm.',
      approverDuty: 'Tb. K. V.',
      isDraft: false,
      updatedAt: DateTime(2026, 8, 8),
      operations: ops,
    );

    final bytes = await (await TemgundrapPdfExporter.build(document)).save();
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

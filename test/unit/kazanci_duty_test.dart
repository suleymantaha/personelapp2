import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/utils/military_structure_helper.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/duty_coverage.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';
import 'package:personelapp2/features/activity/domain/ocr/roster_ocr_name_extractor.dart';

void main() {
  test('Kazancı görev hücresi isme eklenmez ve genel nöbet başlığını aşar', () {
    final ocr = RosterOcrNameExtractor.extract(
        "03.11.2026 NÖBETÇİ İSİM ÇİZELGESİ\n1 J.Uzm.Çvş. Deneme PERSONELİ KAZANCI");
    expect(ocr.names.single.rawName, 'Deneme PERSONELİ');
    expect(ocr.names.single.activityHint, 'KAZANCI');
    expect(
        BulkTextParser.parse(ocr.toBulkImportText())
            .blocks
            .single
            .parsedActivityType,
        'KAZANCI');
  });

  test('Ayrı Kazancı Görevi başlığı personel olarak eklenmez', () {
    final ocr = RosterOcrNameExtractor.extract(
        "03.11.2026\nKAZANCI GÖREVİ\n1 J.Uzm.Çvş. Deneme PERSONELİ");
    expect(ocr.names.map((n) => n.rawName), ['Deneme PERSONELİ']);
    expect(
        BulkTextParser.parse(ocr.toBulkImportText())
            .blocks
            .single
            .parsedActivityType,
        'KAZANCI');
  });

  test('Kazancı soyadı ve mevcut görev ipucu korunur', () {
    final ocr = RosterOcrNameExtractor.extract(
        "03.11.2026 METİ İSİM ÇİZELGESİ\n1 J.Uzm.Çvş. Deneme KAZANCI");
    expect(ocr.names.single.rawName, 'Deneme KAZANCI');
    expect(ocr.names.single.activityHint, isNull);
    expect(
        BulkTextParser.parse(ocr.toBulkImportText())
            .blocks
            .single
            .parsedActivityType,
        'METİ');
  });

  test('Kazancı görsel metninden aktarımda görev adını korur', () {
    final ocr = RosterOcrNameExtractor.extract(
        "03.11.2026 KAZANCI GÖREVİ İSİM ÇİZELGESİ\n1 J.Uzm.Çvş. Deneme PERSONELİ");
    final result = BulkTextParser.parse(ocr.toBulkImportText());
    expect(result.blocks.single.parsedActivityType, 'KAZANCI');
    expect(
        result.blocks.single.personnelList.single.rawName, 'Deneme PERSONELİ');
  });

  test('Kazancı başlangıç ve ertesi günü kapsar, üçüncü güne taşmaz', () {
    for (final duty in ['KAZANCI', 'Kazancı', ' kazancı ']) {
      expect(DutyCoverage.coveredDates(startDate: '2026-11-03', duty: duty),
          ['2026-11-03', '2026-11-04']);
    }
    expect(DutyCoverage.coveredDates(startDate: '2026-12-31', duty: 'KAZANCI'),
        ['2026-12-31', '2027-01-01']);
  });

  test('Kazancı ikinci günü başka görevle çakışır ve üçüncü günü serbesttir',
      () {
    const existing = [
      ExistingDutyAssignment(
          id: 1,
          faaliyetId: 1,
          personelId: 7,
          tarih: '2026-11-03',
          gorevVeyaIzin: 'KAZANCI',
          durum: AssignmentStatus.onaylandi),
    ];
    expect(
        ConflictChecker.evaluateAssignmentStatus(
            personelId: 7,
            targetDate: '2026-11-04',
            targetDuty: 'METİ',
            reports: [],
            existingAssignments: existing),
        AssignmentStatus.beklemede);
    expect(
        ConflictChecker.evaluateAssignmentStatus(
            personelId: 7,
            targetDate: '2026-11-05',
            targetDuty: 'METİ',
            reports: [],
            existingAssignments: existing),
        AssignmentStatus.onaylandi);
  });

  test('Kazancı atanırken ertesi günün raporu da değerlendirilir', () {
    expect(
        ConflictChecker.evaluateAssignmentStatus(
            personelId: 7,
            targetDate: '2026-11-03',
            targetDuty: 'KAZANCI',
            reports: const [
              PersonnelReport(
                  id: 1,
                  personelId: 7,
                  raporBaslangic: '2026-11-04',
                  raporBitis: '2026-11-04'),
            ],
            existingAssignments: []),
        AssignmentStatus.beklemede);
  });

  test('Kazancı nöbet heyeti çıktısında görev adıyla gruplanır', () {
    expect(
        MilitaryStructureHelper.getRosterGroupCode('KAZANCI'), 'NOBET_HEYETI');
    expect(
        MilitaryStructureHelper.getRosterBirlikName(
            timName: '1-B Timi', birlik: 'KH', duty: 'KAZANCI'),
        'Nöbet Heyeti');
    expect(MilitaryStructureHelper.getDigerCellText('KAZANCI'), 'KAZANCI');
    expect(MilitaryStructureHelper.getDutyCategoryOrder('KAZANCI'), 10);
  });

  test('Kazancı görevi başlığı aktarımda genel görev türüne dönüşmez', () {
    final result = BulkTextParser.parse('''
03.11.2026 KAZANCI GÖREVİ İSİM LİSTESİ
1- J.Uzm.Çvş. Deneme PERSONELİ
''');
    expect(result.blocks, hasLength(1));
    expect(result.blocks.single.parsedActivityType, 'KAZANCI');
    expect(
        BulkTextParser.mapActivityTypeToDutyOrLeave(
            result.blocks.single.parsedActivityType),
        'KAZANCI');
    expect(
        result.blocks.single.personnelList.single.rawName, 'Deneme PERSONELİ');
  });
}

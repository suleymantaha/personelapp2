import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/ocr/roster_ocr_name_extractor.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  test('METİ column cells do not become the last personnel surname', () {
    const raw = '''
04.11.2026 TARİHLİ METİ GÖREVİ İSİM ÇİZELGESİ
İSİM ÇİZELGESİ
J.İs.Asb. Üçvş.
Ali DENEME
Veli ÖRNEK
METİ
METİ
''';
    final result = RosterOcrNameExtractor.extract(raw);

    expect(
        result.names.map((item) => item.rawName), ['Ali DENEME', 'Veli ÖRNEK']);
    expect(result.defaultDate, '2026-11-04');
    expect(result.titleActivity, 'METİ');
    final parsed = BulkTextParser.parse(result.toBulkImportText());
    expect(parsed.blocks.single.parsedActivityType, DutyOrLeaveType.meti);
    expect(parsed.blocks.single.personnelList.map((item) => item.rawName),
        ['Ali DENEME', 'Veli ÖRNEK']);
  });

  test('recognizes the photographed military branch without inventing names',
      () {
    const raw = '''
1. J.İs.Asb.Üçvş. Ali DENEME
2. J.İs.Asb. Üçvş.
3. J.Uzm.Çvş. Veli ÖRNEK METİ METİ
''';
    final result = RosterOcrNameExtractor.extract(raw);

    expect(
        result.names.map((item) => item.rawName), ['Ali DENEME', 'Veli ÖRNEK']);
    expect(result.names.first.rawRank, 'J.Asb.Üçvş.');
    expect(result.names.last.activityHint, 'METİ');
  });

  test('keeps split surnames while discarding standalone activity cells', () {
    const raw = '''
1. J.Uzm.Çvş. Ali İhsan
DENEME
METİ
2. J.Uzm.Çvş. Veli ÖRNEK
METİ
''';
    final result = RosterOcrNameExtractor.extract(raw);

    expect(result.names.map((item) => item.rawName),
        ['Ali İhsan DENEME', 'Veli ÖRNEK']);
  });

  test('removes row METİ cells without losing a numbered rankless person', () {
    const raw = '''
04.11.2026 METİ Görevi İsim Listesi
1. Ali DENEME
2. Veli ÖRNEK METİ METİ
''';
    final parsed = BulkTextParser.parse(raw);

    expect(parsed.blocks, hasLength(1));
    expect(parsed.blocks.single.parsedActivityType, DutyOrLeaveType.meti);
    expect(parsed.blocks.single.personnelList.map((item) => item.rawName),
        ['Ali DENEME', 'Veli ÖRNEK']);
  });

  test('an explicit operational duty takes precedence over the METİ team', () {
    const raw = '''
04.11.2026 METİ Timi Gülüşkür İsim Listesi
1. Ali DENEME
''';
    final parsed = BulkTextParser.parse(raw);

    expect(parsed.blocks.single.parsedTimName, 'METİ');
    expect(parsed.blocks.single.parsedActivityType, DutyOrLeaveType.guluskur);
    expect(parsed.blocks.single.personnelList.single.rawName, 'Ali DENEME');
  });

  test('does not remove a matching token inside an original personnel name',
      () {
    final result = RosterOcrNameExtractor.extract('1. Ali Meti DENEME');

    expect(result.names.single.rawName, 'Ali Meti DENEME');
    final parsed = BulkTextParser.parse('''
04.11.2026 GÖREVLİ İsim Listesi
1. Ali Meti DENEME
''');
    expect(
        parsed.blocks.single.personnelList.single.rawName, 'Ali Meti DENEME');
  });

  test('does not reduce a two-word personnel name to a single word', () {
    final result = RosterOcrNameExtractor.extract('1. Ali METİ');

    expect(result.names.single.rawName, 'Ali METİ');
  });

  test('keeps a numbered METİ operational heading as a heading', () {
    final parsed = BulkTextParser.parse('''
04.11.2026
1. METİ Gülüşkür
1. Ali DENEME
''');

    expect(parsed.blocks.single.parsedActivityType, DutyOrLeaveType.guluskur);
    expect(parsed.blocks.single.personnelList.single.rawName, 'Ali DENEME');
  });

  for (final duty in ['GARAJ NÖB.', 'TTZA NÖB.', 'MEBS NÖB.', 'KULE NÖB.']) {
    test('METİ table cell does not override explicit $duty row duty', () {
      final result = RosterOcrNameExtractor.extract('''
04.11.2026 İsim Listesi
1. J.Uzm.Çvş. Ali DENEME $duty METİ
''');
      expect(result.names.single.activityHint, duty);
      expect(result.names.single.rawName, 'Ali DENEME');
      expect(result.toBulkImportText().split('\n').first, contains(duty));
    });
  }

  test('a personal Meti name never assigns the whole roster to METİ', () {
    final result = RosterOcrNameExtractor.extract('''
04.11.2026 İsim Listesi
1. J.Uzm.Çvş. Ali Meti DENEME
2. J.Uzm.Çvş. Veli ÖRNEK
''');
    expect(result.titleActivity, isNull);
    expect(result.toBulkImportText().split('\n').first,
        '04.11.2026 GÖREVLİ İsim Listesi');
  });

  test('a two-word name ending in Meti is not a duty cell', () {
    final result = RosterOcrNameExtractor.extract('''
04.11.2026 İsim Listesi
1. J.Uzm.Çvş. Ali METİ
''');
    expect(result.names.single.rawName, 'Ali METİ');
    expect(result.names.single.activityHint, isNull);
    expect(result.toBulkImportText().split('\n').first,
        '04.11.2026 GÖREVLİ İsim Listesi');
  });
}

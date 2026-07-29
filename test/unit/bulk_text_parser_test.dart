import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/parser/bulk_text_parser.dart';

void main() {
  group('BulkTextParser', () {
    test('parses dated headers and multiple shifts without leaking state', () {
      const rawText = '''
6 / B Gülüşkür isim listesi
25.07.2026 Cumartesi
08.00-19.30
1-J.Asb.üçvş. Erdem BUYAR
2-J.Uzm.Çvş. Erol SARI
3-J.Uzm.Çvş. Abalı Abdullah VURUR
4-J.Uzm.Çvş. Durmuş ÖZKAN
19.30-09.00
1-J.Asb.Kd.Üçvş. Ömer Ali DARILMAZ
2-J.Uzm.Çvş. Furkan DÜNDAR
3-J.Uzm.Çvş. Mehmet YILDIRIM
4-J.Uzm.Çvş. Mehmet Ali ÇAVDAR
7-B Hazır Kıta Listesi
25.07.2026 Cumartesi
1- J.Asb.Üçvş. Ferdi ERDOĞAN
2- J.Uzm.Çvş. Kudret SARIOĞLU
3- J.Uzm.Çvş. Emin SOLUKEL
4- J.Uzm.Çvş. Orhan YENTÜRK
5- J.Uzm.Çvş. Vahit KARACA
6- J.Uzm.Çvş. Sefa YÜCEL
7- J.Uzm.Çvş. Mesut KOÇ
8- J.Uzm.Çvş. Soner SAMUR
9- J.Uzm.Çvş. Seit Abdulveli TÜRKOĞLU
3B- 26.07.2026 *Gülüşkür* İsim Listesi
08:00/20:00
1-J.Asb.Üçvş. Gökhan GÖKMEN
2-J.Uzm.Çvş. Murat Dursun HÜNERCİ
3-J.Uzm.Çvş. Nevzat GÜL
4-J.Uzm.Çvş. Onur ÇELİK
5-J.Uzm.Çvş. Ömer SAVAŞ
''';

      final result = BulkTextParser.parse(rawText);
      final blocks = result.blocks;

      expect(result.hasBlockingIssues, isFalse);
      expect(blocks, hasLength(3));
      expect(blocks[0].parsedTimName, '6/B');
      expect(blocks[0].parsedActivityType, DutyOrLeaveType.guluskur);
      expect(blocks[0].parsedDate, '2026-07-25');
      expect(blocks[0].parsedTimeRange, isNull);
      expect(blocks[0].personnelList, hasLength(8));
      expect(blocks[0].personnelList.first.rawName, 'Erdem BUYAR');
      expect(blocks[0].personnelList.first.rawRank, 'J.Asb.Üçvş.');

      expect(blocks[1].parsedTimName, '7/B');
      expect(blocks[1].parsedActivityType, DutyOrLeaveType.hazirKita);
      expect(blocks[1].personnelList, hasLength(9));

      expect(blocks[2].parsedTimName, '3B');
      expect(blocks[2].parsedActivityType, DutyOrLeaveType.guluskur);
      expect(blocks[2].parsedDate, '2026-07-26');
      expect(blocks[2].parsedTimeRange, isNull);
      expect(blocks[2].personnelList, hasLength(5));
      expect(result.ignoredLineCount, 3);
    });

    test('normalizes common message, team, time and list variants', () {
      const rawText = '''
[10:20, 25/07/2026] Ahmet: gönderildi
> 6 - B HAZIR KITA listesi
25/07/2026 Cumartesi
8.00—19.30
• J. Asb. Kd. Üçvş. Ali ÖZTÜRK
2) J Uzm Cvs Veli ÇELİK
''';

      final result = BulkTextParser.parse(rawText);

      expect(result.hasBlockingIssues, isFalse);
      expect(result.blocks, hasLength(1));
      expect(result.blocks.single.parsedTimName, '6/B');
      expect(result.blocks.single.parsedDate, '2026-07-25');
      expect(result.blocks.single.parsedTimeRange, isNull);
      expect(result.blocks.single.personnelList, hasLength(2));
      expect(
        result.blocks.single.personnelList.first.rawRank,
        'J.Asb.Kd.Üçvş.',
      );
    });

    test('date change closes the previous personnel block', () {
      const rawText = '''
6/B Heybet Listesi
25.07.2026
1- J.Uzm.Çvş. Ali BİR
26.07.2026
1- J.Uzm.Çvş. Veli İKİ
''';

      final result = BulkTextParser.parse(rawText);

      expect(result.blocks, hasLength(2));
      expect(result.blocks[0].parsedDate, '2026-07-25');
      expect(result.blocks[0].personnelList.single.rawName, 'Ali BİR');
      expect(result.blocks[1].parsedDate, '2026-07-26');
      expect(result.blocks[1].personnelList.single.rawName, 'Veli İKİ');
    });

    test('reports invalid date and time as blocking issues', () {
      const rawText = '''
6/B Heybet Listesi
31.02.2026
25:00-08:00
1- J.Uzm.Çvş. Ali BİR
''';

      final result = BulkTextParser.parse(rawText);

      expect(result.hasBlockingIssues, isTrue);
      expect(
        result.issues.map((issue) => issue.code),
        containsAll(<String>['invalid_date', 'invalid_time', 'missing_date']),
      );
    });

    test('does not invent missing date, team, activity or rank', () {
      const rawText = '''
Bilinmeyen Liste
1- Ali VELİ
''';

      final result = BulkTextParser.parse(rawText);

      expect(result.hasBlockingIssues, isTrue);
      expect(result.blocks.single.parsedDate, isEmpty);
      expect(result.blocks.single.parsedTimName, isEmpty);
      expect(result.blocks.single.parsedActivityType, 'Bilinmeyen');
      expect(result.blocks.single.personnelList.single.rawRank, isEmpty);
      expect(
        result.issues.map((issue) => issue.code),
        containsAll(<String>[
          'missing_date',
          'unknown_team',
          'unknown_activity',
          'unknown_rank',
        ]),
      );
    });

    test('returns an explanatory error for empty and unrelated input', () {
      expect(
        BulkTextParser.parse('   ').issues.single.code,
        'empty_input',
      );
      expect(
        BulkTextParser.parse('Merhaba, toplantı yarın.').issues.single.code,
        'no_blocks',
      );
    });

    test('uses an explicit valid default date only', () {
      const rawText = '''
6/B Devriye Listesi
1- J.Uzm.Çvş. Ali BİR
''';

      final valid = BulkTextParser.parse(
        rawText,
        defaultDate: '2026-07-25',
      );
      final invalid = BulkTextParser.parse(
        rawText,
        defaultDate: '2026-02-31',
      );

      expect(valid.hasBlockingIssues, isFalse);
      expect(valid.blocks.single.parsedDate, '2026-07-25');
      expect(invalid.hasBlockingIssues, isTrue);
      expect(invalid.blocks.single.parsedDate, isEmpty);
    });
  });
}

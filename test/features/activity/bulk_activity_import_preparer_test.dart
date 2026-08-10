import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/bulk_activity_import_preparer.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

void main() {
  ParsedPersonnelItem person(int id, String name, {int? teamId}) {
    return ParsedPersonnelItem(
      rawIndex: id,
      rawRank: 'J.Utgm.',
      rawName: name,
      matchedPersonnelId: id,
      matchedAdSoyad: name,
      matchedTimId: teamId,
    );
  }

  ParsedActivityBlock block({
    required String date,
    required String duty,
    required ParsedPersonnelItem person,
    String? time,
  }) {
    return ParsedActivityBlock(
      rawTitle: duty,
      parsedTimName: '7-B',
      parsedActivityType: duty,
      parsedDate: date,
      parsedTimeRange: time,
      personnelList: [person],
    );
  }

  test('creates one activity card per duty for the same day', () {
    final result = BulkActivityImportPreparer.prepare([
      block(
        date: '2026-07-28',
        duty: 'HAZIR KITA',
        time: '08:00 - 19:30',
        person: person(1, 'Ali', teamId: 7),
      ),
      block(
        date: '2026-07-28',
        duty: 'GULUSKUR',
        time: '19:30 - 09:00',
        person: person(2, 'Veli', teamId: 8),
      ),
    ]);

    expect(result.duplicates, isEmpty);
    expect(result.requests, hasLength(2));
    expect(result.requests.map((request) => request.faaliyetAdi), [
      'HAZIR KITA',
      'GULUSKUR',
    ]);
    expect(result.requests.map((request) => request.tarih).toSet(), {
      '2026-07-28',
    });
    expect(result.requests.first.personnelAssignments, hasLength(1));
    expect(result.requests.first.personnelAssignments.first.duty, 'HAZIR KITA');
    expect(
      result.requests.first.personnelAssignments.first.note,
      'Görev Türü: HAZIR KITA',
    );
  });

  test('creates one activity card per date and duty', () {
    final result = BulkActivityImportPreparer.prepare([
      block(date: '2026-07-28', duty: 'GOREVLI', person: person(1, 'Ali')),
      block(date: '2026-07-29', duty: 'GOREVLI', person: person(2, 'Veli')),
    ]);

    expect(result.requests.map((request) => request.tarih), [
      '2026-07-28',
      '2026-07-29',
    ]);
    expect(result.requests.map((request) => request.faaliyetAdi), [
      'GOREVLI',
      'GOREVLI',
    ]);
  });

  test('blocks duplicate personnel on the same date with both assignments', () {
    final result = BulkActivityImportPreparer.prepare([
      block(
        date: '2026-07-28',
        duty: 'HAZIR KITA',
        time: '08:00 - 19:30',
        person: person(1, 'Ali', teamId: 7),
      ),
      block(
        date: '2026-07-28',
        duty: 'GULUSKUR',
        time: '19:30 - 09:00',
        person: person(1, 'Ali', teamId: 7),
      ),
    ]);

    expect(result.canSave, isFalse);
    expect(result.duplicates, hasLength(1));
    expect(result.duplicates.single.personnelName, 'Ali');
    expect(result.duplicates.single.assignments, [
      'HAZIR KITA (08:00 - 19:30)',
      'GULUSKUR (19:30 - 09:00)',
    ]);
  });

  test('collapses repeated personnel in the same duty and discards shifts', () {
    final repeated = person(1, 'Ahmet TINAS', teamId: 9);
    final result = BulkActivityImportPreparer.prepare([
      block(
        date: '2026-07-30',
        duty: 'GULUSKUR',
        time: '08:00 - 19:30',
        person: repeated,
      ),
      block(
        date: '2026-07-30',
        duty: 'GULUSKUR',
        time: '19:30 - 06:30',
        person: repeated,
      ),
    ]);

    expect(result.duplicates, isEmpty);
    expect(result.requests, hasLength(1));
    expect(result.requests.single.faaliyetAdi, 'GULUSKUR');
    expect(result.requests.single.personnelAssignments, hasLength(1));
    expect(
      result.requests.single.personnelAssignments.single.note,
      'Görev Türü: GULUSKUR',
    );
  });

  test('draft builds cards from raw text before preparing save requests',
      () async {
    final repeated = person(1, 'Ahmet TINAS', teamId: 9);
    var matcherReceivedParsedBlocks = false;

    final draft = await BulkActivityImportDraft.fromRawText(
      '''
2026-07-30
9/B Guluskur
1) J.Asb.Cvs. Ahmet TINAS
''',
      matchBlocks: (blocks) async {
        matcherReceivedParsedBlocks = blocks.isNotEmpty;
        return [
          block(
            date: '2026-07-30',
            duty: 'GULUSKUR',
            time: '08:00 - 19:30',
            person: repeated,
          ),
          block(
            date: '2026-07-30',
            duty: 'GULUSKUR',
            time: '19:30 - 06:30',
            person: repeated,
          ),
        ];
      },
    );

    expect(matcherReceivedParsedBlocks, isTrue);
    expect(draft.blocks, hasLength(1));
    expect(draft.deduplicatedPersonnelCount, 1);
    expect(draft.blocks.first.personnelList, hasLength(1));

    final preparation = draft.toPreparation();
    expect(preparation.duplicates, isEmpty);
    expect(preparation.requests, hasLength(1));
    expect(preparation.requests.single.personnelAssignments, hasLength(1));
  });
}

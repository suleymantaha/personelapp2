import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/features/activity/domain/bulk_activity_import_preparer.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

void main() {
  ParsedPersonnelItem person(int id, String name, {int? teamId}) {
    return ParsedPersonnelItem(
      rawIndex: id,
      rawRank: 'J.Ütğm.',
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

  test('creates one daily activity while preserving duty and shift notes', () {
    final result = BulkActivityImportPreparer.prepare([
      block(
        date: '2026-07-28',
        duty: 'HAZIR KITA',
        time: '08:00 - 19:30',
        person: person(1, 'Ali', teamId: 7),
      ),
      block(
        date: '2026-07-28',
        duty: 'GÜLÜŞKÜR',
        time: '19:30 - 09:00',
        person: person(2, 'Veli', teamId: 8),
      ),
    ]);

    expect(result.duplicates, isEmpty);
    expect(result.requests, hasLength(1));
    final request = result.requests.single;
    expect(request.faaliyetAdi, 'Günlük Tüm Faaliyetler');
    expect(request.tarih, '2026-07-28');
    expect(request.personnelAssignments, hasLength(2));
    expect(
      request.personnelAssignments.first,
      containsPair('gorevVeyaIzin', 'HAZIR KITA'),
    );
    expect(
      request.personnelAssignments.first['aciklama'],
      contains('08:00 - 19:30'),
    );
  });

  test('creates one activity per date', () {
    final result = BulkActivityImportPreparer.prepare([
      block(
        date: '2026-07-28',
        duty: 'GÖREVLİ',
        person: person(1, 'Ali'),
      ),
      block(
        date: '2026-07-29',
        duty: 'GÖREVLİ',
        person: person(2, 'Veli'),
      ),
    ]);

    expect(result.requests.map((request) => request.tarih), [
      '2026-07-28',
      '2026-07-29',
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
        duty: 'GÜLÜŞKÜR',
        time: '19:30 - 09:00',
        person: person(1, 'Ali', teamId: 7),
      ),
    ]);

    expect(result.canSave, isFalse);
    expect(result.duplicates, hasLength(1));
    expect(result.duplicates.single.personnelName, 'Ali');
    expect(result.duplicates.single.assignments, [
      'HAZIR KITA (08:00 - 19:30)',
      'GÜLÜŞKÜR (19:30 - 09:00)',
    ]);
  });
}

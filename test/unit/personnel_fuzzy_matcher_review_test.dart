import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final teamId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '6-B Timi',
            olusturmaTarihi: '2026-01-01',
          ),
        );
    await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ahmet TINAS',
            rutbe: 'J.Asb.Çvş.',
            birlik: '6/B',
            timId: Value(teamId),
            kayitTarihi: '2026-01-01',
          ),
        );
  });

  tearDown(() => database.close());

  ParsedActivityBlock block(String team, String name) => ParsedActivityBlock(
        rawTitle: '$team Gülüşkür',
        parsedTimName: team,
        parsedActivityType: 'GÜLÜŞKÜR',
        parsedDate: '2026-07-30',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'J.Asb.Çvş.',
            rawName: name,
          ),
        ],
      );

  test('exact match is automatic when roster and stored teams agree', () async {
    final result = await PersonnelFuzzyMatcher(database)
        .matchBlocks([block('6/B', 'Ahmet TINAS')]);
    final person = result.single.personnelList.single;

    expect(person.isMatched, isTrue);
    expect(person.matchConfidence, 1);
    expect(person.teamMismatch, isFalse);
    expect(person.needsReview, isFalse);
  });

  test('team mismatch requires explicit review even for an exact name',
      () async {
    final result = await PersonnelFuzzyMatcher(database)
        .matchBlocks([block('9/B', 'Ahmet TINAS')]);
    final person = result.single.personnelList.single;

    expect(person.isMatched, isTrue);
    expect(person.teamMismatch, isTrue);
    expect(person.needsReview, isTrue);
    expect(person.copyWith(reviewConfirmed: true).needsReview, isFalse);
  });
}

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

  test(
      'team mismatch keeps match intact with teamMismatch flag but allows auto save',
      () async {
    final result = await PersonnelFuzzyMatcher(database)
        .matchBlocks([block('9/B', 'Ahmet TINAS')]);
    final person = result.single.personnelList.single;

    expect(person.isMatched, isTrue);
    expect(person.teamMismatch, isTrue);
    expect(person.needsReview, isFalse);
    expect(person.copyWith(reviewConfirmed: true).needsReview, isFalse);
  });

  test('unrelated two-word OCR text is not suggested as personnel', () async {
    await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Erdal AKBAL',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '6/B',
            kayitTarihi: '2026-01-01',
          ),
        );

    final result = await PersonnelFuzzyMatcher(database)
        .matchBlocks([block('6/B', 'Arial Black')]);
    final person = result.single.personnelList.single;

    expect(person.isMatched, isFalse);
    expect(person.matchConfidence, 0);
  });

  test('minor typo uses the actual fuzzy confidence', () async {
    final result = await PersonnelFuzzyMatcher(database)
        .matchBlocks([block('6/B', 'Ahmet TINAZ')]);
    final person = result.single.personnelList.single;

    expect(person.isMatched, isTrue);
    expect(person.matchedAdSoyad, 'Ahmet TINAS');
    expect(person.matchConfidence, greaterThan(0.85));
    expect(person.matchConfidence, lessThan(1));
  });
}

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/personnel/data/personnel_repository.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

void main() {
  late AppDatabase db;
  late PersonnelRepository repo;
  setUp(() { db = AppDatabase(NativeDatabase.memory()); repo = PersonnelRepository(db); });
  tearDown(() => db.close());
  Future<int> team(String name) => repo.addSquad(timAdi: name, olusturmaTarihi: '2026-01-01');
  Future<int> person(int squad) => repo.addPersonnel(adSoyad: 'Ali KAYA', rutbe: 'J.Er', birlik: 'Asayiş', timId: squad, kayitTarihi: '2026-01-01');
  ParsedActivityBlock block(String squad) => ParsedActivityBlock(rawTitle: squad, parsedTimName: squad, parsedActivityType: 'HEYBET', parsedDate: '2026-10-02', personnelList: [ParsedPersonnelItem(rawIndex: 1, rawRank: 'J.Er', rawName: 'A. KAYA')]);

  test('rank change requires an explicit existing-person decision', () async {
    final squad = await team('1-B');
    final id = await person(squad);
    await expectLater(repo.importPersonnelBatch([PersonnelImportEntry(adSoyad: 'Ali KAYA', rutbe: 'J.Onb.', birlik: 'Asayiş', timId: squad)], kayitTarihi: '2026-10-02'), throwsArgumentError);
    expect((await db.select(db.personelTable).get()).single.id, id);
  });
  test('legacy global alias cannot silently select among namesakes', () async {
    final squad = await team('1-B');
    final first = await person(squad);
    await person(squad);
    await BulkImportLearningService(db).rememberAlias(rawName: 'A. KAYA', personnelId: first);
    final matched = await PersonnelFuzzyMatcher(db).matchBlocks([block('1-B')]);
    expect(matched.single.personnelList.single.isMatched, isFalse);
  });
  test('legacy alias from another team is not automatically confirmed', () async {
    final first = await person(await team('1-B'));
    final second = await person(await team('2-B'));
    await BulkImportLearningService(db).rememberAlias(rawName: 'A. KAYA', personnelId: first);
    final matched = await PersonnelFuzzyMatcher(db).matchBlocks([block('2-B')]);
    expect(matched.single.personnelList.single.matchedPersonnelId, isNot(first));
    expect(matched.single.personnelList.single.matchedPersonnelId, anyOf(second, null));
  });
}

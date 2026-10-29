import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_activity_import_preparer.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';

void main() {
  test(
      'current membership inferred for display is never explicit task-team evidence',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final team = await db.into(db.timTable).insert(TimTableCompanion.insert(
        timAdi: '1-B Timi', olusturmaTarihi: '2000-01-01'));
    await db.into(db.personelTable).insert(PersonelTableCompanion.insert(
        adSoyad: 'Ali TEST',
        rutbe: 'J.Er',
        birlik: 'Test',
        kayitTarihi: '2000-01-01',
        timId: Value(team)));
    ParsedActivityBlock block(String heading) => ParsedActivityBlock(
            rawTitle: 'HEYBET',
            parsedTimName: heading,
            parsedActivityType: 'HEYBET',
            parsedDate: '2001-01-02',
            personnelList: [
              ParsedPersonnelItem(
                  rawIndex: 1, rawRank: 'J.Er', rawName: 'Ali TEST')
            ]);
    final inferred =
        (await PersonnelFuzzyMatcher(db).matchBlocks([block('')])).single;
    expect(inferred.personnelList.single.matchedTimId, team);
    expect(inferred.taskTeamId, isNull);
    expect(
        BulkActivityImportPreparer.prepare([inferred])
            .requests
            .single
            .personnelAssignments
            .single
            .teamId,
        isNull);
    final explicit =
        (await PersonnelFuzzyMatcher(db).matchBlocks([block('1-B Timi')]))
            .single;
    expect(explicit.taskTeamId, team);
  });
}

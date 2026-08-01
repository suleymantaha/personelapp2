import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';

void main() {
  late AppDatabase database;
  late int personnelId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final teamId = await database.into(database.timTable).insert(
          TimTableCompanion.insert(
            timAdi: '9-B Timi',
            olusturmaTarihi: '2026-01-01',
          ),
        );
    personnelId = await database.into(database.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Hüseyin ORUÇTUTAN',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '9/B',
            timId: Value(teamId),
            kayitTarihi: '2026-01-01',
          ),
        );
  });

  tearDown(() => database.close());

  test('Batch save automatically remembers aliases for matched personnel', () async {
    final block = ParsedActivityBlock(
      rawTitle: '9/B Gülüşkür',
      parsedTimName: '9/B',
      parsedActivityType: 'GÜLÜŞKÜR',
      parsedDate: '2026-07-30',
      personnelList: [
        ParsedPersonnelItem(
          rawIndex: 1,
          rawRank: 'J.Uzm.Çvş.',
          rawName: 'Hüseyin ORUCTUTAN',
          matchedPersonnelId: personnelId,
          matchedAdSoyad: 'Hüseyin ORUÇTUTAN',
          matchedRutbe: 'J.Uzm.Çvş.',
          matchConfidence: 0.75,
        ),
      ],
    );

    final learningService = BulkImportLearningService(database);

    // Simulate batch saving behavior
    final aliasPairs = [block].expand((b) => b.personnelList).where(
      (p) => p.matchedPersonnelId != null && p.rawName.trim().isNotEmpty,
    ).map((p) => (rawName: p.rawName, personnelId: p.matchedPersonnelId!));
    await learningService.rememberAliases(aliasPairs);

    final aliases = await learningService.loadAliases();
    expect(aliases['huseyin oructutan'], personnelId);

    // Verify subsequent import uses learned alias with confidence 1.0 and reviewConfirmed true
    final reimported = await PersonnelFuzzyMatcher(database).matchBlocks([
      ParsedActivityBlock(
        rawTitle: '9/B Gülüşkür',
        parsedTimName: '9/B',
        parsedActivityType: 'GÜLÜŞKÜR',
        parsedDate: '2026-07-31',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'J.Uzm.Çvş.',
            rawName: 'Hüseyin ORUCTUTAN',
          ),
        ],
      ),
    ]);

    final item = reimported.single.personnelList.single;
    expect(item.matchedPersonnelId, personnelId);
    expect(item.matchConfidence, 1.0);
    expect(item.reviewConfirmed, isTrue);
    expect(item.needsReview, isFalse);
  });
}

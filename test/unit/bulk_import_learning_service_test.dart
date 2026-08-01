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

  ParsedActivityBlock block(String name) => ParsedActivityBlock(
        rawTitle: '9/B Gülüşkür',
        parsedTimName: '9/B',
        parsedActivityType: 'GÜLÜŞKÜR',
        parsedDate: '2026-07-30',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'J.Uzm.Çvş.',
            rawName: name,
          ),
        ],
      );

  test('remembers a confirmed spelling and uses it on later imports', () async {
    final service = BulkImportLearningService(database);
    await service.rememberAlias(
      rawName: 'Hüseyin ORUCTUTAN',
      personnelId: personnelId,
    );

    final matched = await PersonnelFuzzyMatcher(database)
        .matchBlocks([block('Hüseyin ORUCTUTAN')]);

    expect(matched.single.personnelList.single.matchedPersonnelId, personnelId);
    expect(matched.single.personnelList.single.matchConfidence, 1);
    expect(matched.single.personnelList.single.needsReview, isFalse);
  });

  test('creates stable fingerprints and detects a recorded import', () async {
    final service = BulkImportLearningService(database);
    final matchedBlock = block('Hüseyin ORUÇTUTAN').copyWith(
      personnelList: [
        block('Hüseyin ORUÇTUTAN')
            .personnelList
            .single
            .copyWith(matchedPersonnelId: personnelId),
      ],
    );
    final fingerprint = BulkImportLearningService.fingerprint([matchedBlock]);

    expect(await service.findImport(fingerprint), isNull);
    await service.recordImport(
      fingerprint: fingerprint,
      blocks: [matchedBlock],
      actor: 'admin',
    );

    final stored = await service.findImport(fingerprint);
    expect(stored, isNotNull);
    expect(stored!.personelSayisi, 1);
    expect(stored.hamMetin, isNull);
    expect(
      BulkImportLearningService.fingerprint([matchedBlock]),
      fingerprint,
    );
  });

  test('rememberAliases saves multiple pairs and handles uppercase Turkish I/İ correctly', () async {
    final service = BulkImportLearningService(database);
    final norm1 = BulkImportLearningService.normalizeName('HÜSEYİN ORUCTUTAN');
    final norm2 = BulkImportLearningService.normalizeName('ISMAİL KAYA');
    expect(norm1, 'huseyin oructutan');
    expect(norm2, 'ismail kaya');

    await service.rememberAliases([
      (rawName: 'HÜSEYİN ORUCTUTAN', personnelId: personnelId),
      (rawName: 'ISMAİL KAYA', personnelId: personnelId),
    ]);

    final aliases = await service.loadAliases();
    expect(aliases['huseyin oructutan'], personnelId);
    expect(aliases['ismail kaya'], personnelId);
  });

  test('learned alias match sets reviewConfirmed to true', () async {
    final service = BulkImportLearningService(database);
    await service.rememberAlias(rawName: 'Hüseyin ORUCTUTAN', personnelId: personnelId);

    final matched = await PersonnelFuzzyMatcher(database).matchBlocks([block('Hüseyin ORUCTUTAN')]);
    final item = matched.single.personnelList.single;
    expect(item.matchedPersonnelId, personnelId);
    expect(item.matchConfidence, 1.0);
    expect(item.reviewConfirmed, isTrue);
  });

  test('getAliasList returns joined personnel details and deleteAlias removes entry', () async {
    final service = BulkImportLearningService(database);
    await service.rememberAlias(rawName: 'Hüseyin ORUCTUTAN', personnelId: personnelId);

    final list = await service.getAliasList();
    expect(list.length, 1);
    expect(list.first.gorunenTakmaAd, 'Hüseyin ORUCTUTAN');
    expect(list.first.personelAdSoyad, 'Hüseyin ORUÇTUTAN');

    await service.deleteAlias(list.first.id);
    final updatedList = await service.getAliasList();
    expect(updatedList.isEmpty, isTrue);
  });
}


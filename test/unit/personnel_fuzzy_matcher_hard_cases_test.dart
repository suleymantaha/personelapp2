import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_fuzzy_matcher.dart';

void main() {
  late AppDatabase db;
  late PersonnelFuzzyMatcher matcher;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    matcher = PersonnelFuzzyMatcher(db);

    // 1. Tim ve 2. Tim ekle
    await db.into(db.timTable).insert(
          TimTableCompanion.insert(timAdi: '1. JÖH Timi', olusturmaTarihi: '2026-01-01'),
        );
    await db.into(db.timTable).insert(
          TimTableCompanion.insert(timAdi: '2. JÖH Timi', olusturmaTarihi: '2026-01-01'),
        );

    // Personelleri ekle
    // Ahmet Mustafa ÇALIŞKAN (J.Asb.Kd.Üçvş.)
    await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Ahmet Mustafa ÇALIŞKAN',
            rutbe: 'J.Asb.Kd.Üçvş.',
            birlik: '1. JÖH Timi',
            kayitTarihi: '2026-01-01',
            timId: const Value(1),
          ),
        );

    // İki farklı rütbeli Mehmet KAYA (Biri Astsubay, biri Uzman Çavuş)
    await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Mehmet KAYA',
            rutbe: 'J.Asb.Kd.Çvş.',
            birlik: '1. JÖH Timi',
            kayitTarihi: '2026-01-01',
            timId: const Value(1),
          ),
        );
    await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Mehmet KAYA',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '2. JÖH Timi',
            kayitTarihi: '2026-01-01',
            timId: const Value(2),
          ),
        );

    // Mehmet YILMAZ
    await db.into(db.personelTable).insert(
          PersonelTableCompanion.insert(
            adSoyad: 'Mehmet YILMAZ',
            rutbe: 'J.Uzm.Çvş.',
            birlik: '1. JÖH Timi',
            kayitTarihi: '2026-01-01',
            timId: const Value(1),
          ),
        );
  });

  tearDown(() => db.close());

  group('PersonnelFuzzyMatcher Hard Cases', () {
    test('reverse token matching: matches clean name when raw name contains extra rank tokens', () async {
      final block = ParsedActivityBlock(
        rawTitle: '1. JÖH Timi GÖREVLİ',
        parsedDate: '2026-10-06',
        parsedTimName: '1. JÖH Timi',
        parsedActivityType: 'GÖREVLİ',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'J.Asb.Kd.Üçvş.',
            rawName: 'J.Per.Asb.Kd.Üçvş. Ahmet Mustafa ÇALIŞKAN',
          ),
        ],
      );

      final matched = await matcher.matchBlocks([block]);
      final person = matched.single.personnelList.single;

      expect(person.isMatched, isTrue);
      expect(person.matchedAdSoyad, equals('Ahmet Mustafa ÇALIŞKAN'));
      expect(person.matchConfidence, equals(1.0));
    });

    test('same name & surname disambiguation: distinguishes by rank when rank differs', () async {
      final block = ParsedActivityBlock(
        rawTitle: 'GÖREVLİ LİSTESİ',
        parsedDate: '2026-10-06',
        parsedTimName: '',
        parsedActivityType: 'GÖREVLİ',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'J.Asb.Kd.Çvş.',
            rawName: 'Mehmet KAYA',
          ),
        ],
      );

      final matched = await matcher.matchBlocks([block]);
      final person = matched.single.personnelList.single;

      expect(person.isMatched, isTrue);
      expect(person.matchedRutbe, equals('J.Asb.Kd.Çvş.'));
    });

    test('same name & surname disambiguation: distinguishes by team name when team matches', () async {
      final block = ParsedActivityBlock(
        rawTitle: '2. JÖH Timi GÖREVLİ',
        parsedDate: '2026-10-06',
        parsedTimName: '2. JÖH Timi',
        parsedActivityType: 'GÖREVLİ',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: '',
            rawName: 'Mehmet KAYA',
          ),
        ],
      );

      final matched = await matcher.matchBlocks([block]);
      final person = matched.single.personnelList.single;

      expect(person.isMatched, isTrue);
      expect(person.matchedTimId, equals(2));
      expect(person.matchedRutbe, equals('J.Uzm.Çvş.'));
    });

    test('same name & surname disambiguation: refuses random assignment when no rank or team clue exists', () async {
      final block = ParsedActivityBlock(
        rawTitle: 'GÖREVLİ LİSTESİ',
        parsedDate: '2026-10-06',
        parsedTimName: '',
        parsedActivityType: 'GÖREVLİ',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: '',
            rawName: 'Mehmet KAYA',
          ),
        ],
      );

      final matched = await matcher.matchBlocks([block]);
      final person = matched.single.personnelList.single;

      // Ambiguous: must NOT pick a random person!
      expect(person.isMatched, isFalse);
    });

    test('poisoned alias protection: rejects alias if surname does not match the target personnel', () async {
      // Zehirlenmiş alias ekle: "ahmet mustafa caliskan" -> Mehmet YILMAZ'ın ID'si
      final allP = await db.select(db.personelTable).get();
      final yilmaz = allP.firstWhere((p) => p.adSoyad == 'Mehmet YILMAZ');

      await BulkImportLearningService(db).rememberAlias(
        rawName: 'Ahmet Mustafa ÇALIŞKAN',
        personnelId: yilmaz.id,
      );

      final block = ParsedActivityBlock(
        rawTitle: '1. JÖH Timi GÖREVLİ',
        parsedDate: '2026-10-06',
        parsedTimName: '1. JÖH Timi',
        parsedActivityType: 'GÖREVLİ',
        personnelList: [
          ParsedPersonnelItem(
            rawIndex: 1,
            rawRank: 'J.Asb.Kd.Üçvş.',
            rawName: 'Ahmet Mustafa ÇALIŞKAN',
          ),
        ],
      );

      final matched = await matcher.matchBlocks([block]);
      final person = matched.single.personnelList.single;

      // Poisoned alias must be IGNORED!
      // Must match Ahmet Mustafa ÇALIŞKAN, NOT Mehmet YILMAZ!
      expect(person.matchedAdSoyad, equals('Ahmet Mustafa ÇALIŞKAN'));
      expect(person.matchedAdSoyad, isNot(equals('Mehmet YILMAZ')));
    });
  });
}

import 'package:drift/drift.dart';
import '../../../../core/database/database.dart';
import '../models/parsed_activity_block.dart';

class PersonnelFuzzyMatcher {
  final AppDatabase database;

  PersonnelFuzzyMatcher(this.database);

  Future<List<ParsedActivityBlock>> matchBlocks(List<ParsedActivityBlock> blocks) async {
    final allPersonnel = await database.select(database.personelTable).get();
    
    List<ParsedActivityBlock> matchedBlocks = [];

    for (final block in blocks) {
      List<ParsedPersonnelItem> matchedPersonnelList = [];

      for (final item in block.personnelList) {
        final matchedItem = _matchPersonnel(item, allPersonnel);
        matchedPersonnelList.add(matchedItem);
      }

      matchedBlocks.add(block.copyWith(personnelList: matchedPersonnelList));
    }

    return matchedBlocks;
  }

  ParsedPersonnelItem _matchPersonnel(ParsedPersonnelItem item, List<PersonelTableData> dbList) {
    if (dbList.isEmpty) return item;

    final rawNameClean = _sanitizeString(item.rawName);

    // 1. Exact Name Match
    for (final p in dbList) {
      final dbNameClean = _sanitizeString(p.adSoyad);
      if (dbNameClean == rawNameClean) {
        return item.copyWith(
          matchedPersonnelId: p.id,
          matchedAdSoyad: p.adSoyad,
          matchedRutbe: p.rutbe,
          matchedTimId: p.timId,
          matchConfidence: 1.0,
        );
      }
    }

    // 2. Token Set Match (ad/soyad yer değişse de tüm kelimeler eşleşiyor mu?)
    final rawTokens = rawNameClean.split(' ').where((e) => e.isNotEmpty).toSet();

    for (final p in dbList) {
      final dbTokens = _sanitizeString(p.adSoyad).split(' ').where((e) => e.isNotEmpty).toSet();

      if (rawTokens.length == dbTokens.length && rawTokens.containsAll(dbTokens)) {
        return item.copyWith(
          matchedPersonnelId: p.id,
          matchedAdSoyad: p.adSoyad,
          matchedRutbe: p.rutbe,
          matchedTimId: p.timId,
          matchConfidence: 0.9,
        );
      }
    }

    // 3. Partial Token Overlap Match (En az 2 kelime veya soyad+ad eşleşmesi)
    PersonelTableData? bestMatch;
    double maxScore = 0.0;

    for (final p in dbList) {
      final dbTokens = _sanitizeString(p.adSoyad).split(' ').where((e) => e.isNotEmpty).toSet();
      final intersection = rawTokens.intersection(dbTokens);

      if (intersection.isNotEmpty) {
        final score = intersection.length / (rawTokens.length > dbTokens.length ? rawTokens.length : dbTokens.length);
        if (score > maxScore && score >= 0.5) {
          maxScore = score;
          bestMatch = p;
        }
      }
    }

    if (bestMatch != null) {
      return item.copyWith(
        matchedPersonnelId: bestMatch.id,
        matchedAdSoyad: bestMatch.adSoyad,
        matchedRutbe: bestMatch.rutbe,
        matchedTimId: bestMatch.timId,
        matchConfidence: 0.7 + (maxScore * 0.2),
      );
    }

    return item;
  }

  static String _sanitizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim();
  }
}

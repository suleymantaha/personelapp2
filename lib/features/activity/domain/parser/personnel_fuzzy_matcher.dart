import 'package:fuzzy/fuzzy.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';
import 'package:personelapp2/features/activity/domain/parser/personnel_search_service.dart';

class PersonnelFuzzyMatcher {
  PersonnelFuzzyMatcher(this.database);
  final AppDatabase database;

  Future<List<ParsedActivityBlock>> matchBlocks(
    List<ParsedActivityBlock> blocks,
  ) async {
    final allPersonnel = await database.select(database.personelTable).get();
    final allTeams = await database.select(database.timTable).get();
    final aliases = await BulkImportLearningService(database).loadAliases();
    final teamNames = {for (final team in allTeams) team.id: team.timAdi};

    final matchedBlocks = <ParsedActivityBlock>[];

    for (final block in blocks) {
      final matchedPersonnelList = <ParsedPersonnelItem>[];

      for (final item in block.personnelList) {
        final matchedItem = _matchPersonnel(
          item,
          allPersonnel,
          parsedTeamName: block.parsedTimName,
          teamNames: teamNames,
          aliases: aliases,
        );
        matchedPersonnelList.add(matchedItem);
      }

      var updatedTimName = block.parsedTimName;
      if (updatedTimName.trim().isEmpty) {
        final matchedTeamIds = matchedPersonnelList
            .where((p) => p.isMatched && p.matchedTimId != null)
            .map((p) => p.matchedTimId!)
            .toSet();
        if (matchedTeamIds.length == 1) {
          // Tüm personeller %100 aynı timden geliyorsa tim adını çıkar
          final inferredName = teamNames[matchedTeamIds.first];
          if (inferredName != null && inferredName.isNotEmpty) {
            updatedTimName = inferredName;
          }
        }
      }

      matchedBlocks.add(
        block.copyWith(
          parsedTimName: updatedTimName,
          personnelList: matchedPersonnelList,
        ),
      );
    }

    return matchedBlocks;
  }

  ParsedPersonnelItem _matchPersonnel(
    ParsedPersonnelItem item,
    List<PersonelTableData> dbList, {
    required String parsedTeamName,
    required Map<int, String> teamNames,
    required Map<String, int> aliases,
  }) {
    if (dbList.isEmpty) return item;

    final rawNameClean = _sanitizeString(item.rawName);
    final aliasPersonnelId = aliases[rawNameClean];
    if (aliasPersonnelId != null) {
      final aliasMatch = dbList
          .where((personnel) => personnel.id == aliasPersonnelId)
          .firstOrNull;
      if (aliasMatch != null) {
        return _withMatch(
          item,
          aliasMatch,
          1,
          parsedTeamName,
          teamNames,
        ).copyWith(reviewConfirmed: true);
      }
    }

    // 1. Exact Name Match
    for (final p in dbList) {
      final dbNameClean = _sanitizeString(p.adSoyad);
      if (dbNameClean == rawNameClean) {
        return _withMatch(item, p, 1, parsedTeamName, teamNames);
      }
    }

    // 2. Token Set Match (all tokens match regardless of order)
    final rawTokens =
        rawNameClean.split(' ').where((e) => e.isNotEmpty).toSet();

    for (final p in dbList) {
      final dbTokens = _sanitizeString(p.adSoyad)
          .split(' ')
          .where((e) => e.isNotEmpty)
          .toSet();

      if (rawTokens.length == dbTokens.length &&
          rawTokens.containsAll(dbTokens)) {
        return _withMatch(item, p, 0.95, parsedTeamName, teamNames);
      }
    }

    // 3. First Letter + Surname Match (e.g., "S. Taha BİRİNCİ" matches "TAHA BİRİNCİ")
    final firstLetterMatch =
        _tryFirstLetterSurnameMatch(rawNameClean, rawTokens, dbList);
    if (firstLetterMatch != null) {
      return _withMatch(
        item,
        firstLetterMatch,
        0.9,
        parsedTeamName,
        teamNames,
      );
    }

    // 4. Token Subset Match (all query tokens found in DB name)
    final tokenSubsetMatch = _tryTokenSubsetMatch(rawTokens, dbList);
    if (tokenSubsetMatch != null) {
      return _withMatch(
        item,
        tokenSubsetMatch,
        0.85,
        parsedTeamName,
        teamNames,
      );
    }

    // 5. Fuzzy match using the package's distance score (lower is better)
    final fuzzyMatch = _tryFuzzyMatch(rawNameClean, dbList);
    if (fuzzyMatch != null) {
      return _withMatch(
        item,
        fuzzyMatch.personnel,
        fuzzyMatch.confidence,
        parsedTeamName,
        teamNames,
      );
    }

    // 6. Partial Token Overlap Match (at least 2 tokens or surname+name match)
    PersonelTableData? bestMatch;
    double maxScore = 0.0;

    for (final p in dbList) {
      final dbTokens = _sanitizeString(p.adSoyad)
          .split(' ')
          .where((e) => e.isNotEmpty)
          .toSet();
      final intersection = rawTokens.intersection(dbTokens);

      if (intersection.isNotEmpty) {
        final score = intersection.length /
            (rawTokens.length > dbTokens.length
                ? rawTokens.length
                : dbTokens.length);
        if (score > maxScore && score >= 0.5) {
          maxScore = score;
          bestMatch = p;
        }
      }
    }

    if (bestMatch != null) {
      return _withMatch(
        item,
        bestMatch,
        0.6 + (maxScore * 0.2),
        parsedTeamName,
        teamNames,
      );
    }

    return item;
  }

  ParsedPersonnelItem _withMatch(
    ParsedPersonnelItem item,
    PersonelTableData personnel,
    double confidence,
    String parsedTeamName,
    Map<int, String> teamNames,
  ) {
    final storedTeam =
        personnel.timId == null ? null : teamNames[personnel.timId!];
    final parsedTeamNumber = _teamNumber(parsedTeamName);
    final storedTeamNumber = _teamNumber(storedTeam ?? '');
    return item.copyWith(
      matchedPersonnelId: personnel.id,
      matchedAdSoyad: personnel.adSoyad,
      matchedRutbe: personnel.rutbe,
      matchedTimId: personnel.timId,
      matchConfidence: confidence,
      teamMismatch: parsedTeamNumber != null &&
          storedTeamNumber != null &&
          parsedTeamNumber != storedTeamNumber,
      reviewConfirmed: false,
    );
  }

  static int? _teamNumber(String value) {
    final trimmed = value.trim();
    final match = RegExp(r'(\d{1,2})').firstMatch(trimmed);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Matches "S. Taha BİRİNCİ" with "TAHA BİRİNCİ" by checking if first token is initial + surname match
  PersonelTableData? _tryFirstLetterSurnameMatch(
    String rawNameClean,
    Set<String> rawTokens,
    List<PersonelTableData> dbList,
  ) {
    if (rawTokens.length < 2) return null;

    // Check if first token is a single letter (initial)
    final firstToken = rawTokens.firstWhere(
      (t) => t.isNotEmpty,
      orElse: () => '',
    );
    if (firstToken.length != 1) return null;

    // Remaining tokens should match a DB entry's tokens
    final remainingTokens = rawTokens.where((t) => t != firstToken).toSet();
    if (remainingTokens.isEmpty) return null;

    for (final p in dbList) {
      final dbTokens = _sanitizeString(p.adSoyad)
          .split(' ')
          .where((e) => e.isNotEmpty)
          .toSet();

      // Check if DB tokens contain all remaining tokens
      if (remainingTokens.length <= dbTokens.length &&
          remainingTokens.containsAll(dbTokens.intersection(remainingTokens))) {
        // Also verify the first letter matches the first name's initial
        final dbFirstToken = dbTokens.firstWhere(
          (t) => t.isNotEmpty,
          orElse: () => '',
        );
        if (dbFirstToken.isNotEmpty && dbFirstToken.startsWith(firstToken)) {
          return p;
        }
      }
    }
    return null;
  }

  /// Matches when all query tokens are found in DB name (subset match)
  PersonelTableData? _tryTokenSubsetMatch(
    Set<String> rawTokens,
    List<PersonelTableData> dbList,
  ) {
    for (final p in dbList) {
      final dbTokens = _sanitizeString(p.adSoyad)
          .split(' ')
          .where((e) => e.isNotEmpty)
          .toSet();

      // All raw tokens must be present in DB tokens
      if (rawTokens.isNotEmpty && dbTokens.containsAll(rawTokens)) {
        return p;
      }
    }
    return null;
  }

  /// Fuzzy matching using Levenshtein distance via fuzzy package
  _FuzzyPersonnelMatch? _tryFuzzyMatch(
    String rawNameClean,
    List<PersonelTableData> dbList,
  ) {
    // Build list of sanitized names for fuzzy search
    final nameList = dbList.map((p) => _sanitizeString(p.adSoyad)).toList();

    // Use fuzzy package for Levenshtein-based matching
    final fuzzy = Fuzzy<String>(nameList,
        options: FuzzyOptions<String>(
          shouldSort: true,
          threshold: 0.6,
          tokenize: false,
        ));

    final results = fuzzy.search(rawNameClean);

    if (results.isEmpty) return null;

    final bestMatch = results.first;
    const maximumDistance = 0.35;
    if (bestMatch.score > maximumDistance) return null;

    const minimumDistanceGap = 0.1;
    if (results.length > 1 &&
        results[1].score - bestMatch.score < minimumDistanceGap) {
      return null;
    }

    try {
      final personnel = dbList.firstWhere(
        (p) => _sanitizeString(p.adSoyad) == bestMatch.item,
      );
      return _FuzzyPersonnelMatch(
        personnel,
        (1 - bestMatch.score).clamp(0.0, 1.0),
      );
    } catch (_) {
      return null;
    }
  }

  static String _sanitizeString(String input) =>
      BulkImportLearningService.normalizeName(input);

  static List<PersonelTableData> searchPersonnel(
    String query,
    List<PersonelTableData> personnelList, {
    double threshold = 0.4,
    int maxResults = 50,
  }) =>
      PersonnelSearchService.searchPersonnel(
        query,
        personnelList,
        threshold: threshold,
        maxResults: maxResults,
      );
}

class _FuzzyPersonnelMatch {
  const _FuzzyPersonnelMatch(this.personnel, this.confidence);

  final PersonelTableData personnel;
  final double confidence;
}

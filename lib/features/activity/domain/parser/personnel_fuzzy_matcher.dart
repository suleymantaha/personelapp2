import 'package:fuzzy/fuzzy.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

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

      matchedBlocks.add(block.copyWith(personnelList: matchedPersonnelList));
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

    // 5. Fuzzy Match (Levenshtein/Jaro-Winkler) using fuzzy package
    final fuzzyMatch = _tryFuzzyMatch(rawNameClean, dbList);
    if (fuzzyMatch != null) {
      return _withMatch(item, fuzzyMatch, 0.75, parsedTeamName, teamNames);
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
  PersonelTableData? _tryFuzzyMatch(
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

    if (results.isNotEmpty) {
      final bestMatch = results.first;
      if (bestMatch.score >= 0.6) {
        // Find the personnel with this sanitized name
        try {
          return dbList.firstWhere(
            (p) => _sanitizeString(p.adSoyad) == bestMatch.item,
          );
        } catch (_) {
          return null;
        }
      }
    }

    // Fallback: Jaro-Winkler for short names (better for initials)
    if (rawNameClean.length <= 20) {
      return _tryJaroWinklerMatch(rawNameClean, dbList);
    }

    return null;
  }

  PersonelTableData? _tryJaroWinklerMatch(
    String rawNameClean,
    List<PersonelTableData> dbList,
  ) {
    double bestScore = 0.0;
    PersonelTableData? bestMatch;

    for (final p in dbList) {
      final dbNameClean = _sanitizeString(p.adSoyad);
      final score = _jaroWinklerDistance(rawNameClean, dbNameClean);
      if (score > bestScore && score >= 0.75) {
        // Higher threshold for Jaro-Winkler
        bestScore = score;
        bestMatch = p;
      }
    }

    return bestMatch;
  }

  /// Jaro-Winkler distance implementation (better for short strings with common prefixes)
  double _jaroWinklerDistance(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Jaro distance
    final matchDistance =
        (s1.length > s2.length ? s1.length : s2.length) ~/ 2 - 1;
    if (matchDistance < 0) return 0.0;

    final s1Matches = List<bool>.filled(s1.length, false);
    final s2Matches = List<bool>.filled(s2.length, false);

    int matches = 0;
    int transpositions = 0;

    for (int i = 0; i < s1.length; i++) {
      final start = (i - matchDistance).clamp(0, s2.length - 1);
      final end = (i + matchDistance + 1).clamp(0, s2.length);

      for (int j = start; j < end; j++) {
        if (!s2Matches[j] && s1[i] == s2[j]) {
          s1Matches[i] = true;
          s2Matches[j] = true;
          matches++;
          break;
        }
      }
    }

    if (matches == 0) return 0.0;

    int k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (s1Matches[i]) {
        while (!s2Matches[k]) {
          k++;
        }
        if (s1[i] != s2[k]) transpositions++;
        k++;
      }
    }

    final jaro = (matches / s1.length +
            matches / s2.length +
            (matches - transpositions / 2) / matches) /
        3;

    // Winkler adjustment
    int prefixLength = 0;
    final minLen = s1.length < s2.length ? s1.length : s2.length;
    for (int i = 0; i < minLen && i < 4; i++) {
      if (s1[i] == s2[i]) prefixLength++;
    }

    return jaro + (0.1 * prefixLength * (1 - jaro));
  }

  static String _sanitizeString(String input) {
    return BulkImportLearningService.normalizeName(input);
  }

  /// Public static method for external search/filter usage
  /// Returns personnel list filtered and ranked by fuzzy match score
  static List<PersonelTableData> searchPersonnel(
    String query,
    List<PersonelTableData> personnelList, {
    double threshold = 0.4,
    int maxResults = 50,
  }) {
    if (query.trim().isEmpty) {
      return personnelList.take(maxResults).toList();
    }

    final cleanQuery = _sanitizeString(query);
    final queryTokens =
        cleanQuery.split(' ').where((e) => e.isNotEmpty).toSet();

    final scoredResults = <_ScoredPersonnel>[];

    for (final p in personnelList) {
      final cleanName = _sanitizeString(p.adSoyad);
      final nameTokens =
          cleanName.split(' ').where((e) => e.isNotEmpty).toSet();

      double score = 0.0;

      // 1. Exact match
      if (cleanName == cleanQuery) {
        score = 1.0;
      }
      // 2. Starts with query
      else if (cleanName.startsWith(cleanQuery)) {
        score = 0.95;
      }
      // 3. Token subset match (all query tokens in name)
      else if (queryTokens.isNotEmpty && nameTokens.containsAll(queryTokens)) {
        score = 0.9;
      }
      // 4. First letter + surname match
      else if (queryTokens.length >= 2) {
        final firstToken = queryTokens.first;
        if (firstToken.length == 1) {
          final remainingTokens =
              queryTokens.where((t) => t != firstToken).toSet();
          if (remainingTokens.isNotEmpty &&
              nameTokens.containsAll(remainingTokens)) {
            final nameFirstToken = nameTokens.first;
            if (nameFirstToken.startsWith(firstToken)) {
              score = 0.85;
            }
          }
        }
      }
      // 5. Fuzzy match (Levenshtein via fuzzy package)
      else {
        final fuzzy = Fuzzy<String>([cleanName],
            options: FuzzyOptions<String>(
              shouldSort: true,
              threshold: 0.5,
              tokenize: false,
            ));
        final results = fuzzy.search(cleanQuery);
        if (results.isNotEmpty) {
          score = results.first.score * 0.8; // Weight fuzzy match lower
        }
      }
      // 6. Token overlap (partial match)
      if (score < 0.5 && queryTokens.isNotEmpty) {
        final intersection = queryTokens.intersection(nameTokens);
        if (intersection.isNotEmpty) {
          final overlapScore = intersection.length /
              (queryTokens.length > nameTokens.length
                  ? queryTokens.length
                  : nameTokens.length);
          if (overlapScore > score) {
            score = overlapScore * 0.6;
          }
        }
      }
      // 7. Jaro-Winkler for short queries
      if (score < 0.5 && cleanQuery.length <= 20) {
        final jwScore = _jaroWinklerStatic(cleanQuery, cleanName);
        if (jwScore > score) {
          score = jwScore * 0.7;
        }
      }

      if (score >= threshold) {
        scoredResults.add(_ScoredPersonnel(p, score));
      }
    }

    // Sort by score descending
    scoredResults.sort((a, b) => b.score.compareTo(a.score));

    return scoredResults.take(maxResults).map((s) => s.personnel).toList();
  }

  static double _jaroWinklerStatic(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final matchDistance =
        (s1.length > s2.length ? s1.length : s2.length) ~/ 2 - 1;
    if (matchDistance < 0) return 0.0;

    final s1Matches = List<bool>.filled(s1.length, false);
    final s2Matches = List<bool>.filled(s2.length, false);

    int matches = 0;
    int transpositions = 0;

    for (int i = 0; i < s1.length; i++) {
      final start = (i - matchDistance).clamp(0, s2.length - 1);
      final end = (i + matchDistance + 1).clamp(0, s2.length);

      for (int j = start; j < end; j++) {
        if (!s2Matches[j] && s1[i] == s2[j]) {
          s1Matches[i] = true;
          s2Matches[j] = true;
          matches++;
          break;
        }
      }
    }

    if (matches == 0) return 0.0;

    int k = 0;
    for (int i = 0; i < s1.length; i++) {
      if (s1Matches[i]) {
        while (!s2Matches[k]) {
          k++;
        }
        if (s1[i] != s2[k]) transpositions++;
        k++;
      }
    }

    final jaro = (matches / s1.length +
            matches / s2.length +
            (matches - transpositions / 2) / matches) /
        3;

    int prefixLength = 0;
    final minLen = s1.length < s2.length ? s1.length : s2.length;
    for (int i = 0; i < minLen && i < 4; i++) {
      if (s1[i] == s2[i]) prefixLength++;
    }

    return jaro + (0.1 * prefixLength * (1 - jaro));
  }
}

class _ScoredPersonnel {
  final PersonelTableData personnel;
  final double score;

  _ScoredPersonnel(this.personnel, this.score);
}

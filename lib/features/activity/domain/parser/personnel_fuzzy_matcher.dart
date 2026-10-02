import 'package:fuzzy/fuzzy.dart';
import 'package:drift/drift.dart';
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
    final allPersonnel =
        await (database.select(database.personelTable)
          ..where((p) => p.aktif.equals(true) & p.isDemo.equals(false))).get();
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
        final matchedTeamIds =
            matchedPersonnelList
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

      final taskTeams =
          allTeams
              .where(
                (t) =>
                    BulkImportLearningService.normalizeTeam(t.timAdi) ==
                    BulkImportLearningService.normalizeTeam(updatedTimName),
              )
              .toList();
      matchedBlocks.add(
        block.copyWith(
          parsedTimName: updatedTimName,
          taskTeamId: taskTeams.length == 1 ? taskTeams.single.id : null,
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
    final scopedAlias =
        aliases[BulkImportLearningService.aliasKey(
          item.rawName,
          teamName: parsedTeamName,
        )];
    final aliasPersonnelId = scopedAlias ?? aliases[rawNameClean];
    if (aliasPersonnelId != null) {
      final aliasMatch =
          dbList
              .where((personnel) => personnel.id == aliasPersonnelId)
              .firstOrNull;
      final isLegacySafe =
          aliasMatch != null &&
          dbList
                  .where(
                    (p) =>
                        _sanitizeString(p.adSoyad) ==
                        _sanitizeString(aliasMatch.adSoyad),
                  )
                  .length ==
              1 &&
          (parsedTeamName.trim().isEmpty ||
              BulkImportLearningService.normalizeTeam(parsedTeamName) ==
                  BulkImportLearningService.normalizeTeam(
                    teamNames[aliasMatch.timId] ?? '',
                  ));
      if (aliasMatch != null && (scopedAlias != null || isLegacySafe)) {
        return _withMatch(
          item,
          aliasMatch,
          1,
          parsedTeamName,
          teamNames,
        ).copyWith(reviewConfirmed: true);
      }
    }

    if (rawNameClean.isEmpty) return item;

    // A matching strategy must identify one person. Never break ties by
    // database order, and never fall through from an ambiguous stronger match.
    ParsedPersonnelItem resolve(
      List<PersonelTableData> candidates,
      double confidence,
    ) {
      if (candidates.length > 1 && parsedTeamName.trim().isNotEmpty) {
        final inTeam =
            candidates
                .where(
                  (p) =>
                      BulkImportLearningService.normalizeTeam(
                        teamNames[p.timId] ?? p.birlik,
                      ) ==
                      BulkImportLearningService.normalizeTeam(parsedTeamName),
                )
                .toList();
        if (inTeam.length == 1) candidates = inTeam;
      }
      return candidates.length == 1
          ? _withMatch(
            item,
            candidates.single,
            confidence,
            parsedTeamName,
            teamNames,
          )
          : item;
    }

    final exactMatches =
        dbList
            .where((p) => _sanitizeString(p.adSoyad) == rawNameClean)
            .toList();
    if (exactMatches.isNotEmpty) return resolve(exactMatches, 1);

    final rawTokens = _nameTokens(rawNameClean);
    final tokenMatches =
        dbList.where((p) {
          final dbTokens = _nameTokens(_sanitizeString(p.adSoyad));
          return rawTokens.length == dbTokens.length &&
              rawTokens.containsAll(dbTokens);
        }).toList();
    if (tokenMatches.isNotEmpty) return resolve(tokenMatches, 0.95);

    // An initial requires the remaining name tokens AND the surname to match.
    // Do not use fuzzy/partial fallback when that explicit abbreviation fails.
    if (rawTokens.length >= 2 && rawTokens.first.length == 1) {
      return resolve(_firstLetterSurnameMatches(rawTokens, dbList), 0.9);
    }

    final subsetMatches =
        dbList
            .where(
              (p) => _nameTokens(
                _sanitizeString(p.adSoyad),
              ).containsAll(rawTokens),
            )
            .toList();
    if (subsetMatches.isNotEmpty) return resolve(subsetMatches, 0.85);

    final fuzzyMatch = _tryFuzzyMatch(rawNameClean, dbList);
    if (fuzzyMatch != null) {
      final personnel = fuzzyMatch.personnel;
      if (personnel == null) return item;
      return _withMatch(
        item,
        personnel,
        fuzzyMatch.confidence,
        parsedTeamName,
        teamNames,
      );
    }

    final bestMatches = <PersonelTableData>[];
    double maxScore = 0;
    for (final p in dbList) {
      final dbTokens = _nameTokens(_sanitizeString(p.adSoyad));
      final intersection = rawTokens.intersection(dbTokens);
      if (intersection.isEmpty) continue;
      final score =
          intersection.length /
          (rawTokens.length > dbTokens.length
              ? rawTokens.length
              : dbTokens.length);
      if (score < 0.5) continue;
      if (score > maxScore) {
        maxScore = score;
        bestMatches.clear();
      }
      if (score == maxScore) bestMatches.add(p);
    }
    if (bestMatches.isNotEmpty) {
      return resolve(bestMatches, 0.6 + maxScore * 0.2);
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
    final parsedTeamKey = BulkImportLearningService.normalizeTeam(
      parsedTeamName,
    );
    final storedTeamKey = BulkImportLearningService.normalizeTeam(
      storedTeam ?? '',
    );
    return item.copyWith(
      matchedPersonnelId: personnel.id,
      matchedAdSoyad: personnel.adSoyad,
      matchedRutbe: personnel.rutbe,
      matchedTimId: personnel.timId,
      matchConfidence: confidence,
      teamMismatch:
          parsedTeamKey.isNotEmpty &&
          storedTeamKey.isNotEmpty &&
          parsedTeamKey != storedTeamKey,
      reviewConfirmed: false,
    );
  }

  static Set<String> _nameTokens(String name) =>
      name.split(' ').where((token) => token.isNotEmpty).toSet();

  List<PersonelTableData> _firstLetterSurnameMatches(
    Set<String> rawTokens,
    List<PersonelTableData> dbList,
  ) {
    final initial = rawTokens.first;
    final remaining = rawTokens.skip(1).toSet();
    return dbList.where((p) {
      final dbTokens = _nameTokens(_sanitizeString(p.adSoyad));
      return dbTokens.length >= 2 &&
          dbTokens.first.startsWith(initial) &&
          dbTokens.last == rawTokens.last &&
          dbTokens.skip(1).toSet().containsAll(remaining);
    }).toList();
  }

  /// Fuzzy matching using Levenshtein distance via fuzzy package
  _FuzzyPersonnelMatch? _tryFuzzyMatch(
    String rawNameClean,
    List<PersonelTableData> dbList,
  ) {
    // Build list of sanitized names for fuzzy search
    final nameList = dbList.map((p) => _sanitizeString(p.adSoyad)).toList();

    // Use fuzzy package for Levenshtein-based matching
    final fuzzy = Fuzzy<String>(
      nameList,
      options: FuzzyOptions<String>(
        shouldSort: true,
        threshold: 0.6,
        tokenize: false,
      ),
    );

    final results = fuzzy.search(rawNameClean);

    if (results.isEmpty) return null;

    final bestMatch = results.first;
    const maximumDistance = 0.35;
    if (bestMatch.score > maximumDistance) return null;

    const minimumDistanceGap = 0.1;
    if (results.length > 1 &&
        results[1].score - bestMatch.score < minimumDistanceGap) {
      return const _FuzzyPersonnelMatch.ambiguous();
    }

    try {
      final candidates =
          dbList
              .where((p) => _sanitizeString(p.adSoyad) == bestMatch.item)
              .toList();
      if (candidates.length != 1) return const _FuzzyPersonnelMatch.ambiguous();
      final personnel = candidates.single;
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
  }) => PersonnelSearchService.searchPersonnel(
    query,
    personnelList,
    threshold: threshold,
    maxResults: maxResults,
  );
}

class _FuzzyPersonnelMatch {
  const _FuzzyPersonnelMatch(this.personnel, this.confidence);

  const _FuzzyPersonnelMatch.ambiguous() : personnel = null, confidence = 0;

  final PersonelTableData? personnel;
  final double confidence;
}

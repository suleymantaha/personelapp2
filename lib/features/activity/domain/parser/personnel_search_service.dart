import 'package:fuzzy/fuzzy.dart';
import 'package:personelapp2/core/database/database.dart';
import 'package:personelapp2/features/activity/domain/bulk_import_learning_service.dart';

class PersonnelSearchService {
  static String _sanitizeString(String input) {
    final separated = input.replaceAll(RegExp(r'[-./_]+'), ' ');
    return BulkImportLearningService.normalizeName(separated);
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
      final cleanRank = _sanitizeString(p.rutbe);
      final cleanUnit = _sanitizeString(p.birlik);
      final searchableText = '$cleanName $cleanRank $cleanUnit';
      final searchableTokens =
          searchableText.split(' ').where((token) => token.isNotEmpty).toSet();
      final nameTokens =
          cleanName.split(' ').where((e) => e.isNotEmpty).toSet();

      double score = 0.0;

      // 1. Exact match
      if (cleanName == cleanQuery) {
        score = 1.0;
      }
      // 2. Direct match in name, rank or unit
      else if (searchableText.contains(cleanQuery)) {
        score = 0.95;
      }
      // 3. Token subset match across name, rank and unit
      else if (queryTokens.isNotEmpty &&
          searchableTokens.containsAll(queryTokens)) {
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

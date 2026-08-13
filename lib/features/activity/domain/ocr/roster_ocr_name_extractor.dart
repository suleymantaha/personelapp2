class RosterOcrExtractedName {
  const RosterOcrExtractedName({
    required this.rawName,
    required this.sourceLineNumber,
    this.rawRank,
    this.activityHint,
  });

  final String rawName;
  final int sourceLineNumber;
  final String? rawRank;
  final String? activityHint;
}

class RosterOcrExtractionResult {
  const RosterOcrExtractionResult({
    required this.names,
    required this.ignoredLineCount,
    this.defaultDate,
    this.titleActivity,
  });

  final List<RosterOcrExtractedName> names;
  final int ignoredLineCount;
  final String? defaultDate;
  final String? titleActivity;

  bool get hasNames => names.isNotEmpty;

  String toBulkImportText() {
    if (names.isEmpty) return '';

    final grouped = <String, List<RosterOcrExtractedName>>{};
    for (final name in names) {
      final activity = _activityFor(name.activityHint) ??
          titleActivity ??
          (defaultDate == null ? '' : 'GÖREVLİ');
      grouped.putIfAbsent(activity, () => <RosterOcrExtractedName>[]).add(name);
    }

    var fallbackIndex = 1;
    final buffer = StringBuffer();
    for (final entry in grouped.entries) {
      final titleParts = <String>[
        if (defaultDate != null) _formatDisplayDate(defaultDate!),
        if (entry.key.trim().isNotEmpty) entry.key,
        'İsim Listesi',
      ];
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln(titleParts.join(' '));
      for (final name in entry.value) {
        final rank = (name.rawRank?.trim().isNotEmpty ?? false)
            ? '${name.rawRank!.trim()} '
            : '';
        buffer.writeln('${fallbackIndex++}. $rank${name.rawName}');
      }
    }
    return buffer.toString().trimRight();
  }

  static String? _activityFor(String? hint) {
    final folded = RosterOcrNameExtractor.fold(hint ?? '');
    if (folded.contains('garaj')) return 'GARAJ NÖB.';
    if (folded.contains('ttza')) return 'TTZA NÖB.';
    if (folded.contains('mebs')) return 'MEBS NÖB.';
    if (folded.contains('kule')) return 'KULE NÖB.';
    if (folded.contains('nob') || folded.contains('nobet')) return 'NÖBETÇİ';
    return null;
  }

  static String _formatDisplayDate(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }
}

class RosterOcrNameExtractor {
  static RosterOcrExtractionResult extract(String rawText) {
    final names = <RosterOcrExtractedName>[];
    var ignored = 0;
    String? defaultDate;
    String? titleActivity;

    final lines =
        rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

    for (var i = 0; i < lines.length; i++) {
      final normalized = _normalizeLine(lines[i]);
      final lineNumber = i + 1;
      if (normalized.isEmpty) {
        ignored++;
        continue;
      }

      defaultDate ??= _extractDate(normalized);
      titleActivity ??= _extractTitleActivity(normalized);

      if (_isNonPersonnelLine(normalized)) {
        ignored++;
        continue;
      }

      final candidate = _extractNameCandidate(normalized, lineNumber);
      if (candidate == null) {
        ignored++;
        continue;
      }

      names.add(candidate);
    }

    return RosterOcrExtractionResult(
      names: List.unmodifiable(_deduplicate(names)),
      ignoredLineCount: ignored,
      defaultDate: defaultDate,
      titleActivity: titleActivity,
    );
  }

  static String fold(String input) {
    const replacements = {
      'Ç': 'C',
      'Ğ': 'G',
      'İ': 'I',
      'I': 'I',
      'Ö': 'O',
      'Ş': 'S',
      'Ü': 'U',
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'i': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
    };
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString().toLowerCase();
  }

  static String _normalizeLine(String input) => input
      .replaceAll('\u00a0', ' ')
      .replaceAll('\t', ' ')
      .replaceAll(
          RegExp(r'[\u200B-\u200F\u202A-\u202E\u2060-\u2064\uFEFF]'), '')
      .replaceAll(RegExp(r'[|]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _isNonPersonnelLine(String line) {
    final folded = fold(line);
    if (RegExp(r'^\d{1,2}[./-]\d{1,2}[./-]\d{4}').hasMatch(line)) {
      return true;
    }
    const labels = [
      's.nu',
      's nu',
      'rutbesi',
      'rütbesi',
      'adi soyadi',
      'adı soyadı',
      'aciklamalar',
      'açıklamalar',
      'gorevli isim cizelgesi',
      'görevli isim çizelgesi',
      'heybet',
      'nobet',
      'nöbet',
      'isim listesi',
      'sayfa',
      'whatsapp image',
      'excel',
    ];
    if (labels.any((label) => folded == fold(label))) return true;
    if (folded.startsWith('sayfa ')) return true;
    if (_isActivityOnlyLine(line)) return true;
    return false;
  }

  static bool _isActivityOnlyLine(String line) {
    final folded = fold(line).replaceAll(RegExp(r'[^a-z0-9 ]'), ' ').trim();
    const activityWords = {
      'sabah',
      'aksam',
      'ogle',
      'oglen',
      'gece',
      'gunduz',
      'garaj nob',
      'garaj nobet',
      'ttza nob',
      'ttza nobet',
      'mebs nob',
      'kule nob',
    };
    return activityWords.contains(folded.replaceAll(RegExp(r'\s+'), ' '));
  }

  static RosterOcrExtractedName? _extractNameCandidate(
    String line,
    int lineNumber,
  ) {
    var working = line;
    working = working.replaceFirst(RegExp(r'^\s*\d+\s*[.)\-:]?\s*'), '');

    final activityHint = _extractActivityHint(working);
    if (activityHint != null) {
      working = working
          .replaceFirst(_activityHintPattern, ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    String? rank;
    final rankMatch = _rankPattern.firstMatch(working);
    if (rankMatch != null) {
      rank = _normalizeRank(rankMatch.group(0)!);
      working = working.substring(rankMatch.end).trim();
    }

    working = working
        .replaceAll(
            RegExp(r'\b(?:SABAH|AKŞAM|AKSAM|GECE|GÜNDÜZ|GUNDUZ)\b',
                caseSensitive: false),
            ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (!_looksLikePersonName(working)) return null;
    return RosterOcrExtractedName(
      rawName: working,
      rawRank: rank,
      activityHint: activityHint,
      sourceLineNumber: lineNumber,
    );
  }

  static final RegExp _rankPattern = RegExp(
    r'^(J\s*[.]?\s*(?:(?:Asb|Uzm)\s*[.]?\s*(?:Kd\s*[.]?\s*)?'
    r'(?:Ü[.]?Çvş|U[.]?Cv[sş]|Üçvş|Ucv[sş]?|Çvş|Cv[sş]?|Bçvş|Bcvs)|'
    r'Ütğm|Utgm|Tğm|Tgm|Astğm|Astgm|Yzb)\s*[.]?)\s*',
    caseSensitive: false,
  );

  static String? _extractActivityHint(String line) {
    final match = _activityHintPattern.firstMatch(line);
    final value = match?.group(0)?.trim();
    if (value == null) return null;
    final folded = fold(value);
    if (folded.contains('ttza')) return 'TTZA NÖB.';
    if (folded.contains('garaj')) return 'GARAJ NÖB.';
    if (folded.contains('mebs')) return 'MEBS NÖB.';
    if (folded.contains('kule')) return 'KULE NÖB.';
    return value;
  }

  static final RegExp _activityHintPattern = RegExp(
    r'\b(?:GARAJ\s+N[ÖO]B[.]?|TTZA\s+N[ÖO]B[.]?|MEBS\s+N[ÖO]B[.]?|KULE\s+N[ÖO]B[.]?|SABAH|AKŞAM|AKSAM|GECE|GÜNDÜZ|GUNDUZ)\b[.]?',
    caseSensitive: false,
  );

  static String? _extractTitleActivity(String line) {
    final folded = fold(line);
    if (folded.contains('heybet')) return 'HEYBET';
    if (folded.contains('hazir kita')) return 'HAZIR KITA';
    if (folded.contains('guluskur')) return 'GÜLÜŞKÜR';
    if (folded.contains('nobet')) return 'NÖBETÇİ';
    if (folded.contains('gorev')) return 'GÖREVLİ';
    return null;
  }

  static String? _extractDate(String line) {
    final match = RegExp(r'(?<!\d)(\d{1,2})[./-](\d{1,2})[./-](\d{4})(?!\d)')
        .firstMatch(line);
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-'
        '${day.toString().padLeft(2, '0')}';
  }

  static bool _looksLikePersonName(String value) {
    if (value.length < 5) return false;
    if (RegExp(r'\d').hasMatch(value)) return false;
    if (!RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(value)) return false;
    final words = value
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().length >= 2)
        .toList();
    if (words.length < 2 || words.length > 4) return false;
    final folded = words.map(fold).toSet();
    const blocked = {
      'adi',
      'soyadi',
      'rutbesi',
      'aciklamalar',
      'sayfa',
      'whatsapp',
      'image',
      'excel',
      'sabah',
      'aksam',
      'gece',
      'garaj',
      'ttza',
      'nob',
    };
    if (folded.any(blocked.contains)) return false;
    return true;
  }

  static String _normalizeRank(String rank) {
    final folded = fold(rank).replaceAll(RegExp(r'[\s.]'), '');
    if (folded.contains('asb')) {
      if (folded.contains('kd') && folded.contains('uc')) {
        return 'J.Asb.Kd.Üçvş.';
      }
      if (folded.contains('kd')) return 'J.Asb.Kd.Çvş.';
      if (folded.contains('uc')) return 'J.Asb.Üçvş.';
      return 'J.Asb.Çvş.';
    }
    if (folded.contains('yzb')) return 'J.Yzb.';
    if (folded.contains('ast')) return 'J.Astğm.';
    if (folded.contains('utg')) return 'J.Ütğm.';
    if (folded.contains('tg')) return 'J.Tğm.';
    return 'J.Uzm.Çvş.';
  }

  static List<RosterOcrExtractedName> _deduplicate(
    List<RosterOcrExtractedName> names,
  ) {
    final seen = <String>{};
    final result = <RosterOcrExtractedName>[];
    for (final name in names) {
      final key = fold(name.rawName).replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (seen.add(key)) result.add(name);
    }
    return result;
  }
}

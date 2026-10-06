part of 'bulk_text_parser.dart';

PersonnelListParseResult _parsePersonnelList(String rawText) {
  final personnel = <ParsedPersonnelItem>[];
  final issues = <BulkParseIssue>[];
  var nextIndex = 1;

  for (final source in _personnelSourceLines(rawText)) {
    final rawLine = source.text;
    final lineNumber = source.lineNumber;
    for (final rawSubLine in _splitLineIfMultiplePersonnel(rawLine)) {
      final line = _normalizeLine(rawSubLine);
      if (line.isEmpty ||
          _messageMetadataPattern.hasMatch(line) ||
          _isHeader(line) ||
          _isCommentOrNoteLine(line) ||
          _summaryPattern.hasMatch(line)) {
        continue;
      }

      final candidate = _personnelCandidate(line);
      final content = (candidate?.content ?? line)
          .replaceAll(_fullDayAnnotationPattern, ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final parsed = _parsePersonnelLine(
        content,
        candidate?.index ?? nextIndex,
        lineNumber,
      );
      if (parsed == null) {
        issues.add(BulkParseIssue(
          lineNumber: lineNumber,
          rawLine: rawSubLine,
          code: 'invalid_personnel',
          message: 'Personel satırı çözümlenemedi.',
          severity: BulkParseIssueSeverity.error,
        ));
        continue;
      }

      personnel.add(parsed.item);
      nextIndex = parsed.item.rawIndex + 1;
      if (!parsed.rankKnown) {
        issues.add(BulkParseIssue(
          lineNumber: lineNumber,
          rawLine: rawSubLine,
          code: 'unknown_rank',
          message: 'Rütbe tanınamadı.',
          severity: BulkParseIssueSeverity.warning,
        ));
      }
    }
  }

  return PersonnelListParseResult(
    personnel: List.unmodifiable(personnel),
    issues: List.unmodifiable(issues),
  );
}

Iterable<({String text, int lineNumber})> _personnelSourceLines(
  String rawText,
) sync* {
  final lines = rawText
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  for (var i = 0; i < lines.length; i++) {
    final originalLineNumber = i + 1;
    final line = _normalizeLine(lines[i]);
    final candidate = _personnelCandidate(line);
    final rank = candidate == null
        ? null
        : _rankPattern.firstMatch(candidate.content);
    final rankOnly =
        rank != null && candidate!.content.substring(rank.end).trim().isEmpty;
    if (rankOnly) {
      var nextIndex = i + 1;
      while (nextIndex < lines.length &&
          _normalizeLine(lines[nextIndex]).isEmpty) {
        nextIndex++;
      }
      if (nextIndex < lines.length) {
        final next = _normalizeLine(lines[nextIndex]);
        final nextCandidate = _personnelCandidate(next);
        final isNameContinuation =
            nextCandidate != null &&
            nextCandidate.index == null &&
            !_rankPattern.hasMatch(next) &&
            !_isHeader(next) &&
            !_summaryPattern.hasMatch(next) &&
            !_isCommentOrNoteLine(next) &&
            RegExp(r"^[A-Za-zÇĞİÖŞÜçğıöşü][A-Za-zÇĞİÖŞÜçğıöşü .'’-]*$")
                .hasMatch(next);
        if (isNameContinuation) {
          yield (text: '$line $next', lineNumber: originalLineNumber);
          i = nextIndex;
          continue;
        }
      }
    }
    yield (text: lines[i], lineNumber: originalLineNumber);
  }
}

String _normalizeLine(String input) => input
    .replaceAll('\u00a0', ' ')
    .replaceAll('\t', ' ')
    .replaceAll(RegExp(r'[\u200B-\u200F\u202A-\u202E\u2060-\u2064\uFEFF]'), '')
    .replaceAll(RegExp('[–—−]'), '-')
    .replaceAll(RegExp(r'[*_`~]'), '')
    .replaceFirst(RegExp(r'^\s*>\s?'), '')
    .replaceFirst(_bulletPattern, '')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

String _removeDateAndDayWords(String line) {
  var clean =
      line.replaceAll(_datePattern, ' ').replaceAll(_textMonthDatePattern, ' ');
  for (final day in _dayNames) {
    clean = clean.replaceAll(RegExp('\\b$day\\b', caseSensitive: false), ' ');
  }
  return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isShiftOnlyLine(String line) {
  var folded = _fold(line);
  folded = folded.replaceAll(_shiftWordPattern, ' ');
  for (final activity in _activityTypes.keys) {
    folded = folded.replaceAll(activity, ' ');
  }
  return folded.replaceAll(RegExp(r'\s+'), '').isEmpty;
}

String _stripShiftWordsAtEdges(String line) {
  var clean = line.replaceFirst(
    RegExp(
      r'^\s*(?:sabah|akşam|aksam|öğlen|oglen|gece|gündüz|gunduz)\b\s*',
      caseSensitive: false,
    ),
    '',
  );
  clean = clean.replaceFirst(
    RegExp(
      r'\s*\b(?:sabah|akşam|aksam|öğlen|oglen|gece|gündüz|gunduz)\s*$',
      caseSensitive: false,
    ),
    '',
  );
  return clean.trim();
}

bool _isHeader(String line) {
  final folded = _fold(line);
  final hasHeaderWord = folded.contains('listesi') ||
      RegExp(r'\bliste\b').hasMatch(folded) ||
      folded.contains('isim list') ||
      folded.contains('timi') ||
      folded.contains(' tim ') ||
      RegExp(r'\bmeti\b').hasMatch(folded);
  final hasActivity = _activityTypes.keys.any((key) => folded.contains(key));
  final hasDate = _extractDateFromLine(line) != null;
  return hasHeaderWord ||
      (hasActivity && (_extractTeam(line) != null || hasDate));
}

const Set<String> _conversationalWords = {
  'merhaba',
  'selam',
  'günaydın',
  'gunaydin',
  'iyigünler',
  'iyigunler',
  'toplantı',
  'toplanti',
  'yarın',
  'yarin',
  'kolay',
  'gelsin',
  'teşekkürler',
  'tesekkurler',
  'tamam',
  'evet',
  'hayır',
  'hayir',
  'sağol',
  'sagol',
  'bilgi',
  'not',
  'açıklama',
  'aciklama',
};

String? _extractTeam(String line) {
  final match = _teamPattern.firstMatch(line);
  if (match == null) {
    final timMatch = RegExp(
      r'(?<!\d)(\d{1,2})\s*[.]?\s*(?:tim(?:i)?|bölük|boluk|bl)\b',
      caseSensitive: false,
    ).firstMatch(_fold(line));
    if (timMatch != null) return '${timMatch.group(1)}';

    final folded = _fold(line);
    if (RegExp(r'\bmeti\b').hasMatch(folded)) {
      return 'METİ';
    }
    return null;
  }
  final number = match.group(1)!;
  final rawSuffix = (match.group(2) ?? match.group(3))!;
  final foldedSuffix = _fold(rawSuffix);

  if (_turkishMonths.containsKey(foldedSuffix)) {
    return null;
  }

  final suffix = rawSuffix.toUpperCase();
  if (suffix == 'TIM' ||
      suffix == 'TIMI' ||
      suffix == 'BÖLÜK' ||
      suffix == 'BOLUK') {
    return number;
  }
  final cleanSuffix = suffix.replaceAll(RegExp(r'[^A-ZÇĞİÖŞÜ]'), '');
  return match.group(2) != null
      ? '$number/$cleanSuffix'
      : '$number$cleanSuffix';
}

(String, bool) _extractActivity(String line) {
  final folded = _fold(line);
  for (final entry in _activityDisplayNames.entries) {
    if (folded.contains(entry.key)) return (entry.value, true);
  }
  return (_extractUnknownActivity(line), false);
}

String _extractUnknownActivity(String line) => line
    .replaceAll(_datePattern, '')
    .replaceAll(_textMonthDatePattern, '')
    .replaceAll(_teamPattern, '')
    .replaceAll(RegExp(r'\bmeti\s*(?:timi?)?\b', caseSensitive: false), '')
    .replaceAll(
      RegExp(r'\b(?:isim\s+)?(?:liste|listesi)\b', caseSensitive: false),
      '',
    )
    .trim();

String _fold(String value) =>
    value.toLowerCase().replaceAll('ı', 'i').replaceAll('İ', 'i');

String? _parseDateMatch(RegExpMatch? match) {
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

String? _validateDefaultDate(String? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null || value != _formatDate(parsed)) return null;
  return value;
}

String? _parseTimeRange(RegExpMatch? match) {
  if (match == null) return null;
  final startHour = int.parse(match.group(1)!);
  final startMinute = int.parse(match.group(2)!);
  final endHour = int.parse(match.group(3)!);
  final endMinute = int.parse(match.group(4)!);
  if (startHour > 23 || endHour > 23 || startMinute > 59 || endMinute > 59) {
    return null;
  }
  return '${startHour.toString().padLeft(2, '0')}:'
      '${startMinute.toString().padLeft(2, '0')} - '
      '${endHour.toString().padLeft(2, '0')}:'
      '${endMinute.toString().padLeft(2, '0')}';
}

({String content, int? index})? _personnelCandidate(String line) {
  final numbered = _numberedPersonnelPattern.firstMatch(line);
  if (numbered != null) {
    return (
      content: numbered.group(3)!.trim(),
      index: int.tryParse(numbered.group(1)!),
    );
  }
  if (_rankPattern.hasMatch(line)) return (content: line, index: null);

  if (RegExp(r'[,.!?:]').hasMatch(line)) return null;

  final folded = _fold(line);
  if (_dayNames.contains(folded) ||
      folded == 'listesi' ||
      folded == 'liste' ||
      folded.contains('isim list') ||
      _activityTypes.containsKey(folded) ||
      _turkishMonths.containsKey(folded)) {
    return null;
  }

  final words = folded.split(RegExp(r'\s+'));
  if (words.any((w) => _conversationalWords.contains(w))) return null;

  final hasLetters = RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(line);
  if (hasLetters && line.trim().length >= 3 && !_isHeader(line)) {
    return (content: line, index: null);
  }

  return null;
}

bool _looksLikeBrokenPersonnel(String line) =>
    RegExp(r'^\d+\s*[.)\-:]').hasMatch(line) ||
    _fold(line).startsWith('j.asb') ||
    _fold(line).startsWith('j.uzm');

({ParsedPersonnelItem item, bool rankKnown})? _parsePersonnelLine(
  String content,
  int index,
  int lineNumber,
) {
  final extracted = MilitaryRankNormalizer.extractRankAndName(content);
  final rankKnown = extracted.hasRank;
  final rank = extracted.standardRank ?? '';
  final name = extracted.cleanName.trim();
  if (name.isEmpty || !RegExp(r'[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(name)) {
    return null;
  }
  return (
    item: ParsedPersonnelItem(
      rawIndex: index,
      rawRank: rank,
      rawName: name,
      sourceLineNumber: lineNumber,
    ),
    rankKnown: rankKnown,
  );
}

String _normalizeRank(String rank) {
  final clean = _fold(rank).replaceAll(RegExp(r'[\s.]'), '');
  if (clean.contains('ütğm') || clean.contains('utgm')) {
    return 'J.Ütğm.';
  }
  if (clean.contains('astğm') || clean.contains('astgm')) {
    return 'J.Astğm.';
  }
  if (clean.contains('tğm') || clean.contains('tgm')) {
    return 'J.Tğm.';
  }
  if (clean.contains('yzb')) {
    return 'J.Yzb.';
  }
  if (clean.contains('asbkdüçvş') ||
      clean.contains('asbkducvs') ||
      clean.contains('asbkdüçvs')) {
    return 'J.Asb.Kd.Üçvş.';
  }
  if (clean.contains('asbkdçvş') ||
      clean.contains('asbkdcvs') ||
      clean.contains('asbkdçvs')) {
    return 'J.Asb.Kd.Çvş.';
  }
  if (clean.contains('asbüçvş') ||
      clean.contains('asbucvs') ||
      clean.contains('asbüçvs') ||
      clean.contains('asbücvs')) {
    return 'J.Asb.Üçvş.';
  }
  if (clean.contains('asbçvş') ||
      clean.contains('asbcvs') ||
      clean.contains('asbçvs')) {
    return 'J.Asb.Çvş.';
  }
  if (clean.contains('bçvş') || clean.contains('bcvs')) {
    return 'J.Bçvş.';
  }
  return 'J.Uzm.Çvş.';
}

String _formatDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

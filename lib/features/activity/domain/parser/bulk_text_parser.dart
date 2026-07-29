import 'package:personelapp2/features/activity/domain/conflict_checker.dart';
import 'package:personelapp2/features/activity/domain/models/parsed_activity_block.dart';

typedef ParsedActivityTitle = ({
  String? timName,
  String activityType,
  String? date,
  bool activityTypeKnown,
});

enum BulkParseIssueSeverity { warning, error }

class BulkParseIssue {
  const BulkParseIssue({
    required this.lineNumber,
    required this.rawLine,
    required this.code,
    required this.message,
    required this.severity,
  });

  final int lineNumber;
  final String rawLine;
  final String code;
  final String message;
  final BulkParseIssueSeverity severity;

  bool get isBlocking => severity == BulkParseIssueSeverity.error;
}

class BulkParseResult {
  const BulkParseResult({
    required this.blocks,
    required this.issues,
    this.ignoredLineCount = 0,
    this.declaredTotals = const [],
  });

  final List<ParsedActivityBlock> blocks;
  final List<BulkParseIssue> issues;
  final int ignoredLineCount;
  final List<BulkDeclaredTotal> declaredTotals;

  bool get hasBlockingIssues => issues.any((issue) => issue.isBlocking);
}

class BulkDeclaredTotal {
  const BulkDeclaredTotal({
    required this.lineNumber,
    required this.expectedCount,
    required this.date,
    required this.teamName,
    required this.activityType,
  });

  final int lineNumber;
  final int expectedCount;
  final String date;
  final String teamName;
  final String activityType;
}

class BulkTextParser {
  static final RegExp _datePattern =
      RegExp(r'(?<!\d)(\d{1,2})[./](\d{1,2})[./](\d{4})(?!\d)');
  static final RegExp _dateOnlyPattern = RegExp(
    r'^\s*\d{1,2}[./]\d{1,2}[./]\d{4}(?:\s+[A-Za-zÇĞİÖŞÜçğıöşü]+)?\s*$',
    caseSensitive: false,
  );
  static final RegExp _teamPattern = RegExp(
    r'(?<!\d)(\d{1,2})\s*(?:[/\-]\s*([A-Za-zÇĞİÖŞÜçğıöşü]+)|([A-Za-zÇĞİÖŞÜçğıöşü]+))',
    caseSensitive: false,
  );
  static final RegExp _numberedPersonnelPattern =
      RegExp(r'^\s*(\d+)\s*([.)\-:])\s*(.+)$');
  static final RegExp _bulletPattern = RegExp(r'^\s*[•●▪◦]\s*');
  static final RegExp _timeRangePattern = RegExp(
    r'(?<!\d)(\d{1,2})[.:](\d{2})\s*[-/]\s*(\d{1,2})[.:](\d{2})(?!\d)',
  );
  static final RegExp _timeLikePattern =
      RegExp(r'\d{1,2}[.:]\d{1,2}\s*[-/]\s*\d{1,2}[.:]\d{1,2}');
  static final RegExp _messageMetadataPattern = RegExp(
    r'^\s*(?:\[\d{1,2}[.:]\d{2}(?:,\s*\d{1,2}[./]\d{1,2}[./]\d{2,4})?\]|'
    r'\d{1,2}[.:]\d{2}\s*[-–—]\s*[A-Za-zÇĞİÖŞÜçğıöşü][^:]{0,59}:)',
  );
  static final RegExp _rankPattern = RegExp(
    r'^(J\s*[.]?\s*(?:(?:Ütğm|Utgm|Tğm|Tgm|Astğm|Astgm)|'
    r'(?:(?:Asb|Uzm)\s*[.]?\s*(?:Kd\s*[.]?\s*)?'
    r'(?:Üçvş|Ucv[sş]?|Çvş|Cv[sş]?)))\s*[.]?)\s*',
    caseSensitive: false,
  );
  static final RegExp _fullDayAnnotationPattern = RegExp(
    r'\s*\(\s*24\s*saat\s+kalacak\s*\)\s*',
    caseSensitive: false,
  );
  static final RegExp _summaryPattern = RegExp(
    r'^\s*(?:toplam|tolam)\b',
    caseSensitive: false,
  );

  static const Map<String, String> _activityTypes = {
    'gülüşkür': DutyOrLeaveType.guluskur,
    'guluskur': DutyOrLeaveType.guluskur,
    'hazır kıta': DutyOrLeaveType.hazirKita,
    'hazir kita': DutyOrLeaveType.hazirKita,
    'heybet': DutyOrLeaveType.heybet,
    'ihtiyat': DutyOrLeaveType.gorevli,
    'devriye': DutyOrLeaveType.gorevli,
    'görev': DutyOrLeaveType.gorevli,
    'gorev': DutyOrLeaveType.gorevli,
    'nöbetçi': DutyOrLeaveType.nobetci,
    'nobetci': DutyOrLeaveType.nobetci,
  };

  static const Map<String, String> _activityDisplayNames = {
    'gülüşkür': 'Gülüşkür',
    'guluskur': 'Gülüşkür',
    'hazır kıta': 'Hazır Kıta',
    'hazir kita': 'Hazır Kıta',
    'heybet': 'Heybet',
    'ihtiyat': 'İhtiyat',
    'devriye': 'Devriye',
    'görev': 'Görev',
    'gorev': 'Görev',
    'nöbetçi': 'Nöbetçi',
    'nobetci': 'Nöbetçi',
  };

  static ParsedActivityTitle parseTitle(
    String titleLine, [
    String? defaultDate,
  ]) {
    final normalized = _normalizeLine(titleLine);
    final teamName = _extractTeam(normalized);
    final activity = _extractActivity(normalized);
    final parsedDate = _parseDateMatch(_datePattern.firstMatch(normalized));
    return (
      timName: teamName,
      activityType: activity.$1,
      date: parsedDate ?? defaultDate,
      activityTypeKnown: activity.$2,
    );
  }

  static String extractActivityType(String titleLine) =>
      _extractActivity(_normalizeLine(titleLine)).$1;

  static String mapActivityTypeToDutyOrLeave(String activityType) =>
      _activityTypes[_fold(activityType).trim()] ?? activityType.trim();

  static BulkParseResult parse(
    String rawText, {
    String? defaultDate,
  }) {
    final issues = <BulkParseIssue>[];
    final blocks = <ParsedActivityBlock>[];
    final personnel = <ParsedPersonnelItem>[];
    final declaredTotals = <BulkDeclaredTotal>[];
    var ignoredLineCount = 0;

    if (rawText.trim().isEmpty) {
      issues.add(const BulkParseIssue(
        lineNumber: 0,
        rawLine: '',
        code: 'empty_input',
        message: 'Ayrıştırılacak metin boş.',
        severity: BulkParseIssueSeverity.error,
      ));
      return BulkParseResult(blocks: blocks, issues: issues);
    }

    String? currentTeam;
    String? currentDate = _validateDefaultDate(defaultDate);
    String? currentActivity;
    var currentActivityKnown = false;
    String? currentTimeRange;
    var currentTitle = '';
    var currentHeaderLine = 0;
    var currentHeaderRawLine = '';
    var nextIndex = 1;

    void addIssue({
      required int line,
      required String raw,
      required String code,
      required String message,
      required BulkParseIssueSeverity severity,
    }) {
      issues.add(BulkParseIssue(
        lineNumber: line,
        rawLine: raw,
        code: code,
        message: message,
        severity: severity,
      ));
    }

    void flushBlock() {
      if (personnel.isEmpty) return;
      final line = currentHeaderLine == 0 ? 1 : currentHeaderLine;
      final raw = currentHeaderRawLine;
      if (currentDate == null) {
        addIssue(
          line: line,
          raw: raw,
          code: 'missing_date',
          message: 'Bu personel grubu için geçerli bir tarih bulunamadı.',
          severity: BulkParseIssueSeverity.error,
        );
      }
      if (currentTeam == null) {
        addIssue(
          line: line,
          raw: raw,
          code: 'unknown_team',
          message: 'Takım/tim bilgisi tanınamadı.',
          severity: BulkParseIssueSeverity.warning,
        );
      }
      if (!currentActivityKnown) {
        addIssue(
          line: line,
          raw: raw,
          code: 'unknown_activity',
          message: 'Görev türü tanınamadı.',
          severity: BulkParseIssueSeverity.warning,
        );
      }
      blocks.add(ParsedActivityBlock(
        rawTitle: currentTitle.isEmpty ? 'Ayrıştırılan Faaliyet' : currentTitle,
        parsedTimName: currentTeam ?? '',
        parsedActivityType: currentActivity ?? '',
        parsedDate: currentDate ?? '',
        parsedTimeRange: currentTimeRange,
        personnelList: List<ParsedPersonnelItem>.unmodifiable(personnel),
      ));
      personnel.clear();
      nextIndex = 1;
    }

    final rawLines =
        rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    for (var lineIndex = 0; lineIndex < rawLines.length; lineIndex++) {
      final rawLine = rawLines[lineIndex];
      final lineNumber = lineIndex + 1;
      final line = _normalizeLine(rawLine);
      if (line.isEmpty || _messageMetadataPattern.hasMatch(line)) continue;

      final dateMatch = _datePattern.firstMatch(line);
      final looksLikeHeader = _isHeader(line);

      if (looksLikeHeader) {
        flushBlock();
        currentTitle = line;
        currentHeaderLine = lineNumber;
        currentHeaderRawLine = rawLine;
        currentTimeRange = null;

        final title = parseTitle(line, currentDate);
        currentTeam = title.timName;
        currentActivityKnown = title.activityTypeKnown;
        currentActivity = title.activityTypeKnown
            ? mapActivityTypeToDutyOrLeave(title.activityType)
            : title.activityType;
        if (dateMatch != null) {
          final parsedDate = _parseDateMatch(dateMatch);
          if (parsedDate == null) {
            currentDate = null;
            addIssue(
              line: lineNumber,
              raw: rawLine,
              code: 'invalid_date',
              message: 'Başlıktaki tarih geçerli değil.',
              severity: BulkParseIssueSeverity.error,
            );
          } else {
            currentDate = parsedDate;
          }
        }
        continue;
      }

      if (_dateOnlyPattern.hasMatch(line)) {
        flushBlock();
        final parsedDate = _parseDateMatch(dateMatch);
        if (parsedDate == null) {
          currentDate = null;
          addIssue(
            line: lineNumber,
            raw: rawLine,
            code: 'invalid_date',
            message: 'Tarih geçerli değil.',
            severity: BulkParseIssueSeverity.error,
          );
        } else {
          currentDate = parsedDate;
        }
        continue;
      }

      final timeMatch = _timeRangePattern.firstMatch(line);
      if (timeMatch != null || _timeLikePattern.hasMatch(line)) {
        ignoredLineCount++;
        if (timeMatch == null || _parseTimeRange(timeMatch) == null) {
          addIssue(
            line: lineNumber,
            raw: rawLine,
            code: 'invalid_time',
            message: 'Saat aralığı geçerli değil.',
            severity: BulkParseIssueSeverity.error,
          );
        }
        continue;
      }

      if (_summaryPattern.hasMatch(line)) {
        ignoredLineCount++;
        final expected =
            int.tryParse(RegExp(r'\d+').firstMatch(line)?.group(0) ?? '');
        if (expected != null &&
            currentDate != null &&
            currentTeam != null &&
            currentActivity != null) {
          declaredTotals.add(
            BulkDeclaredTotal(
              lineNumber: lineNumber,
              expectedCount: expected,
              date: currentDate,
              teamName: currentTeam,
              activityType: currentActivity,
            ),
          );
        }
        continue;
      }

      final personnelCandidate = _personnelCandidate(line);
      if (personnelCandidate != null) {
        final content = personnelCandidate.content
            .replaceAll(_fullDayAnnotationPattern, ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (content != personnelCandidate.content) ignoredLineCount++;
        final parsed = _parsePersonnelLine(
          content,
          personnelCandidate.index ?? nextIndex,
          lineNumber,
        );
        if (parsed == null) {
          addIssue(
            line: lineNumber,
            raw: rawLine,
            code: 'invalid_personnel',
            message: 'Personel satırı çözümlenemedi.',
            severity: BulkParseIssueSeverity.error,
          );
        } else {
          personnel.add(parsed.item);
          nextIndex = parsed.item.rawIndex + 1;
          if (!parsed.rankKnown) {
            addIssue(
              line: lineNumber,
              raw: rawLine,
              code: 'unknown_rank',
              message: 'Rütbe tanınamadı; ham personel adı korundu.',
              severity: BulkParseIssueSeverity.warning,
            );
          }
        }
        continue;
      }

      if (_looksLikeBrokenPersonnel(line)) {
        addIssue(
          line: lineNumber,
          raw: rawLine,
          code: 'invalid_personnel',
          message: 'Personel satırı çözümlenemedi.',
          severity: BulkParseIssueSeverity.error,
        );
      }
    }

    flushBlock();
    if (blocks.isEmpty &&
        !issues.any((issue) => issue.code == 'invalid_personnel')) {
      addIssue(
        line: 0,
        raw: '',
        code: 'no_blocks',
        message: 'Metinde aktarılabilecek personel bloğu bulunamadı.',
        severity: BulkParseIssueSeverity.error,
      );
    }
    return BulkParseResult(
      blocks: List<ParsedActivityBlock>.unmodifiable(blocks),
      issues: List<BulkParseIssue>.unmodifiable(issues),
      ignoredLineCount: ignoredLineCount,
      declaredTotals: List<BulkDeclaredTotal>.unmodifiable(declaredTotals),
    );
  }

  static String _normalizeLine(String input) => input
      .replaceAll('\u00a0', ' ')
      .replaceAll('\t', ' ')
      .replaceAll(RegExp('[–—−]'), '-')
      .replaceAll(RegExp(r'[*_`~]'), '')
      .replaceFirst(RegExp(r'^\s*>\s?'), '')
      .replaceFirst(_bulletPattern, '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _isHeader(String line) {
    final folded = _fold(line);
    final hasHeaderWord = folded.contains('listesi') ||
        RegExp(r'\bliste\b').hasMatch(folded) ||
        folded.contains('isim list') ||
        folded.contains('timi') ||
        folded.contains(' tim ');
    final hasActivity = _activityTypes.keys.any((key) => folded.contains(key));
    return hasHeaderWord || (hasActivity && _extractTeam(line) != null);
  }

  static String? _extractTeam(String line) {
    final match = _teamPattern.firstMatch(line);
    if (match == null) {
      final timMatch =
          RegExp(r'(?<!\d)(\d{1,2})\s*[.]?\s*tim(?:i)?\b', caseSensitive: false)
              .firstMatch(_fold(line));
      return timMatch?.group(1);
    }
    final number = match.group(1)!;
    final suffix = (match.group(2) ?? match.group(3))!.toUpperCase();
    return match.group(2) != null ? '$number/$suffix' : '$number$suffix';
  }

  static (String, bool) _extractActivity(String line) {
    final folded = _fold(line);
    for (final entry in _activityDisplayNames.entries) {
      if (folded.contains(entry.key)) return (entry.value, true);
    }
    return (_extractUnknownActivity(line), false);
  }

  static String _extractUnknownActivity(String line) => line
      .replaceAll(_datePattern, '')
      .replaceAll(_teamPattern, '')
      .replaceAll(
        RegExp(r'\b(?:isim\s+)?(?:liste|listesi)\b', caseSensitive: false),
        '',
      )
      .trim();

  static String _fold(String value) =>
      value.toLowerCase().replaceAll('ı', 'i').replaceAll('İ', 'i');

  static String? _parseDateMatch(RegExpMatch? match) {
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

  static String? _validateDefaultDate(String? value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed == null || value != _formatDate(parsed)) return null;
    return value;
  }

  static String? _parseTimeRange(RegExpMatch? match) {
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

  static ({String content, int? index})? _personnelCandidate(String line) {
    final numbered = _numberedPersonnelPattern.firstMatch(line);
    if (numbered != null) {
      return (
        content: numbered.group(3)!.trim(),
        index: int.tryParse(numbered.group(1)!),
      );
    }
    if (_rankPattern.hasMatch(line)) return (content: line, index: null);
    return null;
  }

  static bool _looksLikeBrokenPersonnel(String line) =>
      RegExp(r'^\d+\s*[.)\-:]').hasMatch(line) ||
      _fold(line).startsWith('j.asb') ||
      _fold(line).startsWith('j.uzm');

  static ({ParsedPersonnelItem item, bool rankKnown})? _parsePersonnelLine(
    String content,
    int index,
    int lineNumber,
  ) {
    final rankMatch = _rankPattern.firstMatch(content);
    final rankKnown = rankMatch != null;
    final rank = rankKnown ? _normalizeRank(rankMatch.group(1)!) : '';
    final name =
        (rankKnown ? content.substring(rankMatch.end) : content).trim();
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

  static String _normalizeRank(String rank) {
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
    if (clean.contains('asbkdüçvş') || clean.contains('asbkducvs')) {
      return 'J.Asb.Kd.Üçvş.';
    }
    if (clean.contains('asbkdçvş') || clean.contains('asbkdcvs')) {
      return 'J.Asb.Kd.Çvş.';
    }
    if (clean.contains('asbüçvş') || clean.contains('asbucvs')) {
      return 'J.Asb.Üçvş.';
    }
    if (clean.contains('asbçvş') || clean.contains('asbcvs')) {
      return 'J.Asb.Çvş.';
    }
    return 'J.Uzm.Çvş.';
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

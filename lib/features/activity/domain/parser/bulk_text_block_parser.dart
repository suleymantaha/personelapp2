part of 'bulk_text_parser.dart';

BulkParseResult _parseBulkText(
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
    currentDate = null;
    nextIndex = 1;
  }

  final rawLines =
      rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

  for (var lineIndex = 0; lineIndex < rawLines.length; lineIndex++) {
    final rawLine = rawLines[lineIndex];
    final lineNumber = lineIndex + 1;
    final subLines = _splitLineIfMultiplePersonnel(rawLine);

    for (final rawSubLine in subLines) {
      var line = _normalizeLine(rawSubLine);
      if (line.isEmpty || _messageMetadataPattern.hasMatch(line)) continue;

      final dateMatch = _extractDateFromLine(line, currentDate);
      final looksLikeHeader = _isHeader(line);

      if (looksLikeHeader) {
        final title = _parseBulkTitle(line, currentDate);
        final newDate = dateMatch ?? currentDate;
        final newTeam = title.timName ?? currentTeam;
        final newActivity = title.activityTypeKnown
            ? _mapBulkActivityTypeToDutyOrLeave(title.activityType)
            : (title.activityType.isNotEmpty
                ? title.activityType
                : currentActivity);

        final isSameBlock = currentDate == newDate &&
            currentTeam == newTeam &&
            (currentActivity == newActivity || !currentActivityKnown);

        if (!isSameBlock) {
          flushBlock();
          currentTitle = line;
          currentHeaderLine = lineNumber;
          currentHeaderRawLine = rawSubLine;
          currentTimeRange = null;
        } else {
          if (currentTitle.isEmpty) currentTitle = line;
        }

        currentTeam = newTeam;
        currentActivityKnown = title.activityTypeKnown || currentActivityKnown;
        currentActivity = newActivity;
        currentDate = newDate;
        continue;
      }

      if (_isDateOnlyLine(line, currentDate)) {
        final parsedDate = _extractDateFromLine(line, currentDate);
        if (parsedDate == null) {
          addIssue(
            line: lineNumber,
            raw: rawSubLine,
            code: 'invalid_date',
            message: 'Tarih geçerli değil.',
            severity: BulkParseIssueSeverity.error,
          );
        } else {
          if (currentDate != parsedDate) {
            if (currentDate == null && personnel.isNotEmpty) {
              currentDate = parsedDate;
            } else {
              flushBlock();
              currentDate = parsedDate;
            }
          }
        }
        continue;
      }

      // Free-form lists commonly put the date and a name on the same line,
      // for example "5 Ağustos Hasan Akbaş". Apply the date to the block,
      // then continue parsing only the meaningful remainder as personnel.
      if (dateMatch != null) {
        if (currentDate != dateMatch) {
          if (currentDate == null && personnel.isNotEmpty) {
            currentDate = dateMatch;
          } else {
            flushBlock();
            currentDate = dateMatch;
          }
        }
        line = _removeDateAndDayWords(line);
        if (line.isEmpty) continue;
      }

      if (_isShiftOnlyLine(line)) {
        ignoredLineCount++;
        continue;
      }

      line = _stripShiftWordsAtEdges(line);
      if (line.isEmpty) {
        ignoredLineCount++;
        continue;
      }

      final timeMatch = _timeRangePattern.firstMatch(line);
      if (timeMatch != null || _timeLikePattern.hasMatch(line)) {
        ignoredLineCount++;
        final parsedTime =
            timeMatch != null ? _parseTimeRange(timeMatch) : null;
        if (parsedTime == null) {
          addIssue(
            line: lineNumber,
            raw: rawSubLine,
            code: 'invalid_time',
            message: 'Saat aralığı geçerli değil.',
            severity: BulkParseIssueSeverity.error,
          );
        } else {
          if (currentTimeRange == null) {
            currentTimeRange = parsedTime;
          } else if (currentTimeRange != parsedTime) {
            currentTimeRange = null;
          }
        }
        continue;
      }

      if (_singleTimePattern.hasMatch(line)) {
        ignoredLineCount++;
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
              date: currentDate!,
              teamName: currentTeam!,
              activityType: currentActivity!,
            ),
          );
        }
        continue;
      }

      if (_isCommentOrNoteLine(line)) {
        ignoredLineCount++;
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
            raw: rawSubLine,
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
              raw: rawSubLine,
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
          raw: rawSubLine,
          code: 'invalid_personnel',
          message: 'Personel satırı çözümlenemedi.',
          severity: BulkParseIssueSeverity.error,
        );
      }
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

/// Parses a plain personnel roster without requiring activity, date or team
/// headers. It deliberately reuses the activity importer's line and rank
/// normalization so both paste flows interpret names consistently.
